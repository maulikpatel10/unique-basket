import { Response, NextFunction } from 'express';
import bcrypt from 'bcryptjs';
import { prisma } from '../config/db';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { getParam } from '../utils/request';
import { paginationMeta, parsePagination } from '../utils/pagination';

export class AdminManagerController {
  /**
   * List all Store Managers.
   * Super Admin only.
   */
  static async listManagers(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { search, storeId, isActive } = req.query;

      // Build query conditions
      const whereClause: any = {
        role: 'STORE_MANAGER',
      };

      if (search) {
        whereClause.OR = [
          { name: { contains: search as string, mode: 'insensitive' } },
          { email: { contains: search as string, mode: 'insensitive' } },
        ];
      }

      if (isActive !== undefined) {
        whereClause.isActive = isActive === 'true';
      }

      if (storeId) {
        whereClause.managers = {
          some: {
            storeId: storeId as string,
          },
        };
      }

      const paging = parsePagination(req.query);
      const [managers, total] = await Promise.all([
        prisma.adminUser.findMany({
          where: whereClause,
          include: {
            managers: {
              include: {
                store: true,
              },
            },
          },
          orderBy: [{ name: 'asc' }, { id: 'asc' }],
          ...(paging ? { skip: paging.skip, take: paging.limit } : {}),
        }),
        paging ? prisma.adminUser.count({ where: whereClause }) : Promise.resolve(0),
      ]);

      // Map database schema response to a clean API response contract
      const mapped = managers.map((m) => {
        const assignment = m.managers.length > 0 ? m.managers[0] : null;
        return {
          id: m.id,
          name: m.name,
          email: m.email,
          role: m.role,
          isActive: m.isActive,
          createdAt: m.createdAt,
          updatedAt: m.updatedAt,
          storeId: assignment ? assignment.store.id : null,
          storeIdString: assignment ? assignment.store.storeId : null,
          storeName: assignment ? assignment.store.name : null,
        };
      });

      res.status(200).json({
        success: true,
        data: paging ? { managers: mapped, pagination: paginationMeta(total, paging) } : mapped,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create Store Manager account and assign to store.
   * Super Admin only.
   */
  static async createManager(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { name, email, password, storeId, isActive } = req.body;

      if (!name || !email || !password || !storeId) {
        res.status(400).json({
          success: false,
          message: 'All fields (name, email, password, storeId) are required.',
          errorCode: 'MISSING_PARAMETERS',
        });
        return;
      }

      // Check if email format is valid
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(email)) {
        res.status(400).json({
          success: false,
          message: 'Invalid email format.',
          errorCode: 'INVALID_EMAIL',
        });
        return;
      }

      // Validate store assignment
      const targetStore = await prisma.store.findUnique({
        where: { id: storeId },
      });

      if (!targetStore) {
        res.status(400).json({
          success: false,
          message: 'Assigned store does not exist.',
          errorCode: 'STORE_NOT_FOUND',
        });
        return;
      }

      // Check if email is already taken
      const existing = await prisma.adminUser.findUnique({
        where: { email },
      });

      if (existing) {
        res.status(400).json({
          success: false,
          message: 'A user with this email address already exists.',
          errorCode: 'DUPLICATE_EMAIL',
        });
        return;
      }

      // Encrypt password
      const passwordHash = await bcrypt.hash(password, 10);

      // Perform user creation and store binding in transaction
      const result = await prisma.$transaction(async (tx) => {
        const admin = await tx.adminUser.create({
          data: {
            name,
            email,
            passwordHash,
            role: 'STORE_MANAGER',
            isActive: isActive !== undefined ? !!isActive : true,
          },
        });

        const storeManager = await tx.storeManager.create({
          data: {
            adminUserId: admin.id,
            storeId: targetStore.id,
          },
        });

        // Write Audit Log
        await tx.auditLog.create({
          data: {
            adminUserId: req.user?.id,
            action: 'MANAGER_CREATED',
            details: `Created Store Manager account for: ${name} (${email}) assigned to store ${targetStore.storeId}`,
          },
        });

        return { admin, storeManager };
      });

      res.status(201).json({
        success: true,
        message: 'Store Manager created successfully.',
        data: {
          id: result.admin.id,
          name: result.admin.name,
          email: result.admin.email,
          role: result.admin.role,
          isActive: result.admin.isActive,
          storeId: targetStore.id,
          storeIdString: targetStore.storeId,
          storeName: targetStore.name,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update Store Manager details and re-assign store if required.
   * Super Admin only.
   */
  static async updateManager(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = getParam(req, 'id');
      const { name, email, password, storeId, isActive } = req.body;

      const admin = await prisma.adminUser.findUnique({
        where: { id },
        include: { managers: true },
      });

      if (!admin || admin.role !== 'STORE_MANAGER') {
        res.status(404).json({
          success: false,
          message: 'Store Manager not found.',
          errorCode: 'MANAGER_NOT_FOUND',
        });
        return;
      }

      // Validate unique email if changed
      if (email && email !== admin.email) {
        const duplicate = await prisma.adminUser.findUnique({
          where: { email },
        });
        if (duplicate) {
          res.status(400).json({
            success: false,
            message: 'A user with this email address already exists.',
            errorCode: 'DUPLICATE_EMAIL',
          });
          return;
        }
      }

      let targetStore: any = null;
      if (storeId) {
        targetStore = await prisma.store.findUnique({
          where: { id: storeId },
        });
        if (!targetStore) {
          res.status(400).json({
            success: false,
            message: 'Assigned store does not exist.',
            errorCode: 'STORE_NOT_FOUND',
          });
          return;
        }
      }

      // Perform update inside transaction to sync manager profile & store associations
      const updatedUser = await prisma.$transaction(async (tx) => {
        let passwordHash = undefined;
        if (password) {
          passwordHash = await bcrypt.hash(password, 10);
        }

        const updated = await tx.adminUser.update({
          where: { id },
          data: {
            name: name !== undefined ? name : undefined,
            email: email !== undefined ? email : undefined,
            passwordHash,
            isActive: isActive !== undefined ? !!isActive : undefined,
          },
        });

        // Handle Store Assignment Re-mapping
        if (targetStore) {
          const currentAssignment = admin.managers.length > 0 ? admin.managers[0] : null;
          if (!currentAssignment || currentAssignment.storeId !== targetStore.id) {
            // Delete old mappings
            await tx.storeManager.deleteMany({
              where: { adminUserId: id },
            });

            // Create new mapping
            await tx.storeManager.create({
              data: {
                adminUserId: id,
                storeId: targetStore.id,
              },
            });

            // Write Store Assignment Audit log
            await tx.auditLog.create({
              data: {
                adminUserId: req.user?.id,
                action: 'MANAGER_STORE_CHANGED',
                details: `Reassigned Store Manager ${updated.name} from store ID ${
                  currentAssignment ? currentAssignment.storeId : 'NONE'
                } to store ID ${targetStore.id}`,
              },
            });
          }
        }

        // Handle Activation/Deactivation Logs
        if (isActive !== undefined && isActive !== admin.isActive) {
          await tx.auditLog.create({
            data: {
              adminUserId: req.user?.id,
              action: isActive ? 'MANAGER_ACTIVATED' : 'MANAGER_DEACTIVATED',
              details: `${isActive ? 'Activated' : 'Deactivated'} Store Manager: ${updated.name} (${updated.email})`,
            },
          });
        }

        // Write General Update log
        await tx.auditLog.create({
          data: {
            adminUserId: req.user?.id,
            action: 'MANAGER_UPDATED',
            details: `Updated details for Store Manager: ${updated.name}`,
          },
        });

        return updated;
      });

      // Reload fresh relational profile details
      const freshUser = await prisma.adminUser.findUnique({
        where: { id: updatedUser.id },
        include: {
          managers: {
            include: { store: true },
          },
        },
      });

      const finalAssignment = freshUser?.managers[0];

      res.status(200).json({
        success: true,
        message: 'Store Manager updated successfully.',
        data: {
          id: freshUser?.id,
          name: freshUser?.name,
          email: freshUser?.email,
          role: freshUser?.role,
          isActive: freshUser?.isActive,
          storeId: finalAssignment ? finalAssignment.store.id : null,
          storeIdString: finalAssignment ? finalAssignment.store.storeId : null,
          storeName: finalAssignment ? finalAssignment.store.name : null,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get Store Manager details by ID.
   * Super Admin only.
   */
  static async getManagerById(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = getParam(req, 'id');

      const manager = await prisma.adminUser.findUnique({
        where: { id },
        include: {
          managers: {
            include: { store: true },
          },
        },
      });

      if (!manager || manager.role !== 'STORE_MANAGER') {
        res.status(404).json({
          success: false,
          message: 'Store Manager not found.',
          errorCode: 'MANAGER_NOT_FOUND',
        });
        return;
      }

      const assignment = manager.managers[0];

      res.status(200).json({
        success: true,
        data: {
          id: manager.id,
          name: manager.name,
          email: manager.email,
          role: manager.role,
          isActive: manager.isActive,
          createdAt: manager.createdAt,
          updatedAt: manager.updatedAt,
          storeId: assignment ? assignment.store.id : null,
          storeIdString: assignment ? assignment.store.storeId : null,
          storeName: assignment ? assignment.store.name : null,
          storeAddress: assignment ? assignment.store.address : null,
        },
      });
    } catch (error) {
      next(error);
    }
  }
}
