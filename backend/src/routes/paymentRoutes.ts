import { Router } from 'express';
import { PaymentController } from '../controllers/paymentController';
import { authenticate } from '../middlewares/authMiddleware';

const router = Router();

// Endpoint for customer verification
router.post('/verify', authenticate, PaymentController.verifyPayment);

// Webhook endpoint (must remain public to allow gateway callbacks)
router.post('/webhook', PaymentController.handleWebhook);

export default router;
