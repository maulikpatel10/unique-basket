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

export default router;
