import { Router } from 'express';
import { AuthController } from '../controllers/authController';
import { authRateLimits } from '../middlewares/rateLimit';

const router = Router();

router.post('/send-otp', authRateLimits.sendOtpPerIp, AuthController.sendOtp);
router.post('/verify-otp', authRateLimits.verifyOtpPerIp, AuthController.verifyOtp);
router.post('/refresh', authRateLimits.refreshPerIp, AuthController.refresh);
router.post('/logout', AuthController.logout);

export default router;
