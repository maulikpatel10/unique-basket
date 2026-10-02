import { Response, NextFunction } from 'express';
import { prisma } from '../config/db';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';

export class AdminPincodeController {
  /**
   * List all supported pincodes.
   * Access: SUPER_ADMIN only.
   */
  static async listPincodes(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { search, isActive } = req.query;

      const where: any = {};

      if (isActive !== undefined && isActive !== '') {
        where.isActive = isActive === 'true' || isActive === '1';
      }

      if (search && typeof search === 'string' && search.trim().length > 0) {
        const term = search.trim();
        where.OR = [
          { pincode: { contains: term, mode: 'insensitive' } },
          { city: { contains: term, mode: 'insensitive' } },
          { state: { contains: term, mode: 'insensitive' } },
        ];
      }

      const pincodes = await prisma.supportedPincode.findMany({
        where,
        orderBy: { pincode: 'asc' },
      });

      res.status(200).json({
        success: true,
        data: pincodes,
        total: pincodes.length,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get single supported pincode by ID.
   * Access: SUPER_ADMIN only.
   */
  static async getPincodeById(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const id = req.params.id as string;
      const pincodeRecord = await prisma.supportedPincode.findUnique({
        where: { id },
      });

      if (!pincodeRecord) {
        res.status(404).json({
          success: false,
          message: 'Supported pincode record not found.',
          errorCode: 'PINCODE_NOT_FOUND',
        });
        return;
      }

      res.status(200).json({
        success: true,
        data: pincodeRecord,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create a new supported pincode.
   * Access: SUPER_ADMIN only.
   */
  static async createPincode(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const adminUserId = req.user?.id;
      const { pincode, city, state, isActive } = req.body;

      if (!pincode || typeof pincode !== 'string' || !/^\d{6}$/.test(pincode.trim())) {
        res.status(400).json({
          success: false,
          message: 'A valid 6-digit numeric pincode is required.',
          errorCode: 'INVALID_PINCODE_FORMAT',
        });
        return;
      }

      const normalizedPincode = pincode.trim();
      const existing = await prisma.supportedPincode.findUnique({
        where: { pincode: normalizedPincode },
      });

      if (existing) {
        res.status(400).json({
          success: false,
          message: `Pincode ${normalizedPincode} already exists in supported pincodes.`,
          errorCode: 'DUPLICATE_PINCODE',
        });
        return;
      }

      const resolvedCity = (city && typeof city === 'string' && city.trim().length > 0) ? city.trim() : 'Rajkot';
      const resolvedState = (state && typeof state === 'string' && state.trim().length > 0) ? state.trim() : 'Gujarat';
      const resolvedActive = isActive !== undefined ? Boolean(isActive) : true;

      const created = await prisma.supportedPincode.create({
        data: {
          pincode: normalizedPincode,
          city: resolvedCity,
          state: resolvedState,
          isActive: resolvedActive,
        },
      });

      // Audit Log
      await prisma.auditLog.create({
        data: {
          adminUserId,
          action: 'SUPPORTED_PINCODE_CREATED',
          details: `Created supported pincode ${created.pincode} (${created.city}, ${created.state}) - Active: ${created.isActive}`,
        },
      });

      res.status(201).json({
        success: true,
        message: 'Supported pincode created successfully.',
        data: created,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update an existing supported pincode.
   * Access: SUPER_ADMIN only.
   */
  static async updatePincode(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const adminUserId = req.user?.id;
      const id = req.params.id as string;
      const { pincode, city, state, isActive } = req.body;

      const existing = await prisma.supportedPincode.findUnique({
        where: { id },
      });

      if (!existing) {
        res.status(404).json({
          success: false,
          message: 'Supported pincode record not found.',
          errorCode: 'PINCODE_NOT_FOUND',
        });
        return;
      }

      let normalizedPincode = existing.pincode;
      if (pincode !== undefined) {
        if (typeof pincode !== 'string' || !/^\d{6}$/.test(pincode.trim())) {
          res.status(400).json({
            success: false,
            message: 'A valid 6-digit numeric pincode is required.',
            errorCode: 'INVALID_PINCODE_FORMAT',
          });
          return;
        }
        normalizedPincode = pincode.trim();
        if (normalizedPincode !== existing.pincode) {
          const duplicate = await prisma.supportedPincode.findUnique({
            where: { pincode: normalizedPincode },
          });
          if (duplicate && duplicate.id !== id) {
            res.status(400).json({
              success: false,
              message: `Pincode ${normalizedPincode} is already registered.`,
              errorCode: 'DUPLICATE_PINCODE',
            });
            return;
          }
        }
      }

      const updated = await prisma.supportedPincode.update({
        where: { id },
        data: {
          pincode: normalizedPincode,
          ...(city !== undefined ? { city: city.trim() } : {}),
          ...(state !== undefined ? { state: state.trim() } : {}),
          ...(isActive !== undefined ? { isActive: Boolean(isActive) } : {}),
        },
      });

      // Audit Log
      await prisma.auditLog.create({
        data: {
          adminUserId,
          action: 'SUPPORTED_PINCODE_UPDATED',
          details: `Updated supported pincode ${updated.pincode} (${updated.city}, ${updated.state}) - Active: ${updated.isActive}`,
        },
      });

      res.status(200).json({
        success: true,
        message: 'Supported pincode updated successfully.',
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Toggle or update active status of a supported pincode.
   * Access: SUPER_ADMIN only.
   */
  static async togglePincodeStatus(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const adminUserId = req.user?.id;
      const id = req.params.id as string;
      const { isActive } = req.body;

      const existing = await prisma.supportedPincode.findUnique({
        where: { id },
      });

      if (!existing) {
        res.status(404).json({
          success: false,
          message: 'Supported pincode record not found.',
          errorCode: 'PINCODE_NOT_FOUND',
        });
        return;
      }

      const targetStatus = isActive !== undefined ? Boolean(isActive) : !existing.isActive;

      const updated = await prisma.supportedPincode.update({
        where: { id },
        data: { isActive: targetStatus },
      });

      // Audit Log
      await prisma.auditLog.create({
        data: {
          adminUserId,
          action: 'SUPPORTED_PINCODE_STATUS_CHANGED',
          details: `${targetStatus ? 'Activated' : 'Deactivated'} supported pincode ${updated.pincode}`,
        },
      });

      res.status(200).json({
        success: true,
        message: `Pincode ${updated.pincode} ${targetStatus ? 'activated' : 'deactivated'} successfully.`,
        data: updated,
      });
    } catch (error) {
      next(error);
    }
  }
}
