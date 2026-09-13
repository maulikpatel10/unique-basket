import { Router } from 'express';
import { OrderController } from '../controllers/orderController';
import { authenticate } from '../middlewares/authMiddleware';

const router = Router();

router.post('/', authenticate, OrderController.createOrder);
router.get('/', authenticate, OrderController.getOrders);
router.get('/:id', authenticate, OrderController.getOrderById);
// Customer cancellation endpoint removed per business policy

export default router;
