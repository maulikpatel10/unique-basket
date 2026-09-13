import { Response, NextFunction } from 'express';
import { prisma } from '../config/db';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { Platform } from '@prisma/client';

export class NotificationController {
  /**
   * Register or update client device token for targeted push notifications.
   */
  static async registerToken(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { token, platform } = req.body;
      const userPayload = req.user!;

      if (!token || !platform || !Object.values(Platform).includes(platform)) {
        res.status(400).json({
          success: false,
          message: 'Valid token and platform (ANDROID, IOS, WEB) are required.',
          errorCode: 'MISSING_PARAMETERS',
        });
        return;
      }

      const isCustomer = userPayload.role === 'customer';

      // Upsert device token
      const deviceToken = await prisma.deviceToken.upsert({
        where: { token },
        update: {
          userId: isCustomer ? userPayload.id : null,
          adminUserId: !isCustomer ? userPayload.id : null,
          platform: platform as Platform,
          updatedAt: new Date(),
        },
        create: {
          token,
          platform: platform as Platform,
          userId: isCustomer ? userPayload.id : null,
          adminUserId: !isCustomer ? userPayload.id : null,
        },
      });

      res.status(200).json({
        success: true,
        message: 'Device token registered successfully.',
        data: deviceToken,
      });
    } catch (error) {
      next(error);
    }
  }
}
