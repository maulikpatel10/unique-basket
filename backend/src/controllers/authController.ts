import { Request, Response, NextFunction } from 'express';
import bcrypt from 'bcryptjs';
import { prisma } from '../config/db';
import { OtpService } from '../services/otpService';
import { generateAccessToken, generateRefreshToken, verifyRefreshToken } from '../utils/jwt';

export class AuthController {
  /**
   * Request OTP endpoint.
   */
  static async sendOtp(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { phone } = req.body;

      if (!phone || typeof phone !== 'string' || !/^\+?[1-9]\d{1,14}$/.test(phone)) {
        res.status(400).json({
          success: false,
          message: 'Invalid mobile number format. Please provide a valid phone number with country code.',
          errorCode: 'INVALID_PHONE_FORMAT',
        });
        return;
      }

      const result = await OtpService.sendOtp(phone);
      if (!result.success) {
        res.status(400).json({
          success: false,
          message: result.message,
          errorCode: 'OTP_REQUEST_FAILED',
        });
        return;
      }

      res.status(200).json({
        success: true,
        message: result.message,
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
      const { phone, otp } = req.body;

      if (!phone || !otp) {
        res.status(400).json({
          success: false,
          message: 'Phone number and OTP are required.',
          errorCode: 'MISSING_PARAMETERS',
        });
        return;
      }

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

      const refreshToken = generateRefreshToken({
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
        include: { managers: true },
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

      const refreshToken = generateRefreshToken({
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
   */
  static async refresh(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      const { refreshToken } = req.body;

      if (!refreshToken) {
        res.status(400).json({
          success: false,
          message: 'Refresh token is required.',
          errorCode: 'MISSING_REFRESH_TOKEN',
        });
        return;
      }

      try {
        const decoded = verifyRefreshToken(refreshToken);
        
        let accessToken = '';

        if (decoded.role === 'customer') {
          const user = await prisma.user.findUnique({
            where: { id: decoded.id },
          });

          if (!user) {
            res.status(401).json({
              success: false,
              message: 'Session invalid: User not found.',
              errorCode: 'USER_NOT_FOUND',
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
            where: { id: decoded.id },
            include: { managers: true },
          });

          if (!admin || !admin.isActive) {
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
      } catch (err) {
        res.status(401).json({
          success: false,
          message: 'Invalid or expired refresh token. Please log in again.',
          errorCode: 'INVALID_REFRESH_TOKEN',
        });
      }
    } catch (error) {
      next(error);
    }
  }

  /**
   * Logout endpoint.
   */
  static async logout(req: Request, res: Response, next: NextFunction): Promise<void> {
    try {
      // In stateless JWT, logout is primarily handled client-side.
      // However, we will clean up active push token registration here if a token is supplied.
      const { deviceToken } = req.body;
      
      if (deviceToken) {
        await prisma.deviceToken.deleteMany({
          where: { token: deviceToken },
        });
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
