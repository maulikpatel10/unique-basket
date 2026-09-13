import { Router } from 'express';
import { ProductController } from '../controllers/productController';
import { authenticate, requireRole, requireStoreAccess, restrictManagerAccess } from '../middlewares/authMiddleware';

const router = Router();

// Global product listing endpoints (Customer / Admin)
router.get('/', authenticate, ProductController.listProducts);
router.get('/:id', authenticate, ProductController.getProductById);

// Super Admin global product configuration
router.post('/', authenticate, requireRole(['SUPER_ADMIN']), ProductController.createProduct);
router.put('/:id', authenticate, requireRole(['SUPER_ADMIN']), ProductController.updateProduct);
router.delete('/:id', authenticate, requireRole(['SUPER_ADMIN']), ProductController.deleteProduct);

// Store-specific inventory endpoints
// 1. List products with store-specific inventory quantities
router.get('/store/:storeId', authenticate, restrictManagerAccess, ProductController.listStoreProducts);

// 2. Update store inventory quantity (Super Admin, or Store Manager assigned to this specific storeId)
router.put(
  '/store/:storeId/inventory/:productId',
  authenticate,
  requireRole(['SUPER_ADMIN', 'STORE_MANAGER']),
  requireStoreAccess,
  ProductController.updateStoreInventory
);

export default router;
