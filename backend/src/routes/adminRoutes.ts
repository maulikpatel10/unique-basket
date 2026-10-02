import { Router } from 'express';
import { AuthController } from '../controllers/authController';
import { AdminOrderController } from '../controllers/adminOrderController';
import { AdminManagerController } from '../controllers/adminManagerController';
import { ProductController } from '../controllers/productController';
import { AdminCustomerController } from '../controllers/adminCustomerController';
import { AdminPaymentController } from '../controllers/adminPaymentController';
import { AdminStoreController } from '../controllers/adminStoreController';
import { AdminAuditController } from '../controllers/adminAuditController';
import { AdminBannerController } from '../controllers/adminBannerController';
import { AdminSettingsController } from '../controllers/adminSettingsController';
import { AdminPincodeController } from '../controllers/adminPincodeController';
import { authenticate, requireRole } from '../middlewares/authMiddleware';
import { authRateLimits } from '../middlewares/rateLimit';

const router = Router();

// Public Admin Auth
router.post('/login', authRateLimits.adminLoginPerIp, authRateLimits.adminLoginPerEmail, AuthController.adminLogin);

// Protected Admin order routes
router.get(
  '/orders',
  authenticate,
  requireRole(['SUPER_ADMIN', 'STORE_MANAGER']),
  AdminOrderController.getOrders
);

router.get(
  '/orders/:id',
  authenticate,
  requireRole(['SUPER_ADMIN', 'STORE_MANAGER']),
  AdminOrderController.getOrderDetails
);

router.put(
  '/orders/:id/status',
  authenticate,
  requireRole(['SUPER_ADMIN', 'STORE_MANAGER']),
  AdminOrderController.updateOrderStatus
);

router.post(
  '/orders/pickup-verify',
  authenticate,
  requireRole(['SUPER_ADMIN', 'STORE_MANAGER']),
  AdminOrderController.verifyPickup
);

// Fares and COD settings management (SUPER_ADMIN only)
router.get(
  '/settings/fare-cod',
  authenticate,
  requireRole(['SUPER_ADMIN']),
  AdminSettingsController.getFareCodSettings
);

router.put(
  '/settings/fare-cod',
  authenticate,
  requireRole(['SUPER_ADMIN']),
  AdminSettingsController.updateFareCodSettings
);

// Legacy/general system configuration management
router.get(
  '/settings',
  authenticate,
  requireRole(['SUPER_ADMIN', 'STORE_MANAGER']),
  AdminSettingsController.getFareCodSettings
);

router.put(
  '/settings',
  authenticate,
  requireRole(['SUPER_ADMIN']),
  AdminSettingsController.updateFareCodSettings
);

// Store Manager Management (Super Admin only)
router.get(
  '/managers',
  authenticate,
  requireRole(['SUPER_ADMIN']),
  AdminManagerController.listManagers
);

router.post(
  '/managers',
  authenticate,
  requireRole(['SUPER_ADMIN']),
  AdminManagerController.createManager
);

router.get(
  '/managers/:id',
  authenticate,
  requireRole(['SUPER_ADMIN']),
  AdminManagerController.getManagerById
);

router.put(
  '/managers/:id',
  authenticate,
  requireRole(['SUPER_ADMIN']),
  AdminManagerController.updateManager
);

// Inventory transactions history log
router.get(
  '/inventory/transactions',
  authenticate,
  requireRole(['SUPER_ADMIN', 'STORE_MANAGER']),
  ProductController.getInventoryHistory
);

// Customer Management Routes (SUPER_ADMIN only)
router.get(
  '/customers',
  authenticate,
  requireRole(['SUPER_ADMIN']),
  AdminCustomerController.getCustomers
);

router.get(
  '/customers/:id',
  authenticate,
  requireRole(['SUPER_ADMIN']),
  AdminCustomerController.getCustomerById
);

router.put(
  '/customers/:id/status',
  authenticate,
  requireRole(['SUPER_ADMIN']),
  AdminCustomerController.updateCustomerStatus
);

// Payment Management Routes
router.get(
  '/payments',
  authenticate,
  requireRole(['SUPER_ADMIN', 'STORE_MANAGER']),
  AdminPaymentController.getPayments
);

router.get(
  '/payments/:id',
  authenticate,
  requireRole(['SUPER_ADMIN', 'STORE_MANAGER']),
  AdminPaymentController.getPaymentDetails
);
router.get('/stores', authenticate, requireRole(['SUPER_ADMIN', 'STORE_MANAGER']), AdminStoreController.listStores);
router.get('/stores/:id', authenticate, requireRole(['SUPER_ADMIN', 'STORE_MANAGER']), AdminStoreController.getStoreById);
router.post('/stores', authenticate, requireRole(['SUPER_ADMIN']), AdminStoreController.createStore);
router.put('/stores/:id', authenticate, requireRole(['SUPER_ADMIN']), AdminStoreController.updateStore);
router.delete('/stores/:id', authenticate, requireRole(['SUPER_ADMIN']), AdminStoreController.deleteStore);
// System Audit Logs Routes (Super Admin only)
router.get('/audit-logs', authenticate, requireRole(['SUPER_ADMIN']), AdminAuditController.getAuditLogs);
router.get('/audit-logs/actions', authenticate, requireRole(['SUPER_ADMIN']), AdminAuditController.getAuditActions);

// Marketing Banners Routes (Super Admin only)
router.get('/banners', authenticate, requireRole(['SUPER_ADMIN']), AdminBannerController.getBanners);
router.post('/banners', authenticate, requireRole(['SUPER_ADMIN']), AdminBannerController.createBanner);
router.get('/banners/:id', authenticate, requireRole(['SUPER_ADMIN']), AdminBannerController.getBannerById);
router.put('/banners/:id', authenticate, requireRole(['SUPER_ADMIN']), AdminBannerController.updateBanner);
router.delete('/banners/:id', authenticate, requireRole(['SUPER_ADMIN']), AdminBannerController.deleteBanner);

// Supported Pincodes / Delivery Areas (Super Admin only)
router.get('/pincodes', authenticate, requireRole(['SUPER_ADMIN']), AdminPincodeController.listPincodes);
router.post('/pincodes', authenticate, requireRole(['SUPER_ADMIN']), AdminPincodeController.createPincode);
router.get('/pincodes/:id', authenticate, requireRole(['SUPER_ADMIN']), AdminPincodeController.getPincodeById);
router.put('/pincodes/:id', authenticate, requireRole(['SUPER_ADMIN']), AdminPincodeController.updatePincode);
router.patch('/pincodes/:id/status', authenticate, requireRole(['SUPER_ADMIN']), AdminPincodeController.togglePincodeStatus);

export default router;
