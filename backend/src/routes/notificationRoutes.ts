import { Router } from 'express';
import { NotificationController } from '../controllers/notificationController';
import { authenticate } from '../middlewares/authMiddleware';

const router = Router();

router.post('/tokens', authenticate, NotificationController.registerToken);

export default router;
