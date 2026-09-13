import { Router } from 'express';
import { CartController } from '../controllers/cartController';
import { authenticate } from '../middlewares/authMiddleware';

const router = Router();

// All cart operations require customer authentication
router.get('/', authenticate, CartController.getCart);
router.post('/items', authenticate, CartController.addItem);
router.put('/items/:id', authenticate, CartController.updateItem);
router.delete('/items/:id', authenticate, CartController.removeItem);

export default router;
