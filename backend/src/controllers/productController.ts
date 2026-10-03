import { Request, Response, NextFunction } from 'express';
import { prisma } from '../config/db';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { getParam } from '../utils/request';
import { lockInventoryRow } from '../services/inventoryService';
import { AppError } from '../utils/errors';
import { parseQuantityConfig } from '../utils/quantity';
import { validatedBody } from '../middlewares/validate';
import { createProductSchema, updateProductSchema, updateStoreInventorySchema } from '../validation/schemas';
import { paginationMeta, parsePagination } from '../utils/pagination';

export class ProductController {
  /**
   * List Global Products.
   * If customer, only return active products.
   * If Super Admin, support category filtering, search terms, status filters, and pagination.
   */
  static async listProducts(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { categoryId, search, isActive } = req.query;
      const role = (req as AuthenticatedRequest).user?.role;

      const whereClause: any = {};

      if (role !== 'SUPER_ADMIN') {
        // Customer only sees active products of active categories
        whereClause.isActive = true;
        whereClause.category = { isActive: true };
      } else {
        // Super Admin filters
        if (isActive !== undefined) {
          whereClause.isActive = isActive === 'true';
        }
        if (categoryId) {
          whereClause.categoryId = categoryId as string;
        }
        if (search) {
          whereClause.OR = [
            { name: { contains: search as string, mode: 'insensitive' } },
            { description: { contains: search as string, mode: 'insensitive' } },
          ];
        }
      }

      const paging = parsePagination(req.query);
      const [products, total] = await Promise.all([
        prisma.product.findMany({
          where: whereClause,
          include: {
            category: {
              select: { name: true },
            },
          },
          orderBy: [{ name: 'asc' }, { id: 'asc' }],
          ...(paging ? { skip: paging.skip, take: paging.limit } : {}),
        }),
        paging ? prisma.product.count({ where: whereClause }) : Promise.resolve(0),
      ]);

      res.status(200).json({
        success: true,
        data: paging ? { products, pagination: paginationMeta(total, paging) } : products,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get Product Details.
   */
  static async getProductById(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = getParam(req, 'id');
      const role = (req as AuthenticatedRequest).user?.role;

      const product = await prisma.product.findUnique({
        where: { id },
        include: {
          category: {
            select: { name: true },
          },
        },
      });

      // Customers cannot view inactive products
      if (!product || (role !== 'SUPER_ADMIN' && !product.isActive)) {
        res.status(404).json({
          success: false,
          message: 'Product not found.',
          errorCode: 'PRODUCT_NOT_FOUND',
        });
        return;
      }

      res.status(200).json({
        success: true,
        data: product,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Super Admin Create Product.
   */
  static async createProduct(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      // Shape validated by validateBody(createProductSchema) (unknown unit → VALIDATION_ERROR)
      const { name, description, imageUrl, categoryId, unit, price, mrp } = validatedBody(res, createProductSchema);

      // D-012: optional product-level quantity rules (all three together)
      const quantityConfig = parseQuantityConfig(req.body, unit);
      if (quantityConfig.error) {
        res.status(400).json({ success: false, message: quantityConfig.error, errorCode: 'INVALID_QUANTITY_CONFIG' });
        return;
      }

      // Check category exists
      const category = await prisma.category.findUnique({
        where: { id: categoryId },
      });

      if (!category) {
        res.status(400).json({
          success: false,
          message: 'Invalid Category ID provided.',
          errorCode: 'CATEGORY_NOT_FOUND',
        });
        return;
      }

      const product = await prisma.product.create({
        data: {
          name,
          description: description ?? null,
          imageUrl: imageUrl ?? null,
          categoryId,
          unit,
          price,
          mrp: mrp ?? null,
          ...(quantityConfig.data ?? {}),
        },
      });

      // Write Audit Log
      await prisma.auditLog.create({
        data: {
          adminUserId: req.user?.id,
          action: 'PRODUCT_CREATED',
          details: `Created product: ${name} (${unit}) at price: ${price}`,
        },
      });

      res.status(201).json({
        success: true,
        message: 'Product created successfully.',
        data: product,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Super Admin Update Product.
   */
  static async updateProduct(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = getParam(req, 'id');
      // Shape validated by validateBody(updateProductSchema)
      const { name, description, imageUrl, categoryId, unit, price, mrp, isActive } = validatedBody(res, updateProductSchema);

      const product = await prisma.product.findUnique({
        where: { id },
      });

      if (!product) {
        res.status(404).json({
          success: false,
          message: 'Product not found.',
          errorCode: 'PRODUCT_NOT_FOUND',
        });
        return;
      }

      const targetUnit = unit ?? product.unit;

      // D-012: quantity rules are validated against the resulting unit. When only the unit
      // changes, the existing configuration must still be valid for the new unit.
      const quantityConfig = parseQuantityConfig(
        ['minQuantity', 'maxQuantity', 'quantityStep'].some((f) => req.body[f] !== undefined)
          ? req.body
          : targetUnit !== product.unit && product.minQuantity != null
            ? {
                minQuantity: Number(product.minQuantity),
                maxQuantity: Number(product.maxQuantity),
                quantityStep: Number(product.quantityStep),
              }
            : {},
        targetUnit,
      );
      if (quantityConfig.error) {
        res.status(400).json({ success: false, message: quantityConfig.error, errorCode: 'INVALID_QUANTITY_CONFIG' });
        return;
      }

      // Check if price is changing to record price change audit
      const targetPrice = price ?? undefined;
      const isPriceChanged = targetPrice !== undefined && targetPrice !== Number(product.price);

      const updated = await prisma.product.update({
        where: { id },
        data: {
          name,
          description,
          imageUrl,
          categoryId,
          unit,
          price: targetPrice,
          mrp,
          isActive,
          ...(quantityConfig.data ?? {}),
        },
      });

      const asNumber = (v: unknown) => (v == null ? null : Number(v));
      const quantityRulesChanged =
        quantityConfig.data !== undefined &&
        (quantityConfig.data.minQuantity !== asNumber(product.minQuantity) ||
          quantityConfig.data.maxQuantity !== asNumber(product.maxQuantity) ||
          quantityConfig.data.quantityStep !== asNumber(product.quantityStep));

      if (quantityConfig.data && quantityRulesChanged) {
        const { minQuantity, maxQuantity, quantityStep } = quantityConfig.data;
        await prisma.auditLog.create({
          data: {
            adminUserId: req.user?.id,
            action: 'PRODUCT_QUANTITY_RULES_CHANGED',
            details:
              minQuantity === null
                ? `Cleared quantity rules for ${updated.name}`
                : `Quantity rules for ${updated.name}: min ${minQuantity}, max ${maxQuantity}, step ${quantityStep} ${updated.unit}`,
          },
        });
      }

      // Write specialized price audit if changed
      if (isPriceChanged) {
        await prisma.auditLog.create({
          data: {
            adminUserId: req.user?.id,
            action: 'PRODUCT_PRICE_CHANGED',
            details: `Changed price of product ${product.name} from ₹${product.price} to ₹${targetPrice}`,
          },
        });
      }

      // Handle activation / deactivation logs
      if (isActive !== undefined && isActive !== product.isActive) {
        await prisma.auditLog.create({
          data: {
            adminUserId: req.user?.id,
            action: isActive ? 'PRODUCT_ACTIVATED' : 'PRODUCT_DEACTIVATED',
            details: `${isActive ? 'Activated' : 'Deactivated'} product: ${updated.name}`,
          },
        });
      }

      // Write General Update log
      await prisma.auditLog.create({
        data: {
          adminUserId: req.user?.id,
          action: 'PRODUCT_UPDATED',
          details: `Updated product details for: ${updated.name}`,
        },
      });

      res.status(200).json({
        success: true,
        message: 'Product updated successfully.',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Super Admin Deactivate Product (Soft delete).
   */
  static async deleteProduct(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = getParam(req, 'id');

      const product = await prisma.product.findUnique({
        where: { id },
      });

      if (!product) {
        res.status(404).json({
          success: false,
          message: 'Product not found.',
          errorCode: 'PRODUCT_NOT_FOUND',
        });
        return;
      }

      const deactivated = await prisma.product.update({
        where: { id },
        data: { isActive: false },
      });

      // Write Audit Log
      await prisma.auditLog.create({
        data: {
          adminUserId: req.user?.id,
          action: 'PRODUCT_DEACTIVATED',
          details: `Deactivated product: ${product.name}`,
        },
      });

      res.status(200).json({
        success: true,
        message: 'Product deactivated successfully.',
        data: deactivated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * List products with store-specific inventory details.
   */
  static async listStoreProducts(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const storeId = getParam(req, 'storeId');
      const { categoryId } = req.query;

      // Ensure store exists and is active for customers
      const store = await prisma.store.findUnique({
        where: { id: storeId },
      });

      const role = (req as AuthenticatedRequest).user?.role;
      const isStaff = role === 'SUPER_ADMIN' || role === 'STORE_MANAGER';

      if (!store || (!isStaff && !store.isActive)) {
        res.status(404).json({
          success: false,
          message: 'Store not found or currently inactive.',
          errorCode: 'STORE_NOT_FOUND',
        });
        return;
      }

      // Query products joined with their inventory for this store
      const products = await prisma.product.findMany({
        where: {
          isActive: true,
          categoryId: categoryId ? (categoryId as string) : undefined,
        },
        include: {
          category: {
            select: { name: true },
          },
          inventory: {
            where: { storeId },
          },
        },
        orderBy: { name: 'asc' },
      });

      let result = products.map((prod) => {
        const inv = prod.inventory[0];
        return {
          id: prod.id,
          name: prod.name,
          description: prod.description,
          imageUrl: prod.imageUrl,
          categoryId: prod.categoryId,
          categoryName: prod.category.name,
          unit: prod.unit,
          minQuantity: prod.minQuantity,
          maxQuantity: prod.maxQuantity,
          quantityStep: prod.quantityStep,
          price: prod.price,
          mrp: prod.mrp,
          stockQuantity: inv ? Number(inv.stockQuantity) : 0,
          lowStockThreshold: inv ? Number(inv.lowStockThreshold) : 5.0,
          isAvailable: inv ? inv.isAvailable : false,
        };
      });

      if (!isStaff) {
        result = result.filter((p) => p.isAvailable && p.stockQuantity > 0);
      }

      res.status(200).json({
        success: true,
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update Store-Specific Product Inventory allocation.
   * Access is limited to Super Admins, or Store Managers assigned to this specific storeId.
   */
  static async updateStoreInventory(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const storeId = getParam(req, 'storeId');
      const productId = getParam(req, 'productId');
      // validateBody(updateStoreInventorySchema): adjustment type, numeric quantities, boolean availability
      const { stockQuantity, adjustmentType, quantity, reason, lowStockThreshold, isAvailable } = validatedBody(res, updateStoreInventorySchema);

      // Check product exists
      const product = await prisma.product.findUnique({
        where: { id: productId },
      });

      if (!product) {
        res.status(404).json({
          success: false,
          message: 'Product not found.',
          errorCode: 'PRODUCT_NOT_FOUND',
        });
        return;
      }

      // Perform inside transaction to guarantee atomic updates and history logging
      const result = await prisma.$transaction(async (tx) => {
        // P0-06: lock the inventory row so concurrent checkouts/adjustments cannot be overwritten
        await lockInventoryRow(tx, storeId, productId);

        // 1. Fetch current inventory details
        const currentInv = await tx.storeInventory.findUnique({
          where: {
            storeId_productId: { storeId, productId },
          },
        });

        const prevStock = currentInv ? Number(currentInv.stockQuantity) : 0;
        let newStock = prevStock;
        let changeVal = 0;
        let type: 'STOCK_ADDED' | 'STOCK_REMOVED' | 'STOCK_ADJUSTED' = 'STOCK_ADJUSTED';

        if (adjustmentType) {
          // New adjustment UI signature
          if (quantity == null) {
            throw new AppError(400, 'INVALID_QUANTITY', 'Quantity must be a positive number.');
          }
          const qty = quantity;

          if (adjustmentType === 'ADD') {
            newStock = prevStock + qty;
            changeVal = qty;
            type = 'STOCK_ADDED';
          } else if (adjustmentType === 'REMOVE') {
            newStock = prevStock - qty;
            changeVal = -qty;
            type = 'STOCK_REMOVED';
          } else if (adjustmentType === 'SET') {
            newStock = qty;
            changeVal = qty - prevStock;
            type = 'STOCK_ADJUSTED';
          }
        } else if (stockQuantity != null) {
          // Existing test compatibility signature
          const targetQty = stockQuantity;
          newStock = targetQty;
          changeVal = targetQty - prevStock;
          type = 'STOCK_ADJUSTED';
        } else {
          // If only updating threshold or availability without changing quantity
          newStock = prevStock;
          changeVal = 0;
        }

        // Negative stock protection
        if (newStock < 0) {
          throw new Error('NEGATIVE_STOCK_BLOCKED');
        }

        // 2. Upsert store inventory record
        const inventory = await tx.storeInventory.upsert({
          where: {
            storeId_productId: { storeId, productId },
          },
          update: {
            stockQuantity: newStock,
            lowStockThreshold: lowStockThreshold ?? undefined,
            isAvailable,
            updatedAt: new Date(),
          },
          create: {
            storeId,
            productId,
            stockQuantity: newStock,
            lowStockThreshold: lowStockThreshold ?? 5.0,
            isAvailable: isAvailable ?? true,
          },
        });

        // 3. Log history transaction record
        if (changeVal !== 0 || adjustmentType || stockQuantity !== undefined) {
          await tx.inventoryTransaction.create({
            data: {
              storeId,
              productId,
              previousQuantity: prevStock,
              changeQuantity: changeVal,
              newQuantity: newStock,
              type,
              reason: reason || 'Manual stock override',
              performedByAdminId: req.user?.id,
            },
          });
        }

        // 4. Write Audit Log
        await tx.auditLog.create({
          data: {
            adminUserId: req.user?.id,
            action: 'UPDATE_INVENTORY',
            details: `Manual inventory adjust (${type}) for store ID: ${storeId}, product ID: ${productId}. Old: ${prevStock}, Change: ${changeVal}, New: ${newStock}`,
          },
        });

        return inventory;
      });

      res.status(200).json({
        success: true,
        message: 'Store inventory updated successfully.',
        data: result,
      });
    } catch (error: any) {
      if (error.message === 'NEGATIVE_STOCK_BLOCKED') {
        res.status(400).json({
          success: false,
          message: 'Insufficient inventory. Stock cannot become negative.',
          errorCode: 'NEGATIVE_STOCK_BLOCKED',
        });
        return;
      }
      next(error);
    }
  }

  /**
   * Fetch Inventory History Transactions.
   * Access is limited to Super Admins (any store), or Store Managers (their assigned store only).
   */
  static async getInventoryHistory(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { role, storeId: managerStoreId } = req.user!;
      const { storeId, productId } = req.query;

      let targetStoreId = storeId as string | undefined;

      if (role === 'STORE_MANAGER') {
        // Enforce store-level isolation check
        targetStoreId = managerStoreId!;
      }

      const whereClause: any = {};
      if (targetStoreId) {
        whereClause.storeId = targetStoreId;
      }
      if (productId) {
        whereClause.productId = productId as string;
      }

      const history = await prisma.inventoryTransaction.findMany({
        where: whereClause,
        include: {
          store: { select: { name: true, storeId: true } },
          product: { select: { name: true, unit: true } },
          performedByAdmin: { select: { name: true, email: true } },
        },
        orderBy: { createdAt: 'desc' },
      });

      res.status(200).json({
        success: true,
        data: history,
      });
    } catch (error) {
      next(error);
    }
  }
}
