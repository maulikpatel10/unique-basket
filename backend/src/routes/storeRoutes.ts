import { Router } from 'express';
import { StoreController } from '../controllers/storeController';
import { authenticate, requireRole } from '../middlewares/authMiddleware';

const router = Router();

// Store routes (accessible to logged-in users)
router.get('/', authenticate, StoreController.listStores);
router.get('/nearby', authenticate, StoreController.listStores); // Alias for coordinates searching
router.get('/:id', authenticate, StoreController.getStoreById);

// Admin-only Store modifications
router.post('/', authenticate, requireRole(['SUPER_ADMIN']), StoreController.createStore);
router.put('/:id', authenticate, requireRole(['SUPER_ADMIN']), StoreController.updateStore);
router.delete('/:id', authenticate, requireRole(['SUPER_ADMIN']), StoreController.deleteStore);

export default router;
