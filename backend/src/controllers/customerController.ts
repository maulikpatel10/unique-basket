import { Response, NextFunction } from 'express';
import { prisma } from '../config/db';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';

export class CustomerController {
  /**
   * Get authenticated customer profile
   */
  static async getProfile(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'Authentication required.',
          errorCode: 'UNAUTHORIZED',
        });
        return;
      }

      const user = await prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true,
          phone: true,
          name: true,
          email: true,
          dob: true,
          isActive: true,
          createdAt: true,
          updatedAt: true,
        },
      });

      if (!user || !user.isActive) {
        res.status(404).json({
          success: false,
          message: 'Customer not found or account is deactivated.',
          errorCode: 'USER_NOT_FOUND',
        });
        return;
      }

      res.status(200).json({
        success: true,
        data: {
          user,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Update authenticated customer profile (e.g. name, email, dob)
   */
  static async updateProfile(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'Authentication required.',
          errorCode: 'UNAUTHORIZED',
        });
        return;
      }

      const { name, email, dob } = req.body;

      // Validate name if provided
      if (name !== undefined) {
        if (typeof name !== 'string' || name.trim().length === 0) {
          res.status(400).json({
            success: false,
            message: 'Name cannot be empty.',
            errorCode: 'INVALID_NAME',
          });
          return;
        }
        if (name.trim().length > 100) {
          res.status(400).json({
            success: false,
            message: 'Name cannot exceed 100 characters.',
            errorCode: 'NAME_TOO_LONG',
          });
          return;
        }
      }

      // Validate email if provided
      if (email !== undefined && email !== null && email !== '') {
        if (typeof email !== 'string' || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim())) {
          res.status(400).json({
            success: false,
            message: 'Invalid email address format.',
            errorCode: 'INVALID_EMAIL',
          });
          return;
        }
      }

      // Validate and parse date of birth if provided
      let parsedDob: Date | null | undefined = undefined;
      if (dob !== undefined) {
        if (dob === null || dob === '') {
          parsedDob = null;
        } else if (typeof dob === 'string') {
          const trimmedDob = dob.trim();
          const dateMatch = trimmedDob.match(/^(\d{4})-(\d{2})-(\d{2})/);
          if (!dateMatch) {
            res.status(400).json({
              success: false,
              message: 'Invalid date of birth format. Expected YYYY-MM-DD or ISO 8601 string.',
              errorCode: 'INVALID_DOB',
            });
            return;
          }

          const year = parseInt(dateMatch[1], 10);
          const month = parseInt(dateMatch[2], 10);
          const day = parseInt(dateMatch[3], 10);

          if (month < 1 || month > 12 || day < 1 || day > 31 || year < 1900) {
            res.status(400).json({
              success: false,
              message: 'Invalid date of birth value.',
              errorCode: 'INVALID_DOB',
            });
            return;
          }

          parsedDob = new Date(Date.UTC(year, month - 1, day, 0, 0, 0, 0));
          if (isNaN(parsedDob.getTime())) {
            res.status(400).json({
              success: false,
              message: 'Invalid date of birth.',
              errorCode: 'INVALID_DOB',
            });
            return;
          }

          if (parsedDob.getTime() > Date.now()) {
            res.status(400).json({
              success: false,
              message: 'Date of birth cannot be in the future.',
              errorCode: 'FUTURE_DOB',
            });
            return;
          }
        } else {
          res.status(400).json({
            success: false,
            message: 'Date of birth must be a string or null.',
            errorCode: 'INVALID_DOB',
          });
          return;
        }
      }

      const updatedUser = await prisma.user.update({
        where: { id: userId },
        data: {
          ...(name !== undefined ? { name: name.trim() } : {}),
          ...(email !== undefined ? { email: email === '' ? null : email.trim() } : {}),
          ...(parsedDob !== undefined ? { dob: parsedDob } : {}),
        },
        select: {
          id: true,
          phone: true,
          name: true,
          email: true,
          dob: true,
          isActive: true,
          createdAt: true,
          updatedAt: true,
        },
      });

      res.status(200).json({
        success: true,
        message: 'Profile updated successfully.',
        data: {
          user: updatedUser,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get authenticated customer addresses
   */
  static async getAddresses(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'Authentication required.',
          errorCode: 'UNAUTHORIZED',
        });
        return;
      }

      const addresses = await prisma.userAddress.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
      });

      res.status(200).json({
        success: true,
        data: {
          addresses,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Create a new address for authenticated customer
   */
  static async addAddress(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'Authentication required.',
          errorCode: 'UNAUTHORIZED',
        });
        return;
      }

      const { title, addressLine, city, state, pincode, latitude, longitude, isDefault } = req.body;

      if (!addressLine || typeof addressLine !== 'string' || addressLine.trim().length === 0) {
        res.status(400).json({
          success: false,
          message: 'Address line is required.',
          errorCode: 'MISSING_ADDRESS_LINE',
        });
        return;
      }

      if (!pincode || typeof pincode !== 'string' || !/^\d{6}$/.test(pincode.trim())) {
        res.status(400).json({
          success: false,
          message: 'A valid 6-digit pincode is required.',
          errorCode: 'INVALID_PINCODE',
        });
        return;
      }

      // Check if customer already has any address; if not, default to true
      const existingAddressCount = await prisma.userAddress.count({ where: { userId } });
      const makeDefault = isDefault ?? (existingAddressCount === 0);

      // If makeDefault is true, unset default on other addresses
      if (makeDefault && existingAddressCount > 0) {
        await prisma.userAddress.updateMany({
          where: { userId },
          data: { isDefault: false },
        });
      }

      // Rajkot default coordinates: 22.3039° N, 70.8022° E
      const lat = latitude !== undefined && latitude !== null ? Number(latitude) : 22.3039;
      const lng = longitude !== undefined && longitude !== null ? Number(longitude) : 70.8022;

      const address = await prisma.userAddress.create({
        data: {
          userId,
          title: (title && typeof title === 'string') ? title.trim() : 'Home',
          addressLine: addressLine.trim(),
          city: (city && typeof city === 'string') ? city.trim() : 'Rajkot',
          state: (state && typeof state === 'string') ? state.trim() : 'Gujarat',
          pincode: pincode.trim(),
          latitude: lat,
          longitude: lng,
          isDefault: makeDefault,
        },
      });

      res.status(201).json({
        success: true,
        message: 'Address saved successfully.',
        data: {
          address,
        },
      });
    } catch (error) {
      next(error);
    }
  }
}
