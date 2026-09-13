import { Response, NextFunction } from 'express';
import { prisma } from '../config/db';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';

export class AdminSettingsController {
  /**
   * Fetch current Fare and COD configurations.
   * Access: SUPER_ADMIN only.
   */
  static async getFareCodSettings(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const settings = await prisma.deliverySettings.findFirst();

      const data = settings
        ? {
            id: settings.id,
            deliveryEnabled: settings.deliveryEnabled,
            deliveryFee: Number(settings.deliveryFee),
            freeDeliveryThreshold: Number(settings.freeDeliveryThreshold),
            minimumOrderAmount: Number(settings.minimumOrderAmount),
            codEnabled: settings.codEnabled,
            codCharge: Number(settings.codCharge),
            minimumCodOrderAmount: Number(settings.minimumCodOrderAmount),
            maximumCodOrderAmount: Number(settings.maximumCodOrderAmount),
            pickupCodEnabled: settings.pickupCodEnabled,
            updatedAt: settings.updatedAt,
          }
        : {
            deliveryEnabled: true,
            deliveryFee: 30.0,
            freeDeliveryThreshold: 499.0,
            minimumOrderAmount: 199.0,
            codEnabled: true,
            codCharge: 20.0,
            minimumCodOrderAmount: 100.0,
            maximumCodOrderAmount: 5000.0,
            pickupCodEnabled: true,
          };

      res.status(200).json({
        success: true,
        data,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update Fare and COD configurations with strict validation.
   * Access: SUPER_ADMIN only.
   */
  static async updateFareCodSettings(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const {
        deliveryEnabled,
        deliveryFee,
        freeDeliveryThreshold,
        minimumOrderAmount,
        codEnabled,
        codCharge,
        minimumCodOrderAmount,
        maximumCodOrderAmount,
        pickupCodEnabled,
      } = req.body;

      const current = await prisma.deliverySettings.findFirst();

      // Resolve candidate values
      const parsedDeliveryFee = deliveryFee !== undefined ? parseFloat(deliveryFee) : current ? Number(current.deliveryFee) : 30.0;
      const parsedFreeDeliveryThreshold = freeDeliveryThreshold !== undefined ? parseFloat(freeDeliveryThreshold) : current ? Number(current.freeDeliveryThreshold) : 499.0;
      const parsedMinimumOrderAmount = minimumOrderAmount !== undefined ? parseFloat(minimumOrderAmount) : current ? Number(current.minimumOrderAmount) : 199.0;
      const parsedCodCharge = codCharge !== undefined ? parseFloat(codCharge) : current ? Number(current.codCharge) : 20.0;
      const parsedMinCod = minimumCodOrderAmount !== undefined ? parseFloat(minimumCodOrderAmount) : current ? Number(current.minimumCodOrderAmount) : 100.0;
      const parsedMaxCod = maximumCodOrderAmount !== undefined ? parseFloat(maximumCodOrderAmount) : current ? Number(current.maximumCodOrderAmount) : 5000.0;

      const resolvedDeliveryEnabled = deliveryEnabled !== undefined ? Boolean(deliveryEnabled) : current ? current.deliveryEnabled : true;
      const resolvedCodEnabled = codEnabled !== undefined ? Boolean(codEnabled) : current ? current.codEnabled : true;
      const resolvedPickupCodEnabled = pickupCodEnabled !== undefined ? Boolean(pickupCodEnabled) : current ? current.pickupCodEnabled : true;

      // Validation 1: Numbers must be valid and non-NaN / finite
      if (
        isNaN(parsedDeliveryFee) ||
        isNaN(parsedFreeDeliveryThreshold) ||
        isNaN(parsedMinimumOrderAmount) ||
        isNaN(parsedCodCharge) ||
        isNaN(parsedMinCod) ||
        isNaN(parsedMaxCod) ||
        !isFinite(parsedDeliveryFee) ||
        !isFinite(parsedFreeDeliveryThreshold) ||
        !isFinite(parsedMinimumOrderAmount) ||
        !isFinite(parsedCodCharge) ||
        !isFinite(parsedMinCod) ||
        !isFinite(parsedMaxCod)
      ) {
        res.status(400).json({
          success: false,
          message: 'Invalid numerical values provided in settings.',
          errorCode: 'INVALID_SETTINGS_VALUES',
        });
        return;
      }

      // Validation 2: Monetary values cannot be negative
      if (
        parsedDeliveryFee < 0 ||
        parsedFreeDeliveryThreshold < 0 ||
        parsedMinimumOrderAmount < 0 ||
        parsedCodCharge < 0 ||
        parsedMinCod < 0 ||
        parsedMaxCod < 0
      ) {
        res.status(400).json({
          success: false,
          message: 'Monetary settings values cannot be negative.',
          errorCode: 'NEGATIVE_VALUES_NOT_ALLOWED',
        });
        return;
      }

      // Validation 3: minimumCodOrderAmount must not exceed maximumCodOrderAmount
      if (parsedMinCod > parsedMaxCod) {
        res.status(400).json({
          success: false,
          message: 'Minimum COD amount cannot be greater than maximum COD amount.',
          errorCode: 'INVALID_COD_RANGE',
        });
        return;
      }

      const updated = await prisma.deliverySettings.upsert({
        where: {
          id: current?.id || '00000000-0000-0000-0000-000000000000',
        },
        update: {
          deliveryEnabled: resolvedDeliveryEnabled,
          deliveryFee: parsedDeliveryFee,
          freeDeliveryThreshold: parsedFreeDeliveryThreshold,
          minimumOrderAmount: parsedMinimumOrderAmount,
          codEnabled: resolvedCodEnabled,
          codCharge: parsedCodCharge,
          minimumCodOrderAmount: parsedMinCod,
          maximumCodOrderAmount: parsedMaxCod,
          pickupCodEnabled: resolvedPickupCodEnabled,
        },
        create: {
          deliveryEnabled: resolvedDeliveryEnabled,
          deliveryFee: parsedDeliveryFee,
          freeDeliveryThreshold: parsedFreeDeliveryThreshold,
          minimumOrderAmount: parsedMinimumOrderAmount,
          codEnabled: resolvedCodEnabled,
          codCharge: parsedCodCharge,
          minimumCodOrderAmount: parsedMinCod,
          maximumCodOrderAmount: parsedMaxCod,
          pickupCodEnabled: resolvedPickupCodEnabled,
        },
      });

      // Write Audit Log
      await prisma.auditLog.create({
        data: {
          adminUserId: req.user?.id,
          action: 'FARE_COD_SETTINGS_UPDATED',
          details: JSON.stringify({
            previous: current
              ? {
                  deliveryEnabled: current.deliveryEnabled,
                  deliveryFee: Number(current.deliveryFee),
                  freeDeliveryThreshold: Number(current.freeDeliveryThreshold),
                  minimumOrderAmount: Number(current.minimumOrderAmount),
                  codEnabled: current.codEnabled,
                  codCharge: Number(current.codCharge),
                  minimumCodOrderAmount: Number(current.minimumCodOrderAmount),
                  maximumCodOrderAmount: Number(current.maximumCodOrderAmount),
                  pickupCodEnabled: current.pickupCodEnabled,
                }
              : null,
            new: {
              deliveryEnabled: updated.deliveryEnabled,
              deliveryFee: Number(updated.deliveryFee),
              freeDeliveryThreshold: Number(updated.freeDeliveryThreshold),
              minimumOrderAmount: Number(updated.minimumOrderAmount),
              codEnabled: updated.codEnabled,
              codCharge: Number(updated.codCharge),
              minimumCodOrderAmount: Number(updated.minimumCodOrderAmount),
              maximumCodOrderAmount: Number(updated.maximumCodOrderAmount),
              pickupCodEnabled: updated.pickupCodEnabled,
            },
          }),
        },
      });

      res.status(200).json({
        success: true,
        message: 'Fares and COD settings updated successfully.',
        data: {
          id: updated.id,
          deliveryEnabled: updated.deliveryEnabled,
          deliveryFee: Number(updated.deliveryFee),
          freeDeliveryThreshold: Number(updated.freeDeliveryThreshold),
          minimumOrderAmount: Number(updated.minimumOrderAmount),
          codEnabled: updated.codEnabled,
          codCharge: Number(updated.codCharge),
          minimumCodOrderAmount: Number(updated.minimumCodOrderAmount),
          maximumCodOrderAmount: Number(updated.maximumCodOrderAmount),
          pickupCodEnabled: updated.pickupCodEnabled,
          updatedAt: updated.updatedAt,
        },
      });
    } catch (error) {
      next(error);
    }
  }
}
