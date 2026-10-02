import { Router } from 'express';
import { CustomerController } from '../controllers/customerController';
import { authenticate, requireRole } from '../middlewares/authMiddleware';

const router = Router();

// Profile endpoints
router.get('/profile', authenticate, requireRole(['customer']), CustomerController.getProfile);
router.patch('/profile', authenticate, requireRole(['customer']), CustomerController.updateProfile);
router.put('/profile', authenticate, requireRole(['customer']), CustomerController.updateProfile);

// Address endpoints
router.get('/addresses', authenticate, requireRole(['customer']), CustomerController.getAddresses);
router.post('/addresses', authenticate, requireRole(['customer']), CustomerController.addAddress);
router.put('/addresses/:id', authenticate, requireRole(['customer']), CustomerController.updateAddress);
router.patch('/addresses/:id', authenticate, requireRole(['customer']), CustomerController.updateAddress);
router.patch('/addresses/:id/default', authenticate, requireRole(['customer']), CustomerController.setDefaultAddress);
router.delete('/addresses/:id', authenticate, requireRole(['customer']), CustomerController.deleteAddress);

// Favorites endpoints
router.get('/favorites', authenticate, requireRole(['customer']), CustomerController.getFavorites);
router.post('/favorites', authenticate, requireRole(['customer']), CustomerController.addFavorite);
router.post('/favorites/:productId', authenticate, requireRole(['customer']), CustomerController.addFavorite);
router.delete('/favorites/:productId', authenticate, requireRole(['customer']), CustomerController.removeFavorite);

// Delivery Settings & Serviceability Pincodes endpoints
router.get('/delivery-settings', CustomerController.getDeliverySettings);
router.get('/pincodes', CustomerController.getSupportedPincodes);
router.get('/serviceability/pincodes', CustomerController.getSupportedPincodes);
router.get('/serviceability/check', CustomerController.checkPincodeServiceability);

export default router;

