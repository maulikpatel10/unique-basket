import { Router } from 'express';
import { CartController } from '../controllers/cartController';
import { authenticate } from '../middlewares/authMiddleware';
import { validateBody } from '../middlewares/validate';
import { addCartItemSchema, updateCartItemSchema } from '../validation/schemas';

const router = Router();

// All cart operations require customer authentication
router.get('/', authenticate, CartController.getCart);
router.post('/items', authenticate, validateBody(addCartItemSchema), CartController.addItem);
router.put('/items/:id', authenticate, validateBody(updateCartItemSchema), CartController.updateItem);
router.delete('/items/:id', authenticate, CartController.removeItem);

export default router;
