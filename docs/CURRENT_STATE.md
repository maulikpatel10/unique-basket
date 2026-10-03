# UNIQUE BASKET — Current State (Repository Audit)

**Audited branch:** `feature/customer-app` @ `c6167c7` (2026-10-02)
**Scope:** CURRENT IMPLEMENTATION only. Nothing here is a product decision. See `docs/DECISIONS.md`.

> **Section 0 reflects the code after the 2026-10-02 backlog sweep.** Sections 1–6 are the original audit; where they conflict, section 0 wins. Task-level detail is in `docs/TASKS.md`.

## 0. Implementation updates since the audit

**Backend**
- Build: `npm run build` (tsconfig.build.json, `src` only) produces `dist/server.js`; `tsc --noEmit` clean.
- Startup validates `JWT_SECRET`/`JWT_REFRESH_SECRET` (no fallbacks; strong secrets required outside development/test).
- OTP: static `1234` bypass only when `NODE_ENV` is `development`/`test`; otherwise random 4-digit OTP (D-004), never returned or logged. No SMS provider yet (P4-02).
- Sessions: refresh tokens are backed by `refresh_tokens` rows (revocable); logout revokes the session; refresh rejects deactivated accounts. Admin role and manager store are resolved from the DB on every request; managers without a store get 403.
- Rate limiting (in-memory, single instance) on send-otp, verify-otp, refresh and admin login.
- Errors: client errors map to 4xx with stable `errorCode`s (invalid JSON/UUID, not found, duplicates, validation, checkout/inventory validation).
- Orders: fulfillment-aware status rules; PICKED_UP only via pickup verification from READY_FOR_PICKUP (D-006); unpaid ONLINE orders can only be cancelled (D-005); auto-PAID on delivery only for COD; delivery address snapshot stored on orders.
- Inventory: atomic stock restore, single cancellation wins, row locks for manual adjustments.
- Quantities: product-level admin-configured min/max/step (D-012, `utils/quantity.ts`), enforced on cart add/update and order creation. Unit precision: PIECE, PACK, DOZEN and GRAM are whole numbers; KG allows up to 3 decimals. Rules are optional per product. Unconfigured products get unit precision checks only.
- Cart and checkout share fare rules (`services/pricingService.ts`).
- Seed refuses to run outside development/test.
- Money: cart/checkout totals use exact integer-paise arithmetic (`utils/money.ts`).
- HTTP: `CORS_ORIGINS` allow-list, security headers, `TRUST_PROXY`, body limit (413); structured request log; `/health` checks the DB (503 when down); graceful SIGTERM/SIGINT shutdown.
- Admin dashboard metrics come from `GET /admin/dashboard/summary` (DB aggregates, store-isolated).
- Tests: 37 suites / 354 tests pass on a fresh migrated+seeded DB.

**Customer app (Flutter)**
- `flutter analyze` clean; 603 tests pass.
- Environment from `--dart-define=APP_ENV`; release/staging require `--dart-define=API_BASE_URL` (no hard-coded production or LAN URL). iOS only declares camera/photo permissions.
- Route guard redirects protected routes to login without a token; session expiry (refresh rejected) redirects to login; dev routes debug-only.
- Logout revokes the backend session (fire-and-forget).
- Cart write failures are surfaced (SnackBar) and reconciled with the server cart; checkout never shows placeholder items/fake contact data and has no client-only discount.
- Decimal quantity UI done (P1-03/D-012: per-product +/- steps, cart badge counts product lines). Still open: location capture (P1-01, blocked on P4-04/P4-05).

**Admin panel**
- Refreshes expired access tokens (single-flight) and revokes the session on logout; no token logging.
- "Verify Pickup" opens pickup verification; unpaid ONLINE orders show "Awaiting Payment".
- Dashboard uses the server-side summary; pages are lazy-loaded (main chunk ~303 kB).
- Vitest suite (12 tests); `npm run lint` → 0 errors; build passes.

---

## 1. Branches

| Branch | Content |
|---|---|
| `main` | Only `README.md` (initial commit) |
| `develop` | Monorepo init + admin panel + backend (`b8d8654`) |
| `feature/admin-panel`, `feature/backend` | Merged into `develop` |
| `feature/customer-app` | `develop` + Flutter customer app (8 commits after `develop`) |
| `feature/categories`, `feature/splash` | Earlier points on the customer-app line |

No CI configuration exists. Branch protection status on GitHub: not verified from the repo.

---

## 2. Backend (`backend/`)

**Stack:** Node.js, TypeScript, Express 5, Prisma 7 (`@prisma/adapter-pg`), PostgreSQL, JWT (`jsonwebtoken`), bcryptjs, firebase-admin, razorpay, Jest + Supertest (`@swc/jest`).

**Scripts:** `dev` (tsx watch), `build` (tsc), `start`, `db:seed`, `test` (`jest --runInBand`).

**Structure:** `src/app.ts` (routes, 404, global error handler), `src/server.ts`, `config/` (db, razorpay), `controllers/` (19), `routes/` (11), `middlewares/authMiddleware.ts`, `services/` (otp, notification), `utils/` (distance, jwt, orderNumber). Business logic lives mostly in controllers (no service layer for orders/cart).

**Response shape:** `{ success, message?, data?, errorCode? }`.

### 2.1 Routes (prefix `/api/v1`)
- `auth`: send-otp, verify-otp, refresh, logout; admin `login`
- `customer`: profile (GET/PUT/PATCH), addresses CRUD + default, favorites, delivery-settings, pincodes, serviceability check (some public)
- `stores`: list / nearby (lat/lng + Haversine), get; admin CRUD
- `categories`, `products`: list/get (authenticated); SUPER_ADMIN CRUD; store inventory
- `banners`, `cart` (items CRUD, decimal qty), `orders` (create, list, get)
- `payments`: `verify` (authenticated), `webhook` (public, signature-checked)
- `notifications`: list, unread-count, read, read-all, register device token
- `admin`: stores, orders (status transitions, pickup-verify), customers, managers, payments, pincodes, settings (fares/COD), banners, audit logs
- `GET /health`

### 2.2 Auth
- Request bodies for auth, profile, addresses, cart, orders and admin products are validated by `validateBody(schema)` (`src/validation/`, P2-01) with the existing errorCodes.
- Customer: phone OTP → access token (15m) + refresh token (7d). Phone numbers are India-only and normalized to `+91XXXXXXXXXX` (`utils/phone.ts`, D-008); 10-digit input is accepted.
- Admin: email + bcrypt password.
- Roles: `customer`, `SUPER_ADMIN`, `STORE_MANAGER`. `requireRole`, `requireStoreAccess` enforce RBAC/store isolation. Active status re-checked from DB per request.
- JWT secrets fall back to hard-coded strings (`fallback_access_secret`, `fallback_refresh_secret`) if env missing — **security risk**.

### 2.3 OTP (`services/otpService.ts`)
- In-memory `Map` (not persisted; not multi-instance safe).
- `NODE_ENV` = `development`/`test` only: static OTP `1234`, returned in API response and logged. Otherwise (including unset): random 4-digit OTP (`crypto.randomInt`), not returned or logged (D-004, P0-01).
- No SMS provider; outside dev/test there is no way to deliver the OTP yet (P4-02).
- Expiry 5 min, resend cooldown 60 s, 3 verify attempts, 5 requests/hour → 15 min block.

### 2.4 Orders (`controllers/orderController.ts`)
- Single DB transaction: load `DeliverySettings` → fulfillment check → per-item stock CAS decrement + `InventoryTransaction` → totals → order + items → cart clear.
- DELIVERY: address must belong to user; nearest active store within its `deliveryRadiusKm` is auto-assigned (Haversine). Error `NO_DELIVERY_AVAILABLE`.
- PICKUP: client supplies `storeId`; store must be active. Delivery fee 0.
- Fees/COD rules come from `DeliverySettings` (confirmed values D-009, also the schema/code/seed defaults: fee ₹30, free ≥ ₹200, min order ₹199, COD charge ₹20, COD ₹100–₹5000).
- ONLINE: creates a Razorpay order (mock in test or with mock key).
- Order number via `DailyOrderSequence` (`utils/orderNumber.ts`).
- Store managers notified via NotificationService.

### 2.5 Payments
- `config/razorpay.ts`: real Razorpay client, or mock when `NODE_ENV=test` / mock key id. Falls back to `mock_key_id` / `mock_key_secret` if env missing.
- `paymentController.verifyPayment`: HMAC-SHA256 signature check with `timingSafeEqual`; marks PAID / CONFIRMED.
- `handleWebhook`: `x-razorpay-signature` check; secret falls back to `mock_webhook_secret`.
- Prisma `Payment` model has Razorpay-specific columns.
- **Provider is not decided** (DECISIONS P-001). This code exists; it is not a decision.

### 2.6 Notifications
- `firebase-admin` initialized only if `FIREBASE_SERVICE_ACCOUNT` env present; else console mock.
- In-app notifications always persisted (`Notification` model). Device tokens in `DeviceToken`.

### 2.7 Database (Prisma, `prisma/schema.prisma`)
Models: User, UserAddress (lat/lng required), Store (radius, hours), AdminUser (role enum), StoreManager, Category (flat), Product (unit enum KG/GRAM/PIECE/PACK/DOZEN, price, mrp), StoreInventory (decimal stock), Order, OrderItem (historical name/unit/price), Payment, DeviceToken, DeliverySettings, Banner, AuditLog, CartItem, Favorite, InventoryTransaction, DailyOrderSequence, Notification, SupportedPincode (defaults city Rajkot, state Gujarat).

Enums: FulfillmentType (DELIVERY, PICKUP), PaymentMethod (COD, ONLINE), PaymentStatus (PENDING, PAID, FAILED), OrderStatus (PLACED, CONFIRMED, PREPARING, READY_FOR_PICKUP, PICKED_UP, OUT_FOR_DELIVERY, DELIVERED, CANCELLED).

15 migrations (2026-08-23 → 2026-10-02), including `20261002180000_add_refresh_tokens` and `20261002190000_add_order_delivery_address_snapshot` (additive). Seed: `prisma/seed.ts`.

**Migration status:**
- Latest migration: `20261002120000_add_favorites_notifications_pincodes_order_sequences` (commit `f392ade`). It creates the tables for `Favorite` (`user_favorites`), `Notification` (`notifications`), `SupportedPincode` (`supported_pincodes`) and `DailyOrderSequence` (`daily_order_sequences`), with their indexes and foreign keys. These models had been added to `schema.prisma` in commit `038dfa7` without a migration.
- A fresh database built with `prisma migrate deploy` now matches `schema.prisma` (no `migrate diff` difference).
- Development database (reported by project owner): `20260929130000_add_user_gender` has been reconciled/applied there.

### 2.8 Tests
20 Jest suites in `backend/tests/` (auth, catalog, cart/order, admin order/payment/store/pincodes/settings, inventory, notifications, etc.). Require a PostgreSQL database. Not executed during this audit.

### 2.9 Other observations
- `cors()` open to all origins; no rate limiting middleware; no request validation library.
- `backend/.agents`, `.claude/skills`, `.windsurf/skills`: vendored Prisma agent skills.

---

## 3. Customer app (`apps/customer_app/`)

**Stack:** Flutter (SDK ≥3.0, Flutter ≥3.16), flutter_riverpod 2.x, go_router 14, dio 5, flutter_secure_storage, shared_preferences, intl, equatable, uuid, google_fonts, flutter_svg, image_picker. Lints: flutter_lints 4.

**Not present:** payment SDK, FCM / firebase_messaging, location/geolocator, geocoding, maps packages.

### 3.1 Structure
`lib/app/` (config, router, theme incl. `app_responsive.dart`), `lib/core/` (constants, errors, network with `ApiClient` + `AuthInterceptor`, storage, providers, utils, validators, `startup_state_resolver`), `lib/shared/widgets/`, `lib/features/<feature>/{data,presentation}`.

Features: address, authentication, cart, checkout, explore, favorites, home, legal, notifications, onboarding, orders, payment, product, profile, profile_setup, search, splash, store.

No `domain/` layers exist, and none is planned (D-010). `ARCHITECTURE.md` and `AGENTS.md` describe this data + presentation structure.

### 3.2 Behavior
- Auth: phone + OTP screen with **4-digit** OTP (`verify_otp_screen.dart` `_otpLength = 4`). Tokens in secure storage; interceptor refreshes on 401 and retries.
- Startup: splash → onboarding → login → profile setup → first address → home, via `StartupStateResolver` and local flags.
- Store: serving store resolved from default address lat/lng via backend `stores/nearby`.
- Checkout: hard-codes `fulfillmentType: 'DELIVERY'`. Payment choices: "UPI" → sent as `ONLINE`, or COD. For ONLINE, no payment SDK is invoked; the app navigates directly to Order Success.
- Pickup: no pickup ordering UI; only order-status display for `READY_FOR_PICKUP` / `PICKED_UP`.
- Payment methods screen: saved methods stored locally in SharedPreferences (UI only).
- Help & Support text mentions UPI (GPay, PhonePe, Paytm, BHIM) and COD — static copy, not a decision.
- Currency: ₹ / INR / en_IN constants. Country code +91.
- Base URL: `--dart-define=API_BASE_URL`, else platform defaults (Android emulator `10.0.2.2:5001`, iOS `localhost:5001`).

### 3.3 Tests
49 test files in `test/` (widget, flow, interceptor, router, responsive/theme). Verified 2026-10-02 (P1-17): `flutter analyze` → no issues; `flutter test` → 584/584 pass.

### 3.4 Existing app docs (reference)
`AGENTS.md`, `ARCHITECTURE.md`, `ARCHITECTURE_MIGRATION_PLAN.md`, `DEVELOPMENT_GUIDELINES.md`, `MOBILE_TODO.md`, `README.md`. `AGENTS.md` defers to the root `CLAUDE.md` and allows required backend/admin changes (D-011).

---

## 4. Admin panel (`apps/admin/`)
React + TypeScript + Vite + Tailwind. Pages: Login, Dashboard, Stores, Managers, Products, Categories, Inventory, Orders/OrderDetails, PickupVerification, Payments, Customers, Banners, Pincodes, Settings, AuditLogs. `services/api.ts`, `context/AuthContext.tsx`, `PrivateRoute`. Not in scope of detailed audit.

---

## 5. Docs & reference material

| File | Nature |
|---|---|
| `reference/UNIQUE BASKET.pdf` | Client requirements + costing. Mentions MSG91 (OTP), Cashfree (payment, also lists Razorpay costing), Firebase FCM, Supabase storage, Render/Railway, Google/Apple Maps external navigation, subcategories, filters/sorting, delivery personnel, reports. **Reference only.** |
| `docs/implementation_plan.md` | Earlier architecture plan (Razorpay, Firebase, Google Maps, pickup flow). **Reference only; partially outdated.** |
| `docs/task.md` | Progress checklist; Stage 8/9 unchecked though admin and app exist — outdated. |
| `docs/MOBILE_*.md` | Mobile inspection/API map/architecture/TODO. Mentions Razorpay in pubspec and 6-digit OTP — does not match current code. |
| `backend/README.md` | Backend reference. |
| `design/customer_app/` | Splash spec. |

---

## 6. Known discrepancies (code vs code vs docs)

1. **OTP length:** app 4 digits; backend dev `1234`, prod 6 digits; docs say 6.
2. **Online payment:** backend creates Razorpay order; app never opens a checkout or calls `/payments/verify`; ONLINE orders stay `PENDING`.
3. **Payment provider:** backend Razorpay vs PDF Cashfree.
4. **Pickup:** supported in backend/admin, absent from customer app.
5. ~~Architecture docs describe `domain/` layers~~ — resolved: `ARCHITECTURE.md` updated to the current structure (D-010).
6. **Status docs** (`docs/task.md`, `MOBILE_TODO.md`) are stale.
7. **Security:** fallback JWT/Razorpay/webhook secrets; OTP logged in all environments; open CORS; in-memory OTP store.
