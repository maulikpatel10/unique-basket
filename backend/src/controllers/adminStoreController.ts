import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { prisma } from '../config/db';
import { StoreController } from './storeController';
import { getParam } from '../utils/request';

/**
 * Admin Store Controller – wraps existing StoreController with admin‑specific isolation.
 * Super Admin: full access (list, get, create, update, delete).
 * Store Manager: can only view their assigned store.
 */
export class AdminStoreController {
  /** List stores for admin dashboard */
  static async listStores(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      if (req.user?.role === 'SUPER_ADMIN') {
        // Delegate to existing controller (handles optional distance query etc.)
        await StoreController.listStores(req as any, res, next);
        return;
      }

      if (req.user?.role === 'STORE_MANAGER') {
        // Store Manager may only see their own store
        const storeId = req.user.storeId;
        if (!storeId) {
          res.status(400).json({ success: false, message: 'Store ID not available for manager.', errorCode: 'MISSING_STORE_ID' });
          return;
        }
        const store = await prisma.store.findUnique({
          where: { id: storeId },
        });
        if (!store) {
          res.status(404).json({ success: false, message: 'Store not found.', errorCode: 'STORE_NOT_FOUND' });
          return;
        }
        // Return as an array to keep response shape consistent with list endpoint
        res.status(200).json({ success: true, data: [store] });
        return;
      }

      // Fallback – should not happen because middleware restricts roles
      res.status(403).json({ success: false, message: 'Forbidden', errorCode: 'FORBIDDEN_ACCESS' });
    } catch (error) {
      next(error);
    }
  }

  /** Get a single store (admin view) */
  static async getStoreById(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = getParam(req, 'id');

      if (req.user?.role === 'SUPER_ADMIN') {
        // Super admin can view any store – reuse existing logic
        await StoreController.getStoreById(req as any, res, next);
        return;
      }

      if (req.user?.role === 'STORE_MANAGER') {
        if (req.user.storeId !== id) {
          // Manager trying to access another store
          res.status(403).json({ success: false, message: 'Access denied to this store.', errorCode: 'STORE_ACCESS_FORBIDDEN' });
          return;
        }
        // Use the existing controller – it already returns 404 if not found
        await StoreController.getStoreById(req as any, res, next);
        return;
      }

      res.status(403).json({ success: false, message: 'Forbidden', errorCode: 'FORBIDDEN_ACCESS' });
    } catch (error) {
      next(error);
    }
  }

  /** Create store – Super Admin only (middleware enforces) */
  static async createStore(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    // Directly delegate to existing StoreController which contains validation and audit logging
    await StoreController.createStore(req as any, res, next);
  }

  /** Update store – Super Admin only */
  static async updateStore(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    await StoreController.updateStore(req as any, res, next);
  }

  /** Delete (deactivate) store – Super Admin only */
  static async deleteStore(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    await StoreController.deleteStore(req as any, res, next);
  }
}
