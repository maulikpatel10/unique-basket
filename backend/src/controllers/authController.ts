import { Request, Response, NextFunction } from 'express';
import bcrypt from 'bcryptjs';
import { prisma } from '../config/db';
import { OtpService, isOtpBypassEnabled } from '../services/otpService';
import { generateAccessToken } from '../utils/jwt';
import { validatedBody } from '../middlewares/validate';
import { sendOtpSchema, verifyOtpSchema } from '../validation/schemas';
import { issueRefreshToken, validateRefreshToken, revokeRefreshSession } from '../services/sessionService';

export class AuthController {
  /**
   * Request OTP endpoint.
   */
  static async sendOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      // Body validated and phone normalised to +91XXXXXXXXXX by validateBody(sendOtpSchema)
      const { phone } = validatedBody(res, sendOtpSchema);

      const result = await OtpService.sendOtp(phone);
      if (!result.success) {
        res.status(400).json({
          success: false,
          message: result.message,
          errorCode: 'OTP_REQUEST_FAILED',
        });
        return;
      }

      const isDevOrTest = isOtpBypassEnabled();

      res.status(200).json({
        success: true,
        message: result.message,
        ...(isDevOrTest && result.otp ? { otp: result.otp } : {}),
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Verify OTP endpoint.
   */
  static async verifyOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      // Body validated and phone normalised by validateBody(verifyOtpSchema)
      const { phone, otp } = validatedBody(res, verifyOtpSchema);

      const otpResult = await OtpService.verifyOtp(phone, otp);
      if (!otpResult.success) {
        res.status(400).json({
          success: false,
          message: otpResult.message,
          errorCode: 'OTP_VERIFICATION_FAILED',
        });
        return;
      }

      // Check if user exists in the database
      let user = await prisma.user.findUnique({
        where: { phone },
      });

      if (user && !user.isActive) {
        res.status(401).json({
          success: false,
          message: 'Account is deactivated. Please contact support.',
          errorCode: 'ACCOUNT_DEACTIVATED',
        });
        return;
      }

      let isNewUser = false;

      if (!user) {
        isNewUser = true;
        // Create user
        user = await prisma.user.create({
          data: {
            phone,
          },
        });
      } else if (!user.name) {
        isNewUser = true;
      }

      // Generate Access and Refresh JWT tokens
      const accessToken = generateAccessToken({
        id: user.id,
        role: 'customer',
        phone: user.phone,
      });

      const refreshToken = await issueRefreshToken({
        id: user.id,
        role: 'customer',
      });

      res.status(200).json({
        success: true,
        message: 'OTP verified successfully.',
        data: {
          user: {
            id: user.id,
            phone: user.phone,
            name: user.name || null,
          },
          isNewUser,
          token: accessToken,
          refreshToken: refreshToken,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Admin Login endpoint.
   */
  static async adminLogin(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { email, password } = req.body;

      if (!email || !password) {
        res.status(400).json({
          success: false,
          message: 'Email and password are required.',
          errorCode: 'MISSING_CREDENTIALS',
        });
        return;
      }

      const admin = await prisma.adminUser.findUnique({
        where: { email },
        include: { managers: { orderBy: { assignedAt: 'asc' } } },
      });

      if (!admin || !admin.isActive) {
        res.status(401).json({
          success: false,
          message: 'Invalid credentials or account is deactivated.',
          errorCode: 'INVALID_CREDENTIALS',
        });
        return;
      }

      const isMatch = await bcrypt.compare(password, admin.passwordHash);
      if (!isMatch) {
        res.status(401).json({
          success: false,
          message: 'Invalid credentials.',
          errorCode: 'INVALID_CREDENTIALS',
        });
        return;
      }

      const storeId = admin.role === 'STORE_MANAGER' && admin.managers.length > 0
        ? admin.managers[0].storeId
        : undefined;

      const accessToken = generateAccessToken({
        id: admin.id,
        role: admin.role as 'SUPER_ADMIN' | 'STORE_MANAGER',
        email: admin.email,
        storeId,
      });

      const refreshToken = await issueRefreshToken({
        id: admin.id,
        role: admin.role,
      });

      res.status(200).json({
        success: true,
        message: 'Admin logged in successfully.',
        data: {
          admin: {
            id: admin.id,
            email: admin.email,
            name: admin.name,
            role: admin.role,
            storeId: storeId || null,
          },
          token: accessToken,
          refreshToken: refreshToken,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Refresh Token endpoint.
   * P1-08: the refresh token must belong to a live (not revoked, not expired) session
   * and the account must still be active.
   */
  static async refresh(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken || typeof refreshToken !== 'string') {
        res.status(400).json({
          success: false,
          message: 'Refresh token is required.',
          errorCode: 'MISSING_REFRESH_TOKEN',
        });
        return;
      }

      // Throws AppError 401 INVALID_REFRESH_TOKEN (handled globally)
      const session = await validateRefreshToken(refreshToken);

      let accessToken = '';

      if (session.role === 'customer') {
        const user = await prisma.user.findUnique({
          where: { id: session.id },
        });

        if (!user) {
          res.status(401).json({
            success: false,
            message: 'Session invalid: User not found.',
            errorCode: 'USER_NOT_FOUND',
          });
          return;
        }

        if (!user.isActive) {
          await revokeRefreshSession(session.jti);
          res.status(401).json({
            success: false,
            message: 'Customer account is deactivated.',
            errorCode: 'ACCOUNT_DEACTIVATED',
          });
          return;
        }

        accessToken = generateAccessToken({
          id: user.id,
          role: 'customer',
          phone: user.phone,
        });
      } else {
        // Admin User refresh session
        const admin = await prisma.adminUser.findUnique({
          where: { id: session.id },
          include: { managers: { orderBy: { assignedAt: 'asc' } } },
        });

        if (!admin || !admin.isActive) {
          await revokeRefreshSession(session.jti);
          res.status(401).json({
            success: false,
            message: 'Session invalid or admin account deactivated.',
            errorCode: 'ADMIN_INACTIVE',
          });
          return;
        }

        const storeId = admin.role === 'STORE_MANAGER' && admin.managers.length > 0
          ? admin.managers[0].storeId
          : undefined;

        accessToken = generateAccessToken({
          id: admin.id,
          role: admin.role as 'SUPER_ADMIN' | 'STORE_MANAGER',
          email: admin.email,
          storeId,
        });
      }

      res.status(200).json({
        success: true,
        data: {
          token: accessToken,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Logout endpoint.
   * P1-08: revokes the supplied refresh token's session. A device token is only removed
   * when it belongs to the owner of that (valid) refresh token.
   */
  static async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refreshToken, deviceToken } = req.body;

      if (refreshToken && typeof refreshToken === 'string') {
        try {
          const session = await validateRefreshToken(refreshToken);
          await revokeRefreshSession(session.jti);

          if (deviceToken && typeof deviceToken === 'string') {
            await prisma.deviceToken.deleteMany({
              where: session.role === 'customer'
                ? { token: deviceToken, userId: session.id }
                : { token: deviceToken, adminUserId: session.id },
            });
          }
        } catch {
          // Already invalid/expired/revoked: nothing to revoke. Logout stays idempotent.
        }
      }

      res.status(200).json({
        success: true,
        message: 'Logged out successfully.',
      });
    } catch (error) {
      next(error);
    }
  }
}
