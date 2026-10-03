import { Response, NextFunction } from 'express';
import { prisma } from '../config/db';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { validateProductQuantity } from '../utils/quantity';
import { validatedBody } from '../middlewares/validate';
import { addCartItemSchema, updateCartItemSchema } from '../validation/schemas';
import { loadFareSettings, calculateDeliveryFee } from '../services/pricingService';
import { fromPaise, lineTotalPaise, toPaise } from '../utils/money';
import { getParam } from '../utils/request';

export class CartController {
  /**
   * Fetch current user's cart items and subtotal.
   */
  static async getCart(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.id;

      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized.',
          errorCode: 'UNAUTHORIZED',
        });
        return;
      }

      const cartItems = await prisma.cartItem.findMany({
        where: { userId },
        include: {
          product: {
            select: {
              id: true,
              name: true,
              price: true,
              mrp: true,
              unit: true,
              minQuantity: true,
              maxQuantity: true,
              quantityStep: true,
              isActive: true,
              category: { select: { isActive: true } },
            },
          },
        },
      });

      // Exclude items checkout would reject: inactive products or products in inactive categories (P1-05)
      const activeItems = cartItems.filter((item) => item.product.isActive && item.product.category.isActive);

      // Calculate subtotal safely avoiding floating point errors
      let subtotalPaise = 0;
      const formattedItems = activeItems.map((item) => {
        const itemQty = Number(item.quantity);
        const itemPrice = Number(item.product.price);
        // P2-03: exact paise arithmetic
        const itemTotalPaise = lineTotalPaise(itemQty, item.product.price);
        subtotalPaise += itemTotalPaise;
        const totalItemPrice = fromPaise(itemTotalPaise);

        return {
          id: item.id,
          productId: item.productId,
          productName: item.product.name,
          unit: item.product.unit,
          minQuantity: item.product.minQuantity != null ? Number(item.product.minQuantity) : null,
          maxQuantity: item.product.maxQuantity != null ? Number(item.product.maxQuantity) : null,
          quantityStep: item.product.quantityStep != null ? Number(item.product.quantityStep) : null,
          price: itemPrice,
          mrp: item.product.mrp ? Number(item.product.mrp) : null,
          quantity: itemQty,
          totalPrice: totalItemPrice,
        };
      });

      // Fetch delivery settings for authoritative pricing calculations
      const subtotal = fromPaise(subtotalPaise);

      // Same fare rules as checkout (P1-05). No delivery fee when the cart is empty or delivery is disabled.
      const fares = await loadFareSettings(prisma);
      const deliveryFee = activeItems.length > 0 && fares.deliveryEnabled
        ? calculateDeliveryFee(subtotal, fares)
        : 0.00;

      const total = fromPaise(subtotalPaise + toPaise(deliveryFee));

      res.status(200).json({
        success: true,
        data: {
          items: formattedItems,
          subtotal,
          deliveryFee,
          total,
          freeDeliveryThreshold: fares.freeDeliveryThreshold,
          deliveryEnabled: fares.deliveryEnabled,
          minimumOrderAmount: fares.minimumOrderAmount,
        },
      });
    } catch (error) {
      next(error);
    }
  }


  /**
   * Add item to cart (supports decimal quantity).
   */
  static async addItem(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.id;
      // Shape validated by validateBody(addCartItemSchema); product quantity rules are checked below.
      const { productId, quantity: targetQty } = validatedBody(res, addCartItemSchema);

      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized.',
          errorCode: 'UNAUTHORIZED',
        });
        return;
      }

      // Check product is active and its category is active
      const product = await prisma.product.findUnique({
        where: { id: productId },
        include: { category: true },
      });

      if (!product || !product.isActive || !product.category.isActive) {
        res.status(404).json({
          success: false,
          message: 'Product not found or currently unavailable.',
          errorCode: 'PRODUCT_UNAVAILABLE',
        });
        return;
      }

      const quantityError = validateProductQuantity(product, targetQty);
      if (quantityError) {
        res.status(400).json({
          success: false,
          message: quantityError,
          errorCode: 'INVALID_QUANTITY',
        });
        return;
      }

      // Upsert cart item
      const cartItem = await prisma.cartItem.upsert({
        where: {
          userId_productId: { userId, productId },
        },
        update: {
          quantity: targetQty,
        },
        create: {
          userId,
          productId,
          quantity: targetQty,
        },
      });

      res.status(201).json({
        success: true,
        message: 'Product added to cart successfully.',
        data: {
          id: cartItem.id,
          productId: cartItem.productId,
          quantity: Number(cartItem.quantity),
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update cart item quantity.
   */
  static async updateItem(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.id;
      const id = getParam(req, 'id');
      // validateBody(updateCartItemSchema): quantity is a number; 0 or less removes the line.
      const { quantity: targetQty } = validatedBody(res, updateCartItemSchema);

      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized.',
          errorCode: 'UNAUTHORIZED',
        });
        return;
      }


      const cartItem = await prisma.cartItem.findUnique({
        where: { id },
        include: { product: { select: { unit: true, minQuantity: true, maxQuantity: true, quantityStep: true } } },
      });

      if (!cartItem || cartItem.userId !== userId) {
        res.status(404).json({
          success: false,
          message: 'Cart item not found.',
          errorCode: 'CART_ITEM_NOT_FOUND',
        });
        return;
      }

      if (targetQty <= 0) {
        // If quantity is 0 or less, remove item
        await prisma.cartItem.delete({
          where: { id },
        });

        res.status(200).json({
          success: true,
          message: 'Cart item removed.',
        });
        return;
      }

      const quantityError = validateProductQuantity(cartItem.product, targetQty);
      if (quantityError) {
        res.status(400).json({
          success: false,
          message: quantityError,
          errorCode: 'INVALID_QUANTITY',
        });
        return;
      }

      const updated = await prisma.cartItem.update({
        where: { id },
        data: { quantity: targetQty },
      });

      res.status(200).json({
        success: true,
        message: 'Cart updated successfully.',
        data: {
          id: updated.id,
          productId: updated.productId,
          quantity: Number(updated.quantity),
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Remove cart item.
   */
  static async removeItem(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.id;
      const id = getParam(req, 'id');

      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'Unauthorized.',
          errorCode: 'UNAUTHORIZED',
        });
        return;
      }

      const cartItem = await prisma.cartItem.findUnique({
        where: { id },
      });

      if (!cartItem || cartItem.userId !== userId) {
        res.status(404).json({
          success: false,
          message: 'Cart item not found.',
          errorCode: 'CART_ITEM_NOT_FOUND',
        });
        return;
      }

      await prisma.cartItem.delete({
        where: { id },
      });

      res.status(200).json({
        success: true,
        message: 'Cart item removed.',
      });
    } catch (error) {
      next(error);
    }
  }
}
