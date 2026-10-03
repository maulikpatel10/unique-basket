# UNIQUE BASKET — Master Task Backlog

**Source:** Fresh audit of `feature/customer-app` @ `eb215ab` (2026-10-02).
**Rules:** Every item is backed by current code evidence. Nothing here is a product decision. Items that need an owner decision are marked **DECISION REQUIRED** and grouped in P4 (cross-referenced from other tasks). Payment code must not change until P4-01 is decided (`docs/DECISIONS.md` D-002).

**Statuses:** TODO · IN PROGRESS · BLOCKED · DECISION REQUIRED · DONE

**Audit evidence summary**
- Backend `npx tsc --noEmit`: **72 errors** (71 in `src/`, 1 in `tests/`); `npm run build` exits 2.
- Backend tests (fresh PostgreSQL, all 13 migrations, seeded, `NODE_ENV=test`, no other env): **15 failed / 226 passed / 241** (3 suites). With `JWT_SECRET=secret`: **2 failed / 239 passed**.
- Prisma: `migrate deploy` on an empty DB + `migrate diff` against `schema.prisma` → no drift.
- Admin (`apps/admin`, run in a scratch copy): `npm run build` passes (572 kB single chunk); `npm run lint` → **97 problems (87 errors, 10 warnings)**.
- Flutter: SDK not available in the audit environment → `flutter analyze` / `flutter test` **not run** (see P1-17).

---

## Summary

| Priority | Count |
|---|---|
| P0 — Critical correctness/security | 7 |
| P1 — Core existing functionality | 19 |
| P2 — Architecture/maintainability | 8 |
| P3 — Production readiness | 9 |
| P4 — Decision-dependent | 15 |
| **Total** | **58** |

---

## P0 — Critical correctness/security

### P0-01 — OTP bypass and OTP leakage when `NODE_ENV` is unset
- **Priority:** P0 · **Area:** Backend / Auth · **Status:** DONE (bypass limited to explicit `development`/`test`; 4-digit random OTP otherwise per D-004; tests in `backend/tests/otp_bypass.test.ts`)
- **Problem:** If `NODE_ENV` is missing, every OTP is the static `1234` and the OTP is returned in the API response, so anyone can log in as any phone number. OTPs are also written to stdout in every environment.
- **Evidence:** `otpService.ts` `isDevOrTest = NODE_ENV==='development' || 'test' || !NODE_ENV` → `'1234'`; `authController.sendOtp` returns `otp` under the same condition; `console.log('[SMS-MOCK] OTP for ${phone} is: ...')` runs unconditionally. README marks `NODE_ENV` as optional.
- **Required fix:** Treat unknown/missing `NODE_ENV` as production (allow-list `development`/`test` explicitly). Never return or log the OTP outside dev/test. Fail startup in production when no real OTP delivery is configured (provider itself is P4-02).
- **Files:** `backend/src/services/otpService.ts`, `backend/src/controllers/authController.ts`
- **Dependencies:** None (provider choice is P4-02, not needed for this guard).
- **Verification:** Unit tests: with `NODE_ENV` unset and `=production`, `send-otp` response has no `otp`, generated OTP ≠ `1234`, no OTP in logs; dev/test behavior unchanged.

### P0-02 — Hard-coded fallback secrets allow forged tokens
- **Priority:** P0 · **Area:** Backend / Security · **Status:** DONE (JWT fallbacks removed; startup validation in `backend/src/config/validateEnv.ts`; test secrets via `backend/tests/setup/env.ts`; tests in `backend/tests/env_validation.test.ts`. Payment fallbacks remain under P4-01.)
- **Problem:** If env vars are missing, the server silently signs/verifies JWTs with public strings, so anyone can mint admin tokens.
- **Evidence:** `utils/jwt.ts`: `JWT_SECRET || 'fallback_access_secret'`, `JWT_REFRESH_SECRET || 'fallback_refresh_secret'`. (Payment fallbacks `mock_key_secret`, `mock_webhook_secret`, `mock_key_id` are tracked in P4-01 because payment code is frozen.)
- **Required fix:** Central env validation at startup; refuse to start (outside `test`) when `JWT_SECRET`/`JWT_REFRESH_SECRET`/`DATABASE_URL` are missing or weak. Remove fallbacks.
- **Files:** `backend/src/utils/jwt.ts`, `backend/src/server.ts`/`app.ts` (new env module)
- **Dependencies:** P1-14 (tests rely on fallbacks; provide a test env).
- **Verification:** Starting with missing secrets in non-test env exits non-zero with a clear message; tests pass with an explicit test env.

### P0-03 — Backend production build fails (72 TypeScript errors)
- **Priority:** P0 · **Area:** Backend / Build · **Status:** DONE (0 tsc errors; `getParam` helper in `backend/src/utils/request.ts`; firebase-admin v14 modular imports; `tsconfig.build.json` builds `src` only to `dist/server.js`; `npm start` verified)
- **Problem:** `npm run build` (tsc) exits 2, while `npm start` runs `dist/server.js`. A clean production build is not possible; type errors hide real bugs.
- **Evidence:** 45× `string | string[]` from Express 5 `req.params/query` typing (product, manager, payment, store, customer, cart, category, order, notification controllers); 3× `Property 'managers' does not exist`; `notificationService.ts` `admin.messaging` does not exist on `firebase-admin@14` types (so FCM sending is likely broken at runtime when configured); implicit `any`; `tests/customer_profile.test.ts(42)` type error. `tsconfig.json` also includes `tests/**` in the build.
- **Required fix:** Fix types (typed param/query parsing), use the correct firebase-admin messaging import, exclude tests from the build tsconfig (separate tsconfig for tests).
- **Files:** `backend/src/**`, `backend/tsconfig.json`, `backend/src/services/notificationService.ts`
- **Dependencies:** None.
- **Verification:** `npx tsc --noEmit` → 0 errors; `npm run build` exit 0; `dist/` contains no tests; `npm start` boots.

### P0-04 — Pickup verification hands over orders in any status
- **Priority:** P0 · **Area:** Backend / Orders · **Status:** DONE (handover only from `READY_FOR_PICKUP`, else 400 `ORDER_NOT_READY_FOR_PICKUP`; conditional update returns 409 `ORDER_STATUS_CONFLICT` on races; tests in `backend/tests/pickup_verify_status.test.ts`)
- **Problem:** `verifyPickup` marks any PICKUP order `PICKED_UP` + `PAID` regardless of its current status, including `CANCELLED` (stock already restored) or `PLACED`.
- **Evidence:** `adminOrderController.verifyPickup` filters only `orderNumber`, `user.phone`, `fulfillmentType: 'PICKUP'`; no `orderStatus` check before the update.
- **Required fix:** Allow handover only from an explicitly allowed status (currently `READY_FOR_PICKUP` in the transition table); reject terminal statuses; do the status check inside the transaction with a conditional update.
- **Files:** `backend/src/controllers/adminOrderController.ts`
- **Dependencies:** Pickup scope for the customer app is P4-03; this guard is needed regardless because the backend/admin already expose pickup.
- **Verification:** Tests: verifying a CANCELLED/PLACED/PICKED_UP pickup order returns 400 and changes nothing; READY_FOR_PICKUP succeeds.

### P0-05 — Order status machine ignores fulfillment type and corrupts payment status
- **Priority:** P0 · **Area:** Backend + Admin / Orders · **Status:** DONE (fulfillment-aware transitions; PICKED_UP only via pickup verification (D-006); unpaid ONLINE orders cancel-only (D-005); auto-PAID on DELIVERED only for COD; admin "Verify Pickup" + "Awaiting Payment"; tests in `backend/tests/order_status_rules.test.ts`. Full lifecycle still P4-12.)
- **Problem:** (a) Transitions don't depend on `fulfillmentType`: a PICKUP order can go `OUT_FOR_DELIVERY → DELIVERED`, a DELIVERY order can be `PICKED_UP`. (b) `PICKED_UP` via the generic status endpoint bypasses phone verification. (c) Moving to `DELIVERED`/`PICKED_UP` always sets `paymentStatus = PAID`, so an ONLINE order with `FAILED`/`PENDING` payment becomes PAID. (d) Unpaid ONLINE orders can be confirmed and advanced.
- **Evidence:** `adminOrderController.updateOrderStatus` `VALID_TRANSITIONS` (READY_FOR_PICKUP → OUT_FOR_DELIVERY | PICKED_UP); `paymentStatusUpdate = PAID` for DELIVERED/PICKED_UP; admin `utils/orderWorkflow.ts` offers "Mark Picked Up" through `PUT /admin/orders/:id/status`.
- **Required fix:** Fulfillment-aware transition table; only allow PAID-on-completion for COD; block advancing ONLINE orders that are not PAID; route pickup completion through verification only. Final lifecycle is P4-12 — implement the safety constraints now without inventing new statuses.
- **Files:** `backend/src/controllers/adminOrderController.ts`, `apps/admin/src/utils/orderWorkflow.ts`, `apps/admin/src/pages/Orders.tsx`, `OrderDetails.tsx`
- **Dependencies:** P4-12 (lifecycle), P4-01 (online payment).
- **Verification:** Tests for every invalid fulfillment/status combination (400), ONLINE FAILED order cannot become PAID via status change, PICKED_UP only via pickup-verify.

### P0-06 — Inventory lost updates and double restore on cancellation
- **Priority:** P0 · **Area:** Backend / Inventory · **Status:** DONE (`backend/src/services/inventoryService.ts`: conditional status claim before restore, atomic increment/upsert restore, row lock for manual adjustments; tests in `backend/tests/inventory_concurrency.test.ts`)
- **Problem:** Stock restore and manual adjustments are read-then-write with absolute values, so concurrent checkouts/adjustments are overwritten. Order status is read outside the transaction, so two concurrent cancellations restore stock twice. Restore throws if the inventory row is missing.
- **Evidence:** `adminOrderController.updateOrderStatus` (cancel branch) and `orderController.cancelOrder`: `findUnique` → `update({ stockQuantity: prev + qty })`; order fetched before `$transaction`; `productController.updateStoreInventory` computes `newStock` from a read inside a default READ COMMITTED transaction. (Checkout itself uses a CAS `updateMany` and is correct.)
- **Required fix:** Use atomic `increment`/`decrement` or CAS updates; re-read and conditionally update the order status inside the transaction (`updateMany where orderStatus = expected`) so only one cancellation wins; handle missing inventory rows.
- **Files:** `backend/src/controllers/adminOrderController.ts`, `orderController.ts`, `productController.ts`
- **Dependencies:** None.
- **Verification:** Concurrency tests: parallel cancel ×2 restores once; parallel adjust + checkout yields correct final stock and matching `inventory_transactions`.

### P0-07 — Seed script wipes data and creates known admin passwords
- **Priority:** P0 · **Area:** Backend / Security / Ops · **Status:** DONE (seed refuses to run unless `NODE_ENV` is `development`/`test`; admin passwords overridable via `SEED_SUPER_ADMIN_PASSWORD`/`SEED_MANAGER_PASSWORD`; tests in `backend/tests/seed_guard.test.ts`. Splitting reference-data seeding is left to P3-05.)
- **Problem:** `prisma db seed` deletes existing records and creates SUPER_ADMIN/manager accounts with hard-coded passwords. Nothing prevents running it against a non-dev database.
- **Evidence:** `prisma/seed.ts`: "Cleared existing records", `bcrypt.hash('SuperSecretPassword123')`, `'ManagerPassword123'`; `prisma.config.ts` wires it as the migrate seed.
- **Required fix:** Refuse to run when `NODE_ENV=production` (or without an explicit override flag); read initial admin credentials from env or generate and print once; separate destructive dev reset from safe reference-data seeding.
- **Files:** `backend/prisma/seed.ts`, `backend/prisma.config.ts`
- **Dependencies:** None.
- **Verification:** Running the seed with `NODE_ENV=production` exits without changes; dev seed still works for tests.

---

## P1 — Core existing functionality

### P1-01 — Addresses get a fake location (Rajkot centre) so store assignment is meaningless
- **Priority:** P1 · **Area:** Backend + Flutter / Address, Serviceability · **Status:** BLOCKED — DECISION REQUIRED (P4-04 location provider, P4-05 serviceability model). Removing the Rajkot default without a way to capture coordinates would block every delivery order from the current app, so this waits on how coordinates are obtained and which serviceability rule is authoritative.
- **Problem:** The app never sends coordinates; the backend silently stores `22.3039, 70.8022` for every address. Nearest-store assignment, delivery-radius checks and `stores/nearby` all run on the same fake point.
- **Evidence:** `customerController.addAddress` defaults lat/lng; Flutter `add_new_address_screen.dart` / `first_time_add_address_screen.dart` call `addAddress` without lat/lng; `orderController.createOrder` uses address coordinates for Haversine.
- **Required fix:** Stop silently defaulting (store null / mark unverified) and make delivery assignment explicit about missing coordinates. How coordinates are captured depends on P4-04.
- **Files:** `backend/src/controllers/customerController.ts`, `orderController.ts`, Flutter `features/address/**`, `features/store/**`
- **Dependencies:** P4-04 (location provider), P4-05 (serviceability model). Partially BLOCKED until decided.
- **Verification:** Address without coordinates is not treated as Rajkot centre; tests cover delivery assignment with/without coordinates.

### P1-02 — Deleting an address erases the delivery address of past orders
- **Priority:** P1 · **Area:** Database / Orders · **Status:** DONE (additive migration `20261002190000_add_order_delivery_address_snapshot` adds `orders.delivery_address_snapshot` and backfills it from existing addresses; checkout stores the snapshot for DELIVERY orders; customer/admin order details and admin payment details fall back to it when the address row is gone; tests in `backend/tests/order_address_snapshot.test.ts`)
- **Problem:** `orders.address_id` is `ON DELETE SET NULL`, and the API hard-deletes addresses, so active and historical delivery orders lose their address.
- **Evidence:** init migration `orders_address_id_fkey ... ON DELETE SET NULL`; `customerController.deleteAddress` uses `prisma.userAddress.delete`.
- **Required fix:** Snapshot the delivery address on the order (like `order_items` does for products) and/or soft-delete addresses. Requires a schema change → needs approval.
- **Files:** `backend/prisma/schema.prisma` (approval required), `customerController.ts`, `orderController.ts`, admin `OrderDetails.tsx`
- **Dependencies:** Owner approval for schema change.
- **Verification:** Delete an address used by an order → order still shows the full address in customer and admin views.

### P1-03 — Flutter truncates decimal quantities to integers
- **Priority:** P1 · **Area:** Flutter / Cart · **Status:** DONE (D-012: cart state, `CartItemModel`, cart repository/data source and checkout payload use `double` quantities end-to-end, with no `toInt()` truncation. `ProductQuantityControl` shows decimals such as 1.25. +/- follow each product's `QuantityRule` (min/max/step from the API), and the cart badge counts product lines. Tests: `test/product_quantity_rules_test.dart`, D-012 cases in `checkout_server_cart_reconciliation_test.dart` and `cart_screen_test.dart`.)
- **Problem:** The backend stores decimal quantities (Decimal(10,3), KG/GRAM units), but the app models cart quantities as `int` and calls `toInt()`, so 1.5 kg shows as 1 and the next change sends a wrong value.
- **Evidence:** `CartItemModel.quantity` is `int` (`qtyNum.toInt()`); `CartStateNotifier extends StateNotifier<Map<String,int>>`; `increment` uses `+1`; `CartRemoteDataSource.addItem/updateItem` take `int`.
- **Required fix:** Represent quantities as decimals end-to-end and format per unit. Step sizes are P4-08.
- **Files:** Flutter `features/cart/**`, `shared/widgets/product_quantity_control.dart`, `features/checkout/**`, `features/orders/**`
- **Dependencies:** P4-08 (quantity rules).
- **Verification:** A server cart with 1.5 renders as 1.5 and round-trips unchanged; unit tests for parsing/formatting.

### P1-04 — Cart/order accept invalid quantities
- **Priority:** P1 · **Area:** Backend / Cart, Orders · **Status:** DONE (D-007: PIECE quantities must be whole numbers; all units limited to 3 decimals and the DB maximum; enforced on cart add/update and checkout via `backend/src/utils/quantity.ts`; tests in `backend/tests/quantity_rules.test.ts`. Extended by D-012: product-level min/max/step and GRAM whole-number precision, see P4-08.)
- **Problem:** Any positive float is accepted for any unit (e.g. 2.37 PIECE, 0.0001 KG), with no upper bound; values beyond 3 decimals are silently rounded by the DB. No stock check when adding to cart.
- **Evidence:** `cartController.addItem/updateItem` and `orderController.createOrder` only check `> 0`.
- **Required fix:** Validate quantity per unit (integer for countable units, min/step/max for weight) and precision; optionally warn on stock at cart time.
- **Files:** `backend/src/controllers/cartController.ts`, `orderController.ts`
- **Dependencies:** P4-08 (rules).
- **Verification:** Tests reject fractional PIECE, excess precision, huge values.

### P1-05 — Cart totals inconsistent with checkout
- **Priority:** P1 · **Area:** Backend / Cart, Pricing · **Status:** DONE (cart and checkout share `backend/src/services/pricingService.ts`; delivery-disabled cart shows no fee + `deliveryEnabled`; inactive-category items excluded; tests in `backend/tests/cart_totals.test.ts`. Out-of-stock flagging needs a store context in the cart and is left for the cart/checkout reconciliation in P1-06.)
- **Problem:** `GET /cart` uses a ₹30 fee when delivery is disabled (`deliveryEnabled ? fee : 30.00`), includes products whose category is inactive, and includes out-of-stock items, so the cart shows totals checkout will reject.
- **Evidence:** `cartController.getCart` (`configDeliveryFee` expression; filter only on `product.isActive`).
- **Required fix:** Share one fare calculation between cart and checkout; exclude/flag unavailable items consistently.
- **Files:** `backend/src/controllers/cartController.ts`, `orderController.ts`
- **Dependencies:** P2-02 (shared pricing service).
- **Verification:** Tests: delivery disabled → cart fee consistent with checkout; inactive-category item flagged.

### P1-06 — Flutter cart silently diverges from the server cart
- **Priority:** P1 · **Area:** Flutter / Cart, Checkout · **Status:** DONE (failed cart writes set `cartSyncErrorProvider` (shown app-wide as a SnackBar) and reload the server cart, rolling back optimistic changes; `getCartSummary` rethrows instead of returning an empty cart; checkout resolves items from the store catalogue or the server cart, never a ₹0 "Fresh Item", and blocks ordering when an item is unresolved or no address exists; removed fake name/phone/address/UPI fallbacks and the client-only "Special Bag Discount" (D-007: backend-authoritative totals; offers are P4-11). Tests: `test/cart_sync_reconciliation_test.dart`, new checkout cases P1-06a/b; 598/598 Flutter tests.)
- **Problem:** Cart sync calls swallow all errors (`catch (_) {}`), and `getCartSummary` returns an empty cart on any error. Checkout builds the order from local state and shows unknown products as a ₹0 "Fresh Item" placeholder.
- **Evidence:** `cart_provider.dart` `_syncAddItem/_syncUpdateItem/_syncRemoveItem`; `cart_remote_data_source.dart` `getCartSummary` catch; `checkout_screen.dart` placeholder `ProductModel(name: 'Fresh Item', price: 0.0)`.
- **Required fix:** Surface sync failures, roll back optimistic updates, reconcile with the server before checkout, never show placeholder prices.
- **Files:** Flutter `features/cart/**`, `features/checkout/presentation/screens/checkout_screen.dart`
- **Dependencies:** P1-03.
- **Verification:** Widget tests with a failing repository show an error and keep state consistent; checkout never shows ₹0 placeholders.

### P1-07 — Flutter has no route guards or session-expiry handling
- **Priority:** P1 · **Area:** Flutter / Navigation, Auth · **Status:** DONE (GoRouter `redirect` sends protected routes to login without an access token; `SessionExpiryNotifier` is triggered by AuthInterceptor when the session is cleared and drives `refreshListenable`; dev routes only in debug builds; tests in `apps/customer_app/test/session_expiry_route_guard_test.dart`; flutter analyze clean, 591/591 tests)
- **Problem:** GoRouter has no `redirect`/`refreshListenable`. When token refresh fails the interceptor clears tokens but the user stays on protected screens with failing calls. Dev-only routes (`/dev/profile-setup`, `/dev/address-first-time-add`) ship in the production router.
- **Evidence:** `app/router/app_router.dart` (no redirect); `auth_interceptor.dart` `_performRefresh` clears storage only; `route_names.dart` dev routes. `AGENTS.md`/`MOBILE_TODO.md` claim auth-aware redirects exist.
- **Required fix:** Auth-aware redirect driven by auth state; emit a session-expired event from the interceptor; gate dev routes behind `kDebugMode`.
- **Files:** Flutter `app/router/**`, `core/network/auth_interceptor.dart`, `features/authentication/**`
- **Dependencies:** None.
- **Verification:** Tests: expired refresh → redirected to login; unauthenticated deep link to `/cart` → login; dev routes absent in release.

### P1-08 — Logout and refresh tokens are not enforced server-side
- **Priority:** P1 · **Area:** Backend + Flutter / Auth · **Status:** DONE (additive migration `20261002180000_add_refresh_tokens`; refresh tokens carry a session id (`jti`) and must match a live, unexpired, unrevoked `refresh_tokens` row; refresh rejects deactivated customers/admins and revokes their session; logout revokes the given session and only deletes device tokens owned by its user; Flutter logout revokes the session fire-and-forget. No rotation (client compatibility). Pre-existing refresh tokens become invalid once → users log in again. Tests: `backend/tests/session_revocation.test.ts`, `apps/customer_app/test/logout_session_revocation_test.dart`.)
- **Problem:** Refresh tokens are stateless and can't be revoked (valid 7 days after logout or deactivation). Customer refresh doesn't check `isActive`. `/auth/logout` is unauthenticated and deletes any device token by value. The app's logout never calls the backend.
- **Evidence:** `authController.refresh` (customer branch has no `isActive` check), `authController.logout`; `authRoutes.ts` (`/logout` without `authenticate`); Flutter `AuthNotifier.logout` only clears local storage.
- **Required fix:** Persist/rotate refresh tokens (or a token version per user), revoke on logout/deactivation, authenticate logout, call it from the app. Needs schema approval if persisted.
- **Files:** `backend/src/controllers/authController.ts`, `routes/authRoutes.ts`, `utils/jwt.ts`, Flutter `auth_provider.dart`, `auth_remote_data_source.dart`
- **Dependencies:** Schema approval (if a token table is used).
- **Verification:** After logout or deactivation, refresh returns 401; tests cover rotation and revocation.

### P1-09 — Admin panel has no token refresh (forced logout every 15 minutes)
- **Priority:** P1 · **Area:** Admin / Auth · **Status:** DONE (`apps/admin/src/services/api.ts`: single-flight refresh on 401 + one retry; session cleared and redirected only when refresh fails; logout revokes the backend session (P1-08); removed console logging of login tokens; tests in `apps/admin/src/services/api.test.ts`. Tokens remain in localStorage — moving to httpOnly cookies would need backend changes.)
- **Problem:** Access tokens last 15 minutes; the admin panel discards the refresh token and hard-redirects to `/login` on any 401, losing unsaved work.
- **Evidence:** `AuthContext.tsx` stores only `ub_admin_token`/`ub_admin_user`; `services/api.ts` 401 interceptor sets `window.location.href = '/login'`.
- **Required fix:** Store the refresh token appropriately and refresh single-flight on 401, then retry; only log out when refresh fails.
- **Files:** `apps/admin/src/services/api.ts`, `context/AuthContext.tsx`
- **Dependencies:** P1-08 (refresh semantics).
- **Verification:** With a 1-minute access TTL in dev, the session survives beyond expiry; failed refresh logs out cleanly.

### P1-10 — Store-manager isolation relies on a stale token claim
- **Priority:** P1 · **Area:** Backend / Authorization · **Status:** DONE (`authenticate` resolves role and store assignment from the DB on every admin request; managers without an assignment get 403 `NO_STORE_ASSIGNMENT`; first assignment by `assignedAt` used consistently; tests in `backend/tests/manager_store_resolution.test.ts`. One-vs-many stores per manager remains a pending decision.)
- **Problem:** The manager's `storeId` is read from the JWT (taken from `managers[0]`). After reassignment, the old store stays accessible until the token expires. The data model allows several stores per manager, but only the first is ever used.
- **Evidence:** `authController.adminLogin/refresh` `managers[0].storeId`; `authMiddleware.requireStoreAccess/restrictManagerAccess` compare against `req.user.storeId`; `StoreManager` has `@@unique([adminUserId, storeId])` (many-to-many).
- **Required fix:** Resolve the manager's store assignment from the DB in `authenticate` (it already loads `isActive`), and enforce one-store-per-manager or support many explicitly (DECISION REQUIRED if many).
- **Files:** `backend/src/middlewares/authMiddleware.ts`, `authController.ts`, admin controllers using `req.user.storeId`
- **Dependencies:** Owner confirmation on one vs many stores per manager.
- **Verification:** Test: reassign manager → next request to the old store returns 403.

### P1-11 — No rate limiting on auth endpoints
- **Priority:** P1 · **Area:** Backend / Security · **Status:** DONE (in-memory fixed-window limiter `backend/src/middlewares/rateLimit.ts`, no new dependency: send-otp 20/15min/IP, verify-otp 30/15min/IP, refresh 60/15min/IP, admin login 20/15min/IP + 10/15min/email → 429 `RATE_LIMITED` with `Retry-After`; tests in `backend/tests/rate_limit.test.ts`. Single-instance only; a shared store and `trust proxy` are needed behind a load balancer (P3-03).)
- **Problem:** `/admin/login` can be brute-forced. `/auth/send-otp` is limited only per phone, in memory, so rotating numbers is unlimited (SMS cost once a provider exists).
- **Evidence:** No rate-limit middleware in `app.ts`; `otpService` per-phone `Map` only.
- **Required fix:** IP + identity rate limiting on `send-otp`, `verify-otp`, `admin/login`, `refresh`; lockout/backoff for admin login.
- **Files:** `backend/src/app.ts`, `routes/authRoutes.ts`, `routes/adminRoutes.ts`
- **Dependencies:** New dependency approval; store choice ties to P4-02/P3 (multi-instance).
- **Verification:** Tests: exceeding limits returns 429.

### P1-12 — Validation and error mapping return 500s and leak internals
- **Priority:** P1 · **Area:** Backend / API · **Status:** DONE (`AppError` in `backend/src/utils/errors.ts`; central mapping in `backend/src/app.ts` for invalid JSON/UUID, Prisma P2025/P2002/P2003/validation errors; checkout + inventory validation errors are 4xx; tests in `backend/tests/error_handling.test.ts`. Full validation layer remains P2-01.)
- **Problem:** Business validation is thrown as plain `Error` inside transactions, and unknown messages fall through to the global handler → HTTP 500 with the message (outside production). Malformed UUIDs make Prisma throw → 500 instead of 400/404. There's no input schema validation.
- **Evidence:** `orderController.createOrder` throws `'Address ID is required...'`, `'Invalid fulfillment type.'`, `'Quantity must be a positive decimal.'`, `'CONCURRENCY_ERROR'` → `next(error)`; `productController.updateStoreInventory` `'Invalid adjustment type.'`; `app.ts` error handler.
- **Required fix:** Typed domain errors with status codes; validate request bodies/params (including UUID format) before DB access; map Prisma known errors (P2025, P2002, invalid UUID).
- **Files:** `backend/src/app.ts`, all controllers
- **Dependencies:** P2-01.
- **Verification:** Tests: invalid UUID → 400/404; missing addressId → 400; CONCURRENCY_ERROR → 409; no 500 for client errors.

### P1-13 — Phone numbers not normalized server-side
- **Priority:** P1 · **Area:** Backend / Auth · **Status:** DONE (D-008: India-only, stored as `+91XXXXXXXXXX`. `backend/src/utils/phone.ts` normalizes send-otp, verify-otp and pickup verification, and accepts 10-digit input. Non-Indian or invalid numbers return `INVALID_PHONE_FORMAT`. Migration `20261003120000_free_delivery_threshold_200_and_canonical_phones` normalizes legacy stored numbers where safe and never deletes rows. Tests: `backend/tests/phone_normalization.test.ts`, plus a 10-digit pickup-verify case in `admin_order.test.ts`.)
- **Problem:** `send-otp` accepts any E.164-ish string, with or without `+`. `9876543210` and `+919876543210` become two different users. Only the Flutter app normalizes to `+91`.
- **Evidence:** `authController.sendOtp` regex `^\+?[1-9]\d{1,14}$`; `User.phone` unique on the raw value; Flutter `auth_provider.dart` adds `+91`.
- **Required fix:** Normalize to one canonical format server-side for OTP, users and pickup verification. The allowed country set is a decision (default to what the app sends today only after confirmation).
- **Files:** `backend/src/controllers/authController.ts`, `adminOrderController.verifyPickup`
- **Dependencies:** Owner confirmation on supported countries.
- **Verification:** Both formats map to the same user; tests.

### P1-14 — Backend tests: 15 failing in a default environment
- **Priority:** P1 · **Area:** Testing / Backend · **Status:** DONE (289/289 on a fresh migrated+seeded DB, re-runnable without reseed; test-only payment secrets in `backend/tests/setup/env.ts`; test setup documented in `backend/README.md` → Testing)
- **Problem:** Tests depend on unstated env and on fallback secrets that differ between tests and app code.
- **Evidence:** No env: 15 failures (`admin_pincodes` 13 — tokens signed with `'secret'` while the app falls back to `'fallback_access_secret'`; `order` 1; `admin_order` 1). With `JWT_SECRET=secret`: 2 failures — `order.test.ts:225` expects `imageUrl` string but the seed leaves it null; `admin_order.test.ts:237` signs with `'rzp_test_key_secret_mock'` vs app fallback `'mock_key_secret'`. Tests share one DB and mutate state (re-runs drift).
- **Required fix:** Add a committed test env (e.g. `.env.test` with non-secret values) and a reset/isolation strategy; fix the outdated expectations (seed vs test). The Razorpay test secret is payment code/test → coordinate with P4-01.
- **Files:** `backend/tests/**`, `backend/jest.config.js`, `backend/prisma/seed.ts`
- **Dependencies:** P0-02.
- **Verification:** `npm test` green on a fresh DB with only the documented test env, twice in a row.

### P1-15 — Missing critical backend tests
- **Priority:** P1 · **Area:** Testing / Backend · **Status:** DONE (covered by tests added in P0-01…P1-11/P1-02: `otp_bypass`, `env_validation`, `session_revocation`, `inventory_concurrency`, `order_status_rules`, `pickup_verify_status`, `quantity_rules`, `error_handling`, `manager_store_resolution`, `order_address_snapshot`, `rate_limit`, `cart_totals`)
- **Problem:** No coverage for: refresh-token flow and logout (0 tests mention logout; refresh in 1 file), OTP production behavior (P0-01), concurrent checkout vs adjustment/cancel (only order-number concurrency is tested), fulfillment-aware transitions, pickup-verify status guard, quantity/unit validation, invalid UUID handling, manager reassignment isolation, address-deletion integrity.
- **Evidence:** `grep` over `backend/tests` (see audit summary).
- **Required fix:** Add tests alongside P0/P1 fixes.
- **Files:** `backend/tests/**`
- **Dependencies:** P1-14.
- **Verification:** New tests exist and fail before the corresponding fix.

### P1-16 — Tests that encode outdated or undecided behavior
- **Priority:** P1 · **Area:** Testing · **Status:** DONE (annotated as current behaviour with their pending decision IDs: `admin_order.test.ts` refund case → P4-09; `admin_payment.test.ts` webhook signing → P4-01; Flutter `checkout_screen_test.dart` ONLINE/UPI → P4-01/D-005. The 4-digit `1234` OTP in `verify_otp_test.dart` is now decided (D-004).)
- **Problem:** Some tests lock in behavior that is undecided or wrong: `admin_order.test.ts:480` "cancel a paid online order without creating a refund workflow" (refund policy P4-09); Flutter `checkout_screen_test.dart` asserts `ONLINE` orders go straight to success with no payment step (P4-01); `verify_otp_test.dart` hard-codes a 4-digit `1234` (P4-02); webhook tests compute the signature over `JSON.stringify(body)`, matching the implementation, not the provider's raw-body contract (P4-01).
- **Evidence:** Files cited above.
- **Required fix:** Mark them as "current behavior" and update them when the related decision lands. Do not delete them.
- **Files:** `backend/tests/admin_order.test.ts`, `admin_payment.test.ts`, Flutter `test/checkout_screen_test.dart`, `test/verify_otp_test.dart`
- **Dependencies:** P4-01, P4-02, P4-09.
- **Verification:** Each such test carries a reference to its pending decision ID.

### P1-17 — Flutter analyze/test not verified
- **Priority:** P1 · **Area:** Testing / Flutter · **Status:** DONE (Flutter 3.x stable installed in the cloud session: `flutter analyze` → No issues found (was 28: unused test imports/params + missing `assets/icons/` entry); `flutter test` → 584/584 pass)
- **Problem:** The Flutter SDK was not available during the audit, so the 49 test files (~20k lines) and lint status are unverified.
- **Evidence:** `which flutter` → not found in the audit environment.
- **Required fix:** Run `flutter analyze` and `flutter test` locally/CI; record results in `CURRENT_STATE.md`; triage failures into this backlog.
- **Files:** `apps/customer_app/**`
- **Dependencies:** P3-01 (CI).
- **Verification:** Recorded results; 0 analyzer issues and all tests pass, or new tasks filed.

### P1-18 — Missing critical Flutter tests
- **Priority:** P1 · **Area:** Testing / Flutter · **Status:** DONE (done: cart sync failure/rollback tests with P1-06; session-expiry redirect tests with P1-07; checkout reconciliation with the server cart — a rejected order now reloads the cart and bill from the server (`CheckoutScreen._reconcileWithServerCart`), returns to the cart if the server cart is empty, and never writes the stale local cart back; a successful order clears the local cart without server writes; tests in `test/checkout_server_cart_reconciliation_test.dart`. Decimal quantity round-trip tests added with P1-03/P4-08 (D-012): `test/product_quantity_rules_test.dart`.)
- **Problem:** No tests for decimal quantity round-trip, cart sync failure/rollback, session-expiry redirect, or checkout reconciliation with the server cart.
- **Evidence:** No test references decimal cart quantities (`CartItemModel` is int-only); no router redirect exists to test.
- **Required fix:** Add tests with P1-03, P1-06, P1-07.
- **Files:** `apps/customer_app/test/**`
- **Dependencies:** P1-03, P1-06, P1-07.
- **Verification:** Tests present and green.

### P1-19 — Admin panel has no tests
- **Priority:** P1 · **Area:** Testing / Admin · **Status:** DONE (Vitest 5 + jsdom dev dependencies, `npm test`; 12 tests: `orderWorkflow.test.ts`, `services/api.test.ts`, `components/PrivateRoute.test.tsx`)
- **Problem:** There's no test runner or tests for the admin panel (auth guard, role routes, order workflow actions, inventory adjust).
- **Evidence:** `apps/admin/package.json` has no test script or test files.
- **Required fix:** Add a test setup and cover `PrivateRoute`, `orderWorkflow.ts`, api 401/refresh handling.
- **Files:** `apps/admin/**`
- **Dependencies:** New dev-dependency approval.
- **Verification:** `npm test` runs in CI.

---

## P2 — Architecture/maintainability

### P2-01 — Business logic in controllers; no request validation layer
- **Priority:** P2 · **Area:** Backend / Architecture · **Status:** IN PROGRESS. The request validation layer is done (parts 1–2). Service extraction part 1 is done for orders, inventory and cart; more controllers can follow.
  - **Validator:** `backend/src/validation/validator.ts`, an in-house typed schema/parsers module with no new dependency (`zod` is still awaiting approval).
  - **Middleware:** `middlewares/validate.ts` (`validateBody`/`validatedBody`).
  - **Schemas:** `validation/schemas.ts`, covering auth send/verify OTP, customer profile, add/update address, cart add/update, order creation, and admin product create/update.
  - **Contracts:** existing errorCodes and messages are preserved, and the 430 existing tests pass unchanged.
  - **Bugs fixed along the way:**
    - `email: null` on a profile update caused a 500.
    - A non-numeric cart update quantity deleted the line; it now returns `INVALID_QUANTITY`.
    - Bad address coordinates were stored or caused a 500; they now return `INVALID_COORDINATES`.
    - A malformed order item reached Prisma; it now returns `MISSING_PARAMETERS`/`INVALID_QUANTITY`.
    - A non-numeric product price/mrp or a non-boolean `isActive` reached Prisma; it now returns `VALIDATION_ERROR`.
    - Null address title/city/state on update caused a 500; null values are now ignored.
  - **Tests:** `backend/tests/request_validation.test.ts`.
  - **Part 2 (admin endpoints, in-house validator kept):** `validateBody` schemas now cover admin login, order status, pickup verification, fare/COD settings, manager create/update, customer status, store create/update (`/admin/stores` and `/stores`), banners, supported pincodes (create/update/status), categories and store inventory. Cross-field rules (negative fees, COD range, quantity required with `adjustmentType`) stay in the controllers with their existing codes.
  - **Part 2 bug fixes:**
    - `"false"` strings were coerced to `true` for settings flags and `isActive`; they are now rejected.
    - A manager update accepted malformed emails; it now returns `INVALID_EMAIL`.
    - Store coordinates, radius, pincode and email were unchecked; they now return `INVALID_COORDINATES`/`INVALID_PINCODE`/`INVALID_EMAIL`/`VALIDATION_ERROR`.
    - A fractional or non-numeric banner/category `displayOrder` was silently truncated; it now returns `VALIDATION_ERROR`.
    - A null pincode city/state on update caused a 500; null values are now ignored.
  - **Part 2 tests:** `backend/tests/admin_request_validation.test.ts`.
  - **Not migrated:** payment endpoints (payment code is frozen until P-001), notification read/token endpoints, and refresh/logout (already explicit).
  - **Service extraction (part 1):**
    - `services/orderService.ts`: `resolveFulfillment` (address → nearest in-range store, or the pickup store), `findNearestDeliveryStore`, `reserveOrderLines` (product, category and D-012 quantity checks, stock deduction, paise pricing) and the pure `calculateOrderCharges` (delivery minimum/fee, COD rules/charge).
    - `services/inventoryService.ts`: `deductStockForOrder` (checkout CAS + ORDER_DEDUCTION log), the pure `computeStockAdjustment`, and `adjustStoreInventory` (lock, upsert, history, audit).
    - `services/cartService.ts`: `getCartSummary`.
    - **Controllers** now orchestrate request → service → response: `orderController` 615→429 lines, `cartController` 295→227, `productController` 597→509. The Razorpay block inside order creation is unchanged (payment code is frozen until P-001).
    - **Behaviour:** HTTP contracts and error codes are unchanged; all 449 existing tests pass. New unit tests in `backend/tests/order_services.test.ts` cover the pure rules without HTTP or a database.
  - **Service extraction (part 2, `customerController` 647→167 lines):**
    - `services/customerService.ts`: profile get/update.
    - `services/addressService.ts`: list/create/update/set-default/delete. The single-default invariant now runs in one transaction per flow; the Rajkot coordinate fallback is unchanged (P1-01).
    - `services/favoriteService.ts`: list/add/remove, idempotent.
    - `services/serviceabilityService.ts`: the active-pincode checks, shared by address create/update and the public endpoints (the serviceability model is still pending, P4-05).
    - `utils/request.ts`: `requireUserId` replaces the repeated 401 blocks (same `UNAUTHORIZED` response).
    - **Behaviour:** responses and error codes are unchanged; all 461 existing tests pass. New tests in `backend/tests/customer_services.test.ts`.
  - **Service extraction (part 3, `adminOrderController` 474→76 lines):**
    - `services/adminOrderService.ts`:
      - `assertStoreAccess`: the store-manager isolation rule.
      - `buildAdminOrderFilter` / `listAdminOrders`: a manager can never widen the list to another store.
      - `getAdminOrderDetails`.
      - The pure `assertStatusTransition`: the transition table, D-006 (PICKED_UP only via verification), the PICKUP fulfilment check and D-005 (unpaid ONLINE can only be cancelled).
      - `changeOrderStatus`: atomic claim, stock restore on cancel, audit log, customer notification.
      - `verifyPickupHandover`.
    - **Behaviour:** responses and error codes are unchanged; all 468 existing tests pass. New unit tests in `backend/tests/admin_order_service.test.ts`. The status lifecycle itself is still pending owner review (P-012).
    - **Remaining candidate:** manager CRUD (`adminManagerController`).
- **Problem:** Orders, cart, inventory and pricing live in 300–800-line controllers with `any`-typed `whereClause`es and ad-hoc parsing.
- **Evidence:** `customerController.ts` 800 lines, `orderController.ts` 627, `productController.ts` 535.
- **Required fix:** Extract services (orders, inventory, pricing) and a validation layer; keep the HTTP contracts unchanged.
- **Files:** `backend/src/**`
- **Dependencies:** P0-03, P1-12.
- **Verification:** Existing tests stay green; controllers become thin.

### P2-02 — Duplicated pricing and stock-restore logic
- **Priority:** P2 · **Area:** Backend · **Status:** DONE (fare/COD defaults live only in `backend/src/services/pricingService.ts`, used by cart, checkout, customer delivery-settings and admin fare/COD settings; stock restore lives in `backend/src/services/inventoryService.ts`; removed unrouted duplicate `AdminOrderController.get/updateDeliverySettings`. Admin store CRUD still delegates to `StoreController` (no duplication).)
- **Problem:** Fare/COD defaults are duplicated in `cartController`, `orderController` and `adminSettingsController` (₹30/₹200/₹199/₹20/₹100/₹5000, D-009). Cancellation stock restore is duplicated in `orderController.cancelOrder` and `adminOrderController.updateOrderStatus`. The admin store controller delegates to the customer-facing `StoreController`.
- **Evidence:** Files cited.
- **Required fix:** Single pricing service and single inventory service.
- **Files:** `backend/src/controllers/*`
- **Dependencies:** P0-06, P1-05.
- **Verification:** One implementation per rule; tests unchanged.

### P2-03 — Money handled as JS floats
- **Priority:** P2 · **Area:** Backend / Data integrity · **Status:** DONE (`backend/src/utils/money.ts`: integer-paise arithmetic with BigInt line totals and single half-up rounding; used for checkout and cart line totals, subtotals and grand totals; responses still plain rupee numbers; tests in `backend/tests/money.test.ts` incl. 200 random carts checked against Prisma.Decimal and the 0.5 × ₹2.01 case that float `toFixed` got wrong)
- **Problem:** Prices/totals are converted to `Number`, computed with `parseFloat(toFixed(2))` and written back to Decimal columns; rounding can drift across many items.
- **Evidence:** `orderController.createOrder`, `cartController.getCart`.
- **Required fix:** Use Prisma `Decimal` (decimal.js) or integer paise for arithmetic.
- **Files:** `backend/src/controllers/orderController.ts`, `cartController.ts`
- **Dependencies:** P2-02.
- **Verification:** Property tests over random carts match exact decimal arithmetic.

### P2-04 — Dead code and duplicate route aliases
- **Priority:** P2 · **Area:** Backend + Flutter · **Status:** DONE (removed unused aliases `PATCH /customer/profile`, `PATCH /customer/addresses/:id`, `GET /customer/serviceability/pincodes`, `PUT /admin/pincodes/:id/status` and the unused `connectDb` import in `app.ts`; kept aliases still used by tests (`/admin/settings`, `POST /customer/favorites`) and `/stores` (used by admin). Kept intentionally: `OrderController.cancelOrder` (future customer cancel, P4-09); Flutter `getFeaturedProducts` and the fallback `ApiClient` in cart/favorites providers (no runtime effect; referenced by test mocks).)
- **Problem:** `OrderController.cancelOrder` is not routed (dead; see P4-09). `app.ts` has an unused `connectDb` import. There are duplicate aliases: `PUT|PATCH /customer/profile`, `PUT|PATCH /customer/addresses/:id`, `POST /customer/favorites` and `/favorites/:productId`, `/customer/pincodes` and `/serviceability/pincodes`, `/admin/settings` and `/admin/settings/fare-cod`, `PATCH|PUT /admin/pincodes/:id/status`, `/stores` and `/stores/nearby`. Flutter `getFeaturedProducts` is unused, and the cart provider creates a fallback `ApiClient` without local storage.
- **Evidence:** Route files; `cart_provider.dart` `cartRemoteDataSourceProvider`.
- **Required fix:** Pick canonical routes (keep aliases the clients use), remove dead code, and stop creating fallback clients inside providers.
- **Files:** `backend/src/routes/*`, `backend/src/app.ts`, Flutter `features/cart/presentation/providers/cart_provider.dart`, `features/home/data/**`
- **Dependencies:** API contract check against both clients.
- **Verification:** Clients still work; no unused handlers.

### P2-05 — Flutter architecture docs don't match the code
- **Priority:** P2 · **Area:** Flutter / Docs · **Status:** DONE (D-010/D-011: `apps/customer_app/ARCHITECTURE.md` rewritten to the current data + presentation structure with no domain layer. `AGENTS.md` now defers to the root `CLAUDE.md` and allows required backend/admin changes. No Flutter code was refactored.)
- **Problem:** `ARCHITECTURE.md`/`AGENTS.md` require `domain/` layers, `route_guards.dart`, feature names (`categories`, `products`, `payments`) and auth redirects that don't exist; repositories return raw `Map<String,dynamic>` for addresses/orders.
- **Evidence:** No `domain/` directories; `customer_address_repository.dart` and order providers return maps.
- **Required fix:** Align the docs with the code (decided: D-010, no domain layer). Typed models for orders/addresses remain a separate improvement.
- **Files:** `apps/customer_app/ARCHITECTURE.md`, `AGENTS.md`, `lib/features/**`
- **Dependencies:** None (D-010).
- **Verification:** Docs describe the actual structure.

### P2-06 — Admin lint errors
- **Priority:** P2 · **Area:** Admin · **Status:** DONE (`npm run lint` → 0 errors, 23 warnings (was 87 errors): typed catch blocks via `src/utils/apiError.ts`, no `any`, `useAuth` moved to `context/authContextStore.ts`, sidebar no longer a component-in-render, derived Inventory validation, error `cause` preserved. `react-hooks/set-state-in-effect` is configured as a warning for the mount-effect data loading pattern (documented in `eslint.config.js`) pending a data-fetching layer (P2-07). Remaining warnings are `exhaustive-deps`/`set-state-in-effect`. Typed API response models are not yet introduced.)
- **Problem:** `npm run lint` reports 87 errors and 10 warnings (`no-explicit-any`, unused vars, `react-hooks/set-state-in-effect`).
- **Evidence:** Lint output from the audit.
- **Required fix:** Fix lint and type the API responses (`types/index.ts`).
- **Files:** `apps/admin/src/**`
- **Dependencies:** None.
- **Verification:** `npm run lint` → 0 errors.

### P2-07 — Admin performance: unpaginated lists, single 572 kB bundle
- **Priority:** P2 · **Area:** Admin + Backend · **Status:** DONE (`GET /admin/dashboard/summary` computes totals/pending/revenue/active stores/5 recent orders in the DB (store-isolated) and the dashboard uses it instead of downloading all orders; admin pages lazy-loaded (main chunk 572 kB → 303 kB); tests in `backend/tests/admin_dashboard.test.ts`. Products, categories, admin stores and managers now support opt-in `page`/`limit` (`src/utils/pagination.ts`, limit capped at 100, stable `id` tie-break ordering) and return `{<items>, pagination}`; without `page`/`limit` they still return a plain array, so the customer app and the store/category pickers are unchanged. The admin pages filter server-side (debounced search, status/category/city/store filters) with a shared `components/Pagination.tsx` footer; `/admin/stores` also returns the distinct `cities` for the city filter. Product search now matches description as well as name, matching the old client-side filter. Tests: `backend/tests/admin_list_pagination.test.ts`, `apps/admin/src/components/Pagination.test.tsx`. Orders, payments, customers, banners and audit logs already paginated.)
- **Problem:** The dashboard fetches all orders (`GET /admin/orders` with no page → backend returns everything). Product, customer and store lists are also unpaginated. There's no code splitting.
- **Evidence:** `Dashboard.tsx` `api.get('/admin/orders')`; `adminOrderController.getOrders` returns everything without `page`/`limit`; build warning.
- **Required fix:** Server-side aggregates for the dashboard, pagination everywhere, route-level lazy loading.
- **Files:** `apps/admin/src/pages/Dashboard.tsx`, backend admin controllers
- **Dependencies:** None.
- **Verification:** Dashboard request count/size bounded; bundle split.

### P2-08 — Stale project documentation
- **Priority:** P2 · **Area:** Docs · **Status:** DONE (`backend/README.md` uses `migrate deploy`/`migrate dev` only, documents NODE_ENV/secret rules, seed safety and rate limiting, drops the unused maps key; old status/plan docs carry a HISTORICAL banner; `docs/CURRENT_STATE.md` has a current section 0)
- **Problem:** `backend/README.md` tells developers to use `prisma db push` (the cause of the earlier missing migration) and lists the unused `GOOGLE_MAPS_API_KEY`. `docs/task.md`, `docs/MOBILE_TODO.md`, `apps/customer_app/MOBILE_TODO.md` and `MOBILE_INTEGRATION_REPORT.md` describe Razorpay in pubspec, a 6-digit OTP and route guards, none of which match the code.
- **Evidence:** Files cited.
- **Required fix:** Update or mark them as historical; make `migrate dev`/`migrate deploy` the only documented path.
- **Files:** `backend/README.md`, `docs/*.md`, `apps/customer_app/*.md`
- **Dependencies:** None.
- **Verification:** No doc recommends `db push`; status docs match `CURRENT_STATE.md`.

---

## P3 — Production readiness

### P3-01 — No CI pipeline
- **Priority:** P3 · **Area:** CI/CD · **Status:** DECISION REQUIRED (P-021: CI provider). Ready to implement once chosen: backend `tsc --noEmit`, `npm run build`, `npm test` against a PostgreSQL service + `prisma migrate deploy` + `prisma migrate diff --exit-code`; admin `npm test`, `npm run lint`, `npm run build`; Flutter `flutter analyze`, `flutter test`.)
- **Problem:** Nothing runs build, lint or tests automatically; `develop`/`main` protection can't require checks.
- **Evidence:** No `.github/workflows` (or other CI config) in the repo.
- **Required fix:** CI jobs: backend tsc + tests against a PostgreSQL service + `prisma migrate diff` drift check; Flutter analyze/test; admin lint/build.
- **Files:** `.github/workflows/*` (new)
- **Dependencies:** P0-03, P1-14; CI provider is pending decision P-021.
- **Verification:** PRs show required green checks.

### P3-02 — No environment validation or `.env.example`
- **Priority:** P3 · **Area:** Config · **Status:** DONE (`backend/.env.example` lists every variable the backend reads (placeholders only; undecided providers marked); `apps/admin/.env.example` has `VITE_API_URL`; startup validation of required secrets is in `backend/src/config/validateEnv.ts` (P0-02))
- **Problem:** There's no example env file for backend/admin/app, and no startup validation (except `DATABASE_URL`).
- **Evidence:** No `.env.example` files; README table only.
- **Required fix:** `.env.example` per app (names only) and a typed env loader (shared with P0-02).
- **Files:** `backend/`, `apps/admin/`
- **Dependencies:** P0-02.
- **Verification:** A fresh clone can configure from the examples; missing vars fail fast.

### P3-03 — HTTP hardening: open CORS, no security headers, no proxy config
- **Priority:** P3 · **Area:** Backend / Security · **Status:** DONE (`backend/src/config/http.ts`: `CORS_ORIGINS` allow-list (any origin only in development/test; none in production when unset; requests without Origin unaffected), security headers incl. HSTS in production, `X-Powered-By` off, `TRUST_PROXY`, `BODY_LIMIT` with 413 `PAYLOAD_TOO_LARGE`; startup warning when CORS_ORIGINS is missing in production; tests in `backend/tests/http_hardening.test.ts`. Actual origin/proxy values depend on hosting (P4-13).)
- **Problem:** `cors()` allows every origin; no security headers; no `trust proxy` (needed for correct IPs behind a host, and for P1-11); default body limits; the global handler logs full errors.
- **Evidence:** `backend/src/app.ts`.
- **Required fix:** Restrict CORS to the admin origin(s), add security headers, configure proxy trust and body limits.
- **Files:** `backend/src/app.ts`
- **Dependencies:** Hosting decision P4-13; dependency approval.
- **Verification:** Requests from unknown origins are rejected; headers present.

### P3-04 — Logging and monitoring
- **Priority:** P3 · **Area:** Ops · **Status:** IN PROGRESS (done: structured request log per request via `backend/src/utils/logger.ts` (method, path without query, status, duration, IP; no bodies), `/health` checks the DB and returns 503 when down, notification mock logs omit message content outside development/test; tests in `backend/tests/observability.test.ts`. Remaining: external error reporting/monitoring and log shipping depend on the hosting/monitoring decision (P4-13).)
- **Problem:** Only `console.*` is used: no request logging, correlation IDs, structured logs or error tracking. Notification bodies and user IDs are logged. `/health` doesn't check the DB.
- **Evidence:** `notificationService.ts`, `app.ts`.
- **Required fix:** Structured logger with redaction, request logging, DB-aware health/readiness endpoint, error reporting.
- **Files:** `backend/src/**`
- **Dependencies:** P4-13 (hosting/monitoring choice).
- **Verification:** Logs are structured with no PII/secrets; health returns 503 when the DB is down.

### P3-05 — Runtime side effects and missing graceful shutdown
- **Priority:** P3 · **Area:** Backend / Ops · **Status:** IN PROGRESS (done: graceful SIGTERM/SIGINT shutdown (stop accepting, drain, close Prisma + pg pool, forced exit after 10s); `connectDb` no longer calls `process.exit` (server.ts decides); verified against the built server. Remaining: the boot-time Rajkot pincode insert stays until the serviceability model is decided (P4-05), because removing it changes which pincodes a fresh production DB serves.)
- **Problem:** `connectDb()` inserts Rajkot pincodes on every boot when the table is empty (data seeding in the runtime path). `connectDb` also calls `process.exit(1)` from library code. There's no SIGTERM handling for the Prisma pool or the HTTP server.
- **Evidence:** `backend/src/config/db.ts`, `server.ts`.
- **Required fix:** Move reference-data seeding to migrations/seed (values depend on P4-05); add graceful shutdown.
- **Files:** `backend/src/config/db.ts`, `server.ts`
- **Dependencies:** P4-05.
- **Verification:** Boot doesn't write data; SIGTERM drains cleanly.

### P3-06 — Database migration, backup and recovery process undocumented
- **Priority:** P3 · **Area:** Database / Ops · **Status:** IN PROGRESS (migration create/deploy/drift-check/`migrate resolve` process documented in `docs/DEVELOPMENT.md` §7; backup/PITR policy and restore drill depend on the database host (P4-13); CI drift check waits on P3-01)
- **Problem:** There's no documented `migrate deploy` step for deployments, no drift check, and no backup/restore policy.
- **Evidence:** README describes `db push`; there's no deploy docs.
- **Required fix:** Document the deploy-time `prisma migrate deploy`, add the CI drift check (P3-01), and define backup/PITR and restore drills (provider per P4-13).
- **Files:** `docs/DEVELOPMENT.md` or a new ops doc
- **Dependencies:** P4-13.
- **Verification:** Documented and rehearsed restore.

### P3-07 — Android release configuration not production-ready
- **Priority:** P3 · **Area:** Flutter / Android · **Status:** BLOCKED (verification + owner input). Android SDK downloads (dl.google.com) are blocked in this cloud environment, so release builds cannot be verified here. Needed: (1) owner-provided upload keystore and `android/key.properties` (already git-ignored); (2) then: read `key.properties` in `build.gradle.kts` for the release `signingConfig`, move `android:usesCleartextTraffic="true"` from `src/main/AndroidManifest.xml` to `src/debug` and `src/profile` manifests, confirm `applicationId`; (3) verify with `flutter build appbundle --release` and `apksigner verify`.
- **Problem:** Release builds are signed with debug keys, and `usesCleartextTraffic="true"` is set in the main manifest (applies to release).
- **Evidence:** `android/app/build.gradle.kts` (`signingConfig = signingConfigs.getByName("debug")`, TODO comment); `android/app/src/main/AndroidManifest.xml`.
- **Required fix:** Release signing via `key.properties` (already git-ignored); move cleartext to debug/profile manifests only; review `applicationId`.
- **Files:** `apps/customer_app/android/**`
- **Dependencies:** Owner provides the keystore; applicationId confirmation.
- **Verification:** `flutter build appbundle --release` is signed with the release key; no cleartext in release.

### P3-08 — Flutter build always targets the development environment
- **Priority:** P3 · **Area:** Flutter / Config · **Status:** DONE (environment from `--dart-define=APP_ENV` with release builds defaulting to production; staging/production require `--dart-define=API_BASE_URL` and fail fast otherwise; removed the committed LAN IP and the unconfirmed production URL; README build commands updated; tests in `apps/customer_app/test/app_environment_test.dart`; 603/603 Flutter tests. The real production URL depends on P4-13.)
- **Problem:** `main.dart` hard-codes `Environment.development`, so release builds hit `10.0.2.2`/`localhost` unless `--dart-define=API_BASE_URL` is passed. A personal LAN IP (`192.168.31.243`) is committed. The prod URL `https://api.uniquebasket.com/api/v1` is unverified.
- **Evidence:** `lib/main.dart`, `lib/app/config/environment.dart`.
- **Required fix:** Select the environment via `--dart-define`/flavors, require an explicit base URL for release, and remove the personal IP.
- **Files:** `apps/customer_app/lib/main.dart`, `lib/app/config/*`
- **Dependencies:** P4-13 (production domain).
- **Verification:** A release build without a base URL fails or uses the confirmed production URL.

### P3-09 — iOS permissions for features that don't exist
- **Priority:** P3 · **Area:** Flutter / iOS · **Status:** DONE (removed unused `NSMicrophoneUsageDescription` and `NSLocationWhenInUseUsageDescription`; camera and photo-library descriptions kept for profile photos. Plist validated with a parser; an iOS build was not possible in this environment. Re-add location when P4-04 is decided.)
- **Problem:** `Info.plist` declares location and microphone usage although the app has no location or microphone feature. This is an App Store review risk and depends on P4-04.
- **Evidence:** `ios/Runner/Info.plist` `NSLocationWhenInUseUsageDescription`, `NSMicrophoneUsageDescription`; no location packages in `pubspec.yaml`.
- **Required fix:** Keep only the permissions that are actually used; revisit after P4-04.
- **Files:** `apps/customer_app/ios/Runner/Info.plist`
- **Dependencies:** P4-04.
- **Verification:** Every declared permission maps to a used API.

---

## P4 — Decision-dependent items

### P4-01 — Payment provider and online payment flow
- **Priority:** P4 · **Area:** Payments (backend, app, admin) · **Status:** DECISION REQUIRED
- **Problem:** No provider has been chosen (D-002). The existing Razorpay-specific code has security/correctness defects that must be fixed if it's kept, or removed/disabled if not:
  1. Fallback secrets `mock_key_secret`, `mock_webhook_secret`, `mock_key_id` → forgeable verification/webhooks if env is missing.
  2. `POST /payments/verify` doesn't check that the payment belongs to the caller, doesn't check the order's state/amount, and sets `CONFIRMED` even on a `CANCELLED` order.
  3. Webhook HMAC is computed over `JSON.stringify(req.body)` instead of the raw body; `timingSafeEqual` throws on a length mismatch → 500.
  4. Unpaid ONLINE orders hold deducted stock indefinitely (no expiry/release).
  5. App: "UPI" sends `ONLINE` and goes to the success screen with no payment; the order stays `PENDING`.
  6. Schema `Payment` has `razorpay_*` columns; `Payment.status` is a free string.
- **Evidence:** `config/razorpay.ts`, `controllers/paymentController.ts`, `orderController.ts`, `prisma/schema.prisma`, Flutter `checkout_screen.dart`.
- **Required fix:** Owner decides the provider (Razorpay / Cashfree / other) and an interim policy (e.g. disable ONLINE until integrated). Then implement and fix items 1–6.
- **Files:** As above.
- **Dependencies:** Owner decision. **Security-critical if ONLINE stays enabled.**
- **Verification:** Defined after the decision; must include signature/ownership/state tests.

### P4-02 — OTP/SMS provider and OTP storage
- **Priority:** P4 · **Area:** Auth · **Status:** DECISION REQUIRED
- **Problem:** There's no SMS provider (mock only). OTP length is decided: 4 digits everywhere (D-004, implemented with P0-01). The OTP store is an in-memory `Map` (lost on restart, not multi-instance).
- **Evidence:** `otpService.ts`; Flutter `verify_otp_screen.dart` `_otpLength = 4`.
- **Required fix:** Decide provider and storage, then implement (hashed OTP, persistent/shared store).
- **Files:** `backend/src/services/otpService.ts`, Flutter `features/authentication/**`
- **Dependencies:** Owner decision. P0-01 can be done first.
- **Verification:** Defined after the decision.

### P4-03 — Pickup scope in the customer app
- **Priority:** P4 · **Area:** Orders · **Status:** DECISION REQUIRED
- **Problem:** The backend and admin support PICKUP (orders, pickup-verify, COD-at-pickup setting), while the app hard-codes `fulfillmentType: 'DELIVERY'`.
- **Evidence:** `checkout_screen.dart`; `orderController.createOrder`; admin `PickupVerification.tsx`.
- **Required fix:** Decide whether pickup is in scope for the app.
- **Files:** As above. **Dependencies:** Owner decision. **Verification:** After the decision.

### P4-04 — Location and maps provider
- **Priority:** P4 · **Area:** Address / Store selection · **Status:** DECISION REQUIRED
- **Problem:** There's no geolocation/geocoding, so coordinates are never captured (see P1-01).
- **Evidence:** `pubspec.yaml` has no location packages.
- **Required fix:** Decide the provider and approach (GPS, geocoding, map pin, or none).
- **Dependencies:** Owner decision. Blocks P1-01 and P3-09. **Verification:** After the decision.

### P4-05 — Serviceability model
- **Priority:** P4 · **Area:** Delivery · **Status:** DECISION REQUIRED
- **Problem:** Two independent mechanisms exist: a pincode whitelist (checked at address creation, Rajkot defaults seeded at boot) and a store radius (checked at checkout).
- **Evidence:** `customerController.addAddress`, `orderController.createOrder`, `config/db.ts`.
- **Required fix:** Decide which is authoritative and how they combine.
- **Dependencies:** Owner decision; affects P1-01 and P3-05. **Verification:** After the decision.

### P4-06 — Notification provider and client integration
- **Priority:** P4 · **Area:** Notifications · **Status:** DECISION REQUIRED
- **Problem:** The backend uses firebase-admin (falls back to a console mock; `admin.messaging` is a type error under v14, see P0-03). The app has no push SDK and never registers device tokens (`POST /notifications/tokens` is unused). Notification texts send raw enum values ("updated to: OUT_FOR_DELIVERY").
- **Evidence:** `notificationService.ts`, `notificationController.registerToken`, Flutter `pubspec.yaml`.
- **Required fix:** Decide the provider and which events notify whom; then implement client registration.
- **Dependencies:** Owner decision. **Verification:** After the decision.

### P4-07 — Delivery fee, minimum order and COD values
- **Priority:** P4 · **Area:** Pricing · **Status:** DONE (D-009: fee ₹30, free delivery ≥ ₹200, minimum order ₹199, COD charge ₹20, COD ₹100–₹5000. Applied to the schema default + migration, seed, `pricingService` defaults, the admin settings form and customer-app fallbacks (`DeliverySettingsModel` constants). Tests: `backend/tests/fare_defaults.test.ts`, updated `admin_fares_cod_settings`/`cart_totals`, and `apps/customer_app/test/delivery_settings_defaults_test.dart`.)
- **Problem:** Values are admin-configurable, with code defaults that had not been confirmed (formerly pending P-011; old free-delivery default ₹499).
- **Evidence:** `schema.prisma` `DeliverySettings` defaults; controller fallbacks.
- **Required fix:** Confirm defaults/rules.
- **Dependencies:** Owner decision. **Verification:** After the decision.

### P4-08 — Quantity rules per unit
- **Priority:** P4 · **Area:** Catalog / Cart · **Status:** DONE (D-012: product-level, admin-configurable min/max/step; the unit sets precision. Implemented end to end:
  - **Backend:** schema, migration, validation of product config and of cart/order quantities.
  - **Admin:** product form fields with validation, plus a rule summary in the product list.
  - **Customer app:** reads the rules for +/-, cart/checkout validation and the limits shown on product details.
  - **Tests:** `backend/tests/product_quantity_rules.test.ts`, `apps/admin/src/utils/quantityRules.test.ts`, Flutter tests listed under P1-03.
  - **Follow-ups confirmed:** PACK/DOZEN whole numbers only; quantity rules remain optional per product.)
- **Problem:** Step size, minimum, maximum and integer-vs-decimal rules per unit (KG, GRAM, PIECE, PACK, DOZEN) are undefined, and the app and backend disagree (P1-03, P1-04).
- **Evidence:** `ProductUnit` enum; cart code.
- **Required fix:** Decide the rules.
- **Dependencies:** Owner decision. Blocks the final shape of P1-03/P1-04. **Verification:** After the decision.

### P4-09 — Cancellation and refund policy
- **Priority:** P4 · **Area:** Orders / Payments · **Status:** DECISION REQUIRED
- **Problem:** Customers can't cancel (the handler exists but isn't routed). Admins can cancel paid online orders with no refund handling.
- **Evidence:** `orderController.cancelOrder` (unrouted); `admin_order.test.ts:480`.
- **Required fix:** Decide who can cancel and when, and the refund process.
- **Dependencies:** Owner decision; P4-01. **Verification:** After the decision.

### P4-10 — Store operating hours enforcement
- **Priority:** P4 · **Area:** Stores / Orders · **Status:** DECISION REQUIRED
- **Problem:** `openingTime`/`closingTime` are stored but never enforced at checkout or for pickup.
- **Evidence:** No usage outside the store CRUD controllers.
- **Required fix:** Decide whether orders outside hours are blocked, scheduled or allowed.
- **Dependencies:** Owner decision. **Verification:** After the decision.

### P4-11 — Coupons/offers
- **Priority:** P4 · **Area:** Pricing · **Status:** DECISION REQUIRED
- **Problem:** `Order.discount` always stays 0; notifications have a `promoCode` field; there's no coupon model or API. The app shows a `discount` variable in checkout.
- **Evidence:** `schema.prisma`, `checkout_screen.dart`.
- **Required fix:** Decide whether offers are in scope.
- **Dependencies:** Owner decision. **Verification:** After the decision.

### P4-12 — Order status lifecycle
- **Priority:** P4 · **Area:** Orders · **Status:** DECISION REQUIRED
- **Problem:** The 8-status lifecycle and its transitions are implementation-defined (pending P-012). P0-05 adds only safety constraints.
- **Evidence:** `adminOrderController.updateOrderStatus`.
- **Required fix:** Confirm the lifecycle per fulfillment type.
- **Dependencies:** Owner decision. **Verification:** After the decision.

### P4-13 — Hosting, deployment, domain and monitoring
- **Priority:** P4 · **Area:** Infrastructure · **Status:** DECISION REQUIRED
- **Problem:** There's no deployment config (no Dockerfile/Procfile/hosting manifests), no production domain is confirmed, and no backup or monitoring provider is chosen.
- **Evidence:** Repo contents.
- **Required fix:** Decide the host, DB provider, domain and monitoring.
- **Dependencies:** Owner decision. Blocks P3-03, P3-04, P3-06, P3-08. **Verification:** After the decision.

### P4-14 — Image/file storage
- **Priority:** P4 · **Area:** Catalog / Profile · **Status:** DECISION REQUIRED
- **Problem:** Products, categories and banners store URLs only; the app includes `image_picker` for profile photos, but there's no upload API or storage.
- **Evidence:** `schema.prisma` `imageUrl` fields; `edit_profile_screen.dart`, `profile_setup_screen.dart` use `ImagePicker`.
- **Required fix:** Decide the storage provider and the upload flow (or remove the photo picking).
- **Dependencies:** Owner decision. **Verification:** After the decision.

### P4-15 — Remaining pending decisions affecting existing code
- **Priority:** P4 · **Area:** Various · **Status:** DECISION REQUIRED
- **Problem:** Existing code or docs depend on these undecided items: delivery personnel/management (P-015; admin has none); saved payment methods stored only on device (P-019, `payment_methods_provider.dart`); CI provider (P-021); one vs many stores per manager (P1-10). (Resolved 2026-10-03: AGENTS.md rule → D-011, `domain/` layer → D-010, phone countries → D-008.)
- **Evidence:** `docs/DECISIONS.md` pending table; files cited.
- **Required fix:** Owner decisions.
- **Dependencies:** Owner. **Verification:** Recorded in `docs/DECISIONS.md`.

---

## Recommended fix order

1. **Security first:** P0-01, P0-02, P0-07, then decide the interim ONLINE payment policy (P4-01).
2. **Build and test baseline:** P0-03, P1-14 (green build, a reproducible test env), P1-17 (run Flutter tests), P3-01 (CI).
3. **Order and inventory integrity:** P0-06, P0-04, P0-05, P1-12, P1-15.
4. **Auth and session:** P1-08, P1-07, P1-09, P1-10, P1-11, P1-13.
5. **Cart and quantity correctness:** P4-08 decided (D-012) and done; P1-03, P1-04, P1-05, P1-06, P1-18.
6. **Address and data integrity:** P1-02, then P1-01 after P4-04/P4-05.
7. **Maintainability:** P2-01 … P2-08.
8. **Production readiness:** P3-02 … P3-09 as P4-13 is decided.
