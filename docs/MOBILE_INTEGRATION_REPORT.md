# UNIQUE BASKET — Mobile Integration Report (Phase A Inspection)

**Date**: September 1, 2026  
**Status**: Inspection Complete — Ready for Phase B Architecture & Foundation Setup  
**Target Platform**: Flutter Mobile Application (iOS & Android)

---

## 1. Executive Summary

A comprehensive architectural and code-level inspection of the UNIQUE BASKET backend, database schema, and Admin Panel was conducted. The backend is solid, secure, and production-ready with full transactional guarantees, CAS inventory locking, and Razorpay cryptographic HMAC verification.

The customer mobile application will act strictly as a client consuming the existing REST API contracts without modifying established business rules, store isolation, or role-based security.

---

## 2. API & Feature Availability Breakdown

### A. ALREADY AVAILABLE & CAN USE DIRECTLY (Backend Ready)

1. **Customer OTP Authentication**:
   - `POST /api/v1/auth/send-otp` (Phone format validation & SMS OTP dispatch)
   - `POST /api/v1/auth/verify-otp` (OTP verification, JWT Access + Refresh token issuance, `isNewUser` flag)
   - `POST /api/v1/auth/refresh` (JWT Session restoration with refresh tokens)
   - `POST /api/v1/auth/logout` (Client session cleanup & device push token unregistration)

2. **Catalog & Categories**:
   - `GET /api/v1/categories` (Returns list of active product categories)
   - `GET /api/v1/products` (Filtered by `categoryId`, `search`, returns active products of active categories)
   - `GET /api/v1/products/:id` (Product details with unit, pricing, MRP, and category)
   - `GET /api/v1/products/store/:storeId` (Store-specific inventory availability, stock quantity, and pricing)

3. **Store Proximity & Fulfillments**:
   - `GET /api/v1/stores` (Lists active stores)
   - `GET /api/v1/stores?lat={lat}&lng={lng}&fulfillment=DELIVERY` (Calculates Haversine distance, checks delivery radius eligibility `isEligible`, and sorts closest store first)
   - `GET /api/v1/stores/:id` (Store details, operating hours, phone, address)

4. **Server-Side Persistent Cart**:
   - `GET /api/v1/cart` (Returns active cart items, individual totals, and calculated subtotal)
   - `POST /api/v1/cart/items` (Upserts decimal quantity item into user's cart)
   - `PUT /api/v1/cart/items/:id` (Updates decimal quantity; removes if quantity ≤ 0)
   - `DELETE /api/v1/cart/items/:id` (Deletes item from cart)

5. **Transactional Order Checkout & Fares / COD Enforcement**:
   - `POST /api/v1/orders` (Transactional order placement):
     - Calculates Haversine distance and automatically assigns nearest eligible store for `DELIVERY`.
     - Validates store existence for `PICKUP`.
     - Enforces Delivery minimum order threshold (`minimumOrderAmount`, default ₹199).
     - Applies free delivery threshold (`freeDeliveryThreshold`, default ₹499) vs standard fee (`deliveryFee`, default ₹30).
     - Sets delivery fee to ₹0 for `PICKUP`.
     - Enforces COD rules (`codEnabled`, `pickupCodEnabled`, `minimumCodOrderAmount`, `maximumCodOrderAmount`) and applies COD charge (`codCharge`, default ₹20).
     - Sets COD charge to ₹0 for `ONLINE`.
     - Atomically deducts inventory using CAS (Compare-And-Swap) with stock transaction audit logging.
     - Initializes Razorpay order (`razorpayOrder` payload) for `ONLINE` orders.
     - Empties customer cart upon successful placement.
     - Asynchronously notifies store managers via Firebase/mock notifications.

6. **Online Payment Verification**:
   - `POST /api/v1/payments/verify` (Cryptographically verifies Razorpay `order_id|payment_id` HMAC SHA256 signature, transitions order to `CONFIRMED` and payment status to `PAID`).

7. **Order History & Tracking**:
   - `GET /api/v1/orders` (Returns customer's order history sorted newest first).
   - `GET /api/v1/orders/:id` (Returns full order details, line items, address, store, and payment status).

8. **Device Tokens & Notifications**:
   - `POST /api/v1/notifications/tokens` (Registers FCM device token with platform: `ANDROID` | `IOS` | `WEB`).

---

### B. IDENTIFIED GAPS & RECOMMENDATIONS (Backend Missing vs Client Handling)

1. **Customer Address Management (CRUD)**:
   - *Current Backend State*: `UserAddress` table exists in PostgreSQL (`id`, `userId`, `title`, `addressLine`, `city`, `state`, `pincode`, `latitude`, `longitude`, `isDefault`), and `OrderController.createOrder` expects `addressId`. However, dedicated customer address CRUD endpoints (`GET/POST/PUT/DELETE /api/v1/addresses`) are not currently mounted in `app.ts`.
   - *Recommendation*: Add a lightweight, backward-compatible `addressRoutes.ts` & `addressController.ts` in Phase B/G when implementing customer address management, ensuring existing backend tests continue to pass 100%.

2. **Customer Public Marketing Banners**:
   - *Current Backend State*: `Banner` table exists and `AdminBannerController` is mounted at `/api/v1/admin/banners` (Super Admin role restricted).
   - *Recommendation*: Expose `GET /api/v1/banners` (public/authenticated customer) returning active banners sorted by `displayOrder`.

3. **Customer Delivery & COD Fare Settings Inspection**:
   - *Current Backend State*: Settings exist at `/api/v1/admin/settings` (admin restricted). Checkout dynamically validates and applies them on the server.
   - *Recommendation*: Provide a customer endpoint `GET /api/v1/settings/fare-cod` (or public settings) so Flutter can display estimated delivery fees and COD charges before checkout submission, while server remains the final authority.

4. **Customer Profile Update (Name / Email)**:
   - *Current Backend State*: User name and email are stored on `User` table; `verify-otp` accepts initial registration.
   - *Recommendation*: Add `PUT /api/v1/users/profile` for customer profile updates.

5. **Wishlist / Favourites**:
   - *Current Backend State*: No database table for favourites.
   - *Recommendation*: Handle favourites via local persistent device storage (Hive / SharedPreferences) in Flutter without requiring backend schema alteration.

---

### C. PHASE 2 (EXCLUDED FROM CURRENT SCOPE)

The following delivery personnel features are strictly deferred to Phase 2:
- Delivery personnel authentication, logins, and accounts
- Driver location streaming and driver tracking
- Delivery assignment and driver order dashboard
- Driver COD collection interface and delivery verification

---

### D. BLOCKERS

- **None**. Flutter architecture, foundation, state management, and core customer flows (Auth, Catalog, Cart, Checkout, Razorpay, Orders) can proceed immediately.
