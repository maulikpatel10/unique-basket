# UNIQUE BASKET — Technical Implementation Progress

## Stage 1: Backend Foundation & Database
- [x] Set up Node.js with TypeScript and Express.js framework
- [x] Initialize Prisma ORM / Knex with PostgreSQL configuration
- [x] Run migration to create core database tables (`users`, `stores`, `admin_users`, `products`, `orders`, `audit_logs`, etc.)
- [x] Seed database with initial categories (Fruits, Vegetables), mock stores, and admin credentials
- [x] Implement global error handlers, sanitization, and input validations

## Stage 2: Authentication & Security
- [x] Create JWT helper utils (sign, verify, refresh tokens)
- [x] Implement Send OTP and Verify OTP endpoints with simulated mock provider
- [x] Develop profile registration endpoint for new users
- [x] Implement admin login authentication and generate role/store-associated claims

## Stage 3: Store & Location Management
- [x] Implement Store CRUD endpoints (Super Admin only, logged in audit logs)
- [x] Write Haversine distance calculator query in PostgreSQL
- [x] Develop `GET /api/v1/stores/nearby` endpoint with delivery radius filtering and `is_eligible` indicators
- [x] Add error responses for out-of-delivery-bounds address checks

## Stage 4: Products, Categories & Inventory
- [x] Create Category and Product CRUD endpoints for Super Admin
- [x] Develop store-specific inventory management APIs (updating quantities, checking thresholds)
- [x] Enforce Store Manager access isolation on inventory routes (can only edit their store's stock)

## Stage 5: Cart & Checkout Operations
- [x] Build cart endpoints to add, update, and remove items with decimal quantities
- [x] Develop order total calculation service (verifies prices, applies admin-defined delivery fee or free threshold)
- [x] Implement transactional order creation (`POST /api/v1/orders`) binding store ID, updating inventory, and writing audit logs

## Stage 6: Store Pickup Verification & Payment Integration
- [x] Implement Store Pickup verification endpoint (`Order ID + Mobile Number`) for Store Managers
- [x] Integrate Razorpay order creation and server-side signature verification logic
- [x] Implement Razorpay Webhook signature parsing and status synchronization handlers

## Stage 7: Firebase Push Notifications
- [x] Register and save device tokens (`device_tokens` table)
- [x] Implement FCM notification delivery trigger for order status updates
- [x] Set up store manager topic/token routing for new orders

## Stage 8: React Admin Panel (TypeScript)
- [ ] Initialize React SPA with Vite, TypeScript, and Tailwind CSS
- [ ] Configure routing (Public, Protected, Role/Store-isolated routes)
- [ ] Design Super Admin views (Store CRUD, global products, banner configuration, reports)
- [ ] Design Store Manager views (Store orders list, inventory updates, Pickup Verification overlay)
- [ ] Connect React services to the TypeScript backend REST APIs

## Stage 9: Flutter Customer Mobile App
- [ ] Set up Flutter workspace structure following Riverpod state management
- [ ] Implement Splash, Onboarding, Mobile OTP Login, and Profile setup UI
- [ ] Integrate geocoding/Google Maps address selection
- [ ] Develop Home dashboard, Category filter, Product detail page with decimal quantity selector
- [ ] Build Cart and Checkout screens supporting Delivery (auto-assigned store) & Store Pickup (manually selected store)
- [ ] Integrate Razorpay SDK on Flutter and link to backend verification services

## Stage 10: E2E Integration & Verification
- [ ] Write automation tests for backend store access isolation
- [ ] Verify complete delivery/pickup order flows under high concurrent load mock simulations
- [ ] Prepare Android/iOS native bundles (signing, bundle identifiers, permissions descriptions)
