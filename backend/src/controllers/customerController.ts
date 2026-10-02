import { Response, NextFunction } from 'express';
import { prisma } from '../config/db';
import { AuthenticatedRequest } from '../middlewares/authMiddleware';
import { getParam } from '../utils/request';
import { loadFareSettings } from '../services/pricingService';

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
          gender: true,
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
   * Update authenticated customer profile (e.g. name, email, dob, gender)
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

      const { name, email, dob, gender } = req.body;

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

      // Validate and parse gender if provided
      let parsedGender: string | null | undefined = undefined;
      if (gender !== undefined) {
        if (gender === null || gender === '') {
          parsedGender = null;
        } else if (typeof gender === 'string') {
          const normalized = gender.trim();
          const upper = normalized.toUpperCase();
          if (upper === 'MALE' || normalized === 'Male') {
            parsedGender = 'Male';
          } else if (upper === 'FEMALE' || normalized === 'Female') {
            parsedGender = 'Female';
          } else if (upper === 'OTHER' || normalized === 'Other') {
            parsedGender = 'Other';
          } else if (upper === 'PREFER_NOT_TO_SAY' || normalized === 'Prefer not to say') {
            parsedGender = 'Prefer not to say';
          } else {
            res.status(400).json({
              success: false,
              message: 'Invalid gender value. Allowed values: Male, Female, Other, Prefer not to say.',
              errorCode: 'INVALID_GENDER',
            });
            return;
          }
        } else {
          res.status(400).json({
            success: false,
            message: 'Gender must be a string or null.',
            errorCode: 'INVALID_GENDER',
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
          ...(parsedGender !== undefined ? { gender: parsedGender } : {}),
        },
        select: {
          id: true,
          phone: true,
          name: true,
          email: true,
          dob: true,
          gender: true,
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

      const normalizedPincode = pincode.trim();
      const supportedPincode = await prisma.supportedPincode.findFirst({
        where: { pincode: normalizedPincode, isActive: true },
      });

      if (!supportedPincode) {
        res.status(400).json({
          success: false,
          message: 'Delivery is currently not available for this pincode.',
          errorCode: 'PINCODE_NOT_SERVICEABLE',
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
          city: (city && typeof city === 'string') ? city.trim() : supportedPincode.city,
          state: (state && typeof state === 'string') ? state.trim() : supportedPincode.state,
          pincode: normalizedPincode,
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

  /**
   * Update an existing address for authenticated customer
   */
  static async updateAddress(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
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

      const id = getParam(req, 'id');
      const { title, addressLine, city, state, pincode, latitude, longitude, isDefault } = req.body;

      const existing = await prisma.userAddress.findFirst({
        where: { id, userId },
      });

      if (!existing) {
        res.status(404).json({
          success: false,
          message: 'Address not found.',
          errorCode: 'ADDRESS_NOT_FOUND',
        });
        return;
      }

      if (addressLine !== undefined && (typeof addressLine !== 'string' || addressLine.trim().length === 0)) {
        res.status(400).json({
          success: false,
          message: 'Address line cannot be empty.',
          errorCode: 'MISSING_ADDRESS_LINE',
        });
        return;
      }

      let validatedPincode: string | undefined = undefined;
      if (pincode !== undefined) {
        if (typeof pincode !== 'string' || !/^\d{6}$/.test(pincode.trim())) {
          res.status(400).json({
            success: false,
            message: 'A valid 6-digit pincode is required.',
            errorCode: 'INVALID_PINCODE',
          });
          return;
        }

        const normalizedPincode = pincode.trim();
        const supportedPincode = await prisma.supportedPincode.findFirst({
          where: { pincode: normalizedPincode, isActive: true },
        });

        if (!supportedPincode) {
          res.status(400).json({
            success: false,
            message: 'Delivery is currently not available for this pincode.',
            errorCode: 'PINCODE_NOT_SERVICEABLE',
          });
          return;
        }
        validatedPincode = normalizedPincode;
      }

      // If updating to default, unset other defaults
      if (isDefault === true) {
        await prisma.userAddress.updateMany({
          where: { userId, NOT: { id } },
          data: { isDefault: false },
        });
      }

      const updated = await prisma.userAddress.update({
        where: { id },
        data: {
          ...(title !== undefined ? { title: title.trim() } : {}),
          ...(addressLine !== undefined ? { addressLine: addressLine.trim() } : {}),
          ...(city !== undefined ? { city: city.trim() } : {}),
          ...(state !== undefined ? { state: state.trim() } : {}),
          ...(pincode !== undefined ? { pincode: pincode.trim() } : {}),
          ...(latitude !== undefined ? { latitude: Number(latitude) } : {}),
          ...(longitude !== undefined ? { longitude: Number(longitude) } : {}),
          ...(isDefault !== undefined ? { isDefault } : {}),
        },
      });

      res.status(200).json({
        success: true,
        message: 'Address updated successfully.',
        data: {
          address: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Set address as default for authenticated customer
   */
  static async setDefaultAddress(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
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

      const id = getParam(req, 'id');
      const existing = await prisma.userAddress.findFirst({
        where: { id, userId },
      });

      if (!existing) {
        res.status(404).json({
          success: false,
          message: 'Address not found.',
          errorCode: 'ADDRESS_NOT_FOUND',
        });
        return;
      }

      await prisma.userAddress.updateMany({
        where: { userId, NOT: { id } },
        data: { isDefault: false },
      });

      const updated = await prisma.userAddress.update({
        where: { id },
        data: { isDefault: true },
      });

      res.status(200).json({
        success: true,
        message: 'Default address updated successfully.',
        data: {
          address: updated,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Delete address for authenticated customer
   */
  static async deleteAddress(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
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

      const id = getParam(req, 'id');
      const existing = await prisma.userAddress.findFirst({
        where: { id, userId },
      });

      if (!existing) {
        res.status(404).json({
          success: false,
          message: 'Address not found.',
          errorCode: 'ADDRESS_NOT_FOUND',
        });
        return;
      }

      const wasDefault = existing.isDefault;

      await prisma.userAddress.delete({
        where: { id },
      });

      // If the deleted address was default, choose the first remaining address deterministically
      if (wasDefault) {
        const remaining = await prisma.userAddress.findMany({
          where: { userId },
          orderBy: { createdAt: 'desc' },
        });

        if (remaining.length > 0) {
          const hasDefault = remaining.some((a) => a.isDefault);
          if (!hasDefault) {
            await prisma.userAddress.update({
              where: { id: remaining[0].id },
              data: { isDefault: true },
            });
          }
        }
      }

      res.status(200).json({
        success: true,
        message: 'Address deleted successfully.',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get authenticated customer favorites list of product IDs and objects
   */
  static async getFavorites(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
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

      const favorites = await prisma.favorite.findMany({
        where: { userId },
        include: {
          product: {
            select: {
              id: true,
              name: true,
              description: true,
              price: true,
              mrp: true,
              unit: true,
              imageUrl: true,
              categoryId: true,
              isActive: true,
            },
          },
        },
        orderBy: { createdAt: 'desc' },
      });

      const activeFavorites = favorites.filter((f) => f.product.isActive);
      const productIds = activeFavorites.map((f) => f.productId);

      res.status(200).json({
        success: true,
        data: {
          productIds,
          favorites: activeFavorites.map((f) => ({
            id: f.id,
            productId: f.productId,
            product: f.product,
          })),
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Add a product to authenticated customer's favorites
   */
  static async addFavorite(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.id;
      const productId = req.params.productId || req.body.productId;

      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'Authentication required.',
          errorCode: 'UNAUTHORIZED',
        });
        return;
      }

      if (!productId) {
        res.status(400).json({
          success: false,
          message: 'Product ID is required.',
          errorCode: 'MISSING_PRODUCT_ID',
        });
        return;
      }

      const product = await prisma.product.findUnique({
        where: { id: productId },
      });

      if (!product || !product.isActive) {
        res.status(404).json({
          success: false,
          message: 'Product not found or currently unavailable.',
          errorCode: 'PRODUCT_NOT_FOUND',
        });
        return;
      }

      const favorite = await prisma.favorite.upsert({
        where: {
          userId_productId: { userId, productId },
        },
        create: {
          userId,
          productId,
        },
        update: {},
      });

      res.status(201).json({
        success: true,
        message: 'Product added to favourites successfully.',
        data: {
          id: favorite.id,
          productId: favorite.productId,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Remove a product from authenticated customer's favorites
   */
  static async removeFavorite(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const userId = req.user?.id;
      const productId = req.params.productId || req.body.productId;

      if (!userId) {
        res.status(401).json({
          success: false,
          message: 'Authentication required.',
          errorCode: 'UNAUTHORIZED',
        });
        return;
      }

      if (!productId) {
        res.status(400).json({
          success: false,
          message: 'Product ID is required.',
          errorCode: 'MISSING_PRODUCT_ID',
        });
        return;
      }

      await prisma.favorite.deleteMany({
        where: {
          userId,
          productId,
        },
      });

      res.status(200).json({
        success: true,
        message: 'Product removed from favourites successfully.',
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get public/customer delivery charge and threshold settings
   */
  static async getDeliverySettings(req: any, res: Response, next: NextFunction): Promise<void> {
    try {
      const fares = await loadFareSettings(prisma);
      res.status(200).json({
        success: true,
        data: {
          deliveryEnabled: fares.deliveryEnabled,
          deliveryFee: fares.deliveryFee,
          freeDeliveryThreshold: fares.freeDeliveryThreshold,
          minimumOrderAmount: fares.minimumOrderAmount,
        },
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Get active supported pincodes for delivery serviceability
   */
  static async getSupportedPincodes(req: any, res: Response, next: NextFunction): Promise<void> {
    try {
      const pincodes = await prisma.supportedPincode.findMany({
        where: { isActive: true },
        orderBy: { pincode: 'asc' },
      });

      res.status(200).json({
        success: true,
        data: pincodes,
        pincodes,
      });
    } catch (error) {
      next(error);
    }
  }

  /**
   * Check serviceability for a specific pincode
   */
  static async checkPincodeServiceability(req: any, res: Response, next: NextFunction): Promise<void> {
    try {
      const { pincode } = req.query;
      if (!pincode || typeof pincode !== 'string' || !/^\d{6}$/.test(pincode.trim())) {
        res.status(400).json({
          success: false,
          message: 'A valid 6-digit pincode is required.',
          errorCode: 'INVALID_PINCODE',
        });
        return;
      }

      const normalized = pincode.trim();
      const supported = await prisma.supportedPincode.findFirst({
        where: { pincode: normalized, isActive: true },
      });

      res.status(200).json({
        success: true,
        data: {
          isServiceable: !!supported,
          pincode: normalized,
          city: supported?.city || 'Rajkot',
          state: supported?.state || 'Gujarat',
        },
      });
    } catch (error) {
      next(error);
    }
  }
}


