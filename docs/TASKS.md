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
- **Priority:** P1 · **Area:** Backend + Flutter / Address, Serviceability · **Status:** TODO
- **Problem:** The app never sends coordinates; the backend silently stores `22.3039, 70.8022` for every address. Nearest-store assignment, delivery-radius checks and `stores/nearby` all run on the same fake point.
- **Evidence:** `customerController.addAddress` defaults lat/lng; Flutter `add_new_address_screen.dart` / `first_time_add_address_screen.dart` call `addAddress` without lat/lng; `orderController.createOrder` uses address coordinates for Haversine.
- **Required fix:** Stop silently defaulting (store null / mark unverified) and make delivery assignment explicit about missing coordinates. How coordinates are captured depends on P4-04.
- **Files:** `backend/src/controllers/customerController.ts`, `orderController.ts`, Flutter `features/address/**`, `features/store/**`
- **Dependencies:** P4-04 (location provider), P4-05 (serviceability model). Partially BLOCKED until decided.
- **Verification:** Address without coordinates is not treated as Rajkot centre; tests cover delivery assignment with/without coordinates.

### P1-02 — Deleting an address erases the delivery address of past orders
- **Priority:** P1 · **Area:** Database / Orders · **Status:** TODO
- **Problem:** `orders.address_id` is `ON DELETE SET NULL`, and the API hard-deletes addresses, so active and historical delivery orders lose their address.
- **Evidence:** init migration `orders_address_id_fkey ... ON DELETE SET NULL`; `customerController.deleteAddress` uses `prisma.userAddress.delete`.
- **Required fix:** Snapshot the delivery address on the order (like `order_items` does for products) and/or soft-delete addresses. Requires a schema change → needs approval.
- **Files:** `backend/prisma/schema.prisma` (approval required), `customerController.ts`, `orderController.ts`, admin `OrderDetails.tsx`
- **Dependencies:** Owner approval for schema change.
- **Verification:** Delete an address used by an order → order still shows the full address in customer and admin views.

### P1-03 — Flutter truncates decimal quantities to integers
- **Priority:** P1 · **Area:** Flutter / Cart · **Status:** TODO
- **Problem:** The backend stores decimal quantities (Decimal(10,3), KG/GRAM units), but the app models cart quantities as `int` and calls `toInt()`, so 1.5 kg shows as 1 and the next change sends a wrong value.
- **Evidence:** `CartItemModel.quantity` is `int` (`qtyNum.toInt()`); `CartStateNotifier extends StateNotifier<Map<String,int>>`; `increment` uses `+1`; `CartRemoteDataSource.addItem/updateItem` take `int`.
- **Required fix:** Represent quantities as decimals end-to-end and format per unit. Step sizes are P4-08.
- **Files:** Flutter `features/cart/**`, `shared/widgets/product_quantity_control.dart`, `features/checkout/**`, `features/orders/**`
- **Dependencies:** P4-08 (quantity rules).
- **Verification:** A server cart with 1.5 renders as 1.5 and round-trips unchanged; unit tests for parsing/formatting.

### P1-04 — Cart/order accept invalid quantities
- **Priority:** P1 · **Area:** Backend / Cart, Orders · **Status:** TODO
- **Problem:** Any positive float is accepted for any unit (e.g. 2.37 PIECE, 0.0001 KG), with no upper bound; values beyond 3 decimals are silently rounded by the DB. No stock check when adding to cart.
- **Evidence:** `cartController.addItem/updateItem` and `orderController.createOrder` only check `> 0`.
- **Required fix:** Validate quantity per unit (integer for countable units, min/step/max for weight) and precision; optionally warn on stock at cart time.
- **Files:** `backend/src/controllers/cartController.ts`, `orderController.ts`
- **Dependencies:** P4-08 (rules).
- **Verification:** Tests reject fractional PIECE, excess precision, huge values.

### P1-05 — Cart totals inconsistent with checkout
- **Priority:** P1 · **Area:** Backend / Cart, Pricing · **Status:** TODO
- **Problem:** `GET /cart` uses a ₹30 fee when delivery is disabled (`deliveryEnabled ? fee : 30.00`), includes products whose category is inactive, and includes out-of-stock items, so the cart shows totals checkout will reject.
- **Evidence:** `cartController.getCart` (`configDeliveryFee` expression; filter only on `product.isActive`).
- **Required fix:** Share one fare calculation between cart and checkout; exclude/flag unavailable items consistently.
- **Files:** `backend/src/controllers/cartController.ts`, `orderController.ts`
- **Dependencies:** P2-02 (shared pricing service).
- **Verification:** Tests: delivery disabled → cart fee consistent with checkout; inactive-category item flagged.

### P1-06 — Flutter cart silently diverges from the server cart
- **Priority:** P1 · **Area:** Flutter / Cart, Checkout · **Status:** TODO
- **Problem:** Cart sync calls swallow all errors (`catch (_) {}`), and `getCartSummary` returns an empty cart on any error. Checkout builds the order from local state and shows unknown products as a ₹0 "Fresh Item" placeholder.
- **Evidence:** `cart_provider.dart` `_syncAddItem/_syncUpdateItem/_syncRemoveItem`; `cart_remote_data_source.dart` `getCartSummary` catch; `checkout_screen.dart` placeholder `ProductModel(name: 'Fresh Item', price: 0.0)`.
- **Required fix:** Surface sync failures, roll back optimistic updates, reconcile with the server before checkout, never show placeholder prices.
- **Files:** Flutter `features/cart/**`, `features/checkout/presentation/screens/checkout_screen.dart`
- **Dependencies:** P1-03.
- **Verification:** Widget tests with a failing repository show an error and keep state consistent; checkout never shows ₹0 placeholders.

### P1-07 — Flutter has no route guards or session-expiry handling
- **Priority:** P1 · **Area:** Flutter / Navigation, Auth · **Status:** TODO
- **Problem:** GoRouter has no `redirect`/`refreshListenable`. When token refresh fails the interceptor clears tokens but the user stays on protected screens with failing calls. Dev-only routes (`/dev/profile-setup`, `/dev/address-first-time-add`) ship in the production router.
- **Evidence:** `app/router/app_router.dart` (no redirect); `auth_interceptor.dart` `_performRefresh` clears storage only; `route_names.dart` dev routes. `AGENTS.md`/`MOBILE_TODO.md` claim auth-aware redirects exist.
- **Required fix:** Auth-aware redirect driven by auth state; emit a session-expired event from the interceptor; gate dev routes behind `kDebugMode`.
- **Files:** Flutter `app/router/**`, `core/network/auth_interceptor.dart`, `features/authentication/**`
- **Dependencies:** None.
- **Verification:** Tests: expired refresh → redirected to login; unauthenticated deep link to `/cart` → login; dev routes absent in release.

### P1-08 — Logout and refresh tokens are not enforced server-side
- **Priority:** P1 · **Area:** Backend + Flutter / Auth · **Status:** TODO
- **Problem:** Refresh tokens are stateless and can't be revoked (valid 7 days after logout or deactivation). Customer refresh doesn't check `isActive`. `/auth/logout` is unauthenticated and deletes any device token by value. The app's logout never calls the backend.
- **Evidence:** `authController.refresh` (customer branch has no `isActive` check), `authController.logout`; `authRoutes.ts` (`/logout` without `authenticate`); Flutter `AuthNotifier.logout` only clears local storage.
- **Required fix:** Persist/rotate refresh tokens (or a token version per user), revoke on logout/deactivation, authenticate logout, call it from the app. Needs schema approval if persisted.
- **Files:** `backend/src/controllers/authController.ts`, `routes/authRoutes.ts`, `utils/jwt.ts`, Flutter `auth_provider.dart`, `auth_remote_data_source.dart`
- **Dependencies:** Schema approval (if a token table is used).
- **Verification:** After logout or deactivation, refresh returns 401; tests cover rotation and revocation.

### P1-09 — Admin panel has no token refresh (forced logout every 15 minutes)
- **Priority:** P1 · **Area:** Admin / Auth · **Status:** TODO
- **Problem:** Access tokens last 15 minutes; the admin panel discards the refresh token and hard-redirects to `/login` on any 401, losing unsaved work.
- **Evidence:** `AuthContext.tsx` stores only `ub_admin_token`/`ub_admin_user`; `services/api.ts` 401 interceptor sets `window.location.href = '/login'`.
- **Required fix:** Store the refresh token appropriately and refresh single-flight on 401, then retry; only log out when refresh fails.
- **Files:** `apps/admin/src/services/api.ts`, `context/AuthContext.tsx`
- **Dependencies:** P1-08 (refresh semantics).
- **Verification:** With a 1-minute access TTL in dev, the session survives beyond expiry; failed refresh logs out cleanly.

### P1-10 — Store-manager isolation relies on a stale token claim
- **Priority:** P1 · **Area:** Backend / Authorization · **Status:** TODO
- **Problem:** The manager's `storeId` is read from the JWT (taken from `managers[0]`). After reassignment, the old store stays accessible until the token expires. The data model allows several stores per manager, but only the first is ever used.
- **Evidence:** `authController.adminLogin/refresh` `managers[0].storeId`; `authMiddleware.requireStoreAccess/restrictManagerAccess` compare against `req.user.storeId`; `StoreManager` has `@@unique([adminUserId, storeId])` (many-to-many).
- **Required fix:** Resolve the manager's store assignment from the DB in `authenticate` (it already loads `isActive`), and enforce one-store-per-manager or support many explicitly (DECISION REQUIRED if many).
- **Files:** `backend/src/middlewares/authMiddleware.ts`, `authController.ts`, admin controllers using `req.user.storeId`
- **Dependencies:** Owner confirmation on one vs many stores per manager.
- **Verification:** Test: reassign manager → next request to the old store returns 403.

### P1-11 — No rate limiting on auth endpoints
- **Priority:** P1 · **Area:** Backend / Security · **Status:** TODO
- **Problem:** `/admin/login` can be brute-forced. `/auth/send-otp` is limited only per phone, in memory, so rotating numbers is unlimited (SMS cost once a provider exists).
- **Evidence:** No rate-limit middleware in `app.ts`; `otpService` per-phone `Map` only.
- **Required fix:** IP + identity rate limiting on `send-otp`, `verify-otp`, `admin/login`, `refresh`; lockout/backoff for admin login.
- **Files:** `backend/src/app.ts`, `routes/authRoutes.ts`, `routes/adminRoutes.ts`
- **Dependencies:** New dependency approval; store choice ties to P4-02/P3 (multi-instance).
- **Verification:** Tests: exceeding limits returns 429.

### P1-12 — Validation and error mapping return 500s and leak internals
- **Priority:** P1 · **Area:** Backend / API · **Status:** TODO
- **Problem:** Business validation is thrown as plain `Error` inside transactions, and unknown messages fall through to the global handler → HTTP 500 with the message (outside production). Malformed UUIDs make Prisma throw → 500 instead of 400/404. There's no input schema validation.
- **Evidence:** `orderController.createOrder` throws `'Address ID is required...'`, `'Invalid fulfillment type.'`, `'Quantity must be a positive decimal.'`, `'CONCURRENCY_ERROR'` → `next(error)`; `productController.updateStoreInventory` `'Invalid adjustment type.'`; `app.ts` error handler.
- **Required fix:** Typed domain errors with status codes; validate request bodies/params (including UUID format) before DB access; map Prisma known errors (P2025, P2002, invalid UUID).
- **Files:** `backend/src/app.ts`, all controllers
- **Dependencies:** P2-01.
- **Verification:** Tests: invalid UUID → 400/404; missing addressId → 400; CONCURRENCY_ERROR → 409; no 500 for client errors.

### P1-13 — Phone numbers not normalized server-side
- **Priority:** P1 · **Area:** Backend / Auth · **Status:** TODO
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
- **Priority:** P1 · **Area:** Testing / Backend · **Status:** TODO
- **Problem:** No coverage for: refresh-token flow and logout (0 tests mention logout; refresh in 1 file), OTP production behavior (P0-01), concurrent checkout vs adjustment/cancel (only order-number concurrency is tested), fulfillment-aware transitions, pickup-verify status guard, quantity/unit validation, invalid UUID handling, manager reassignment isolation, address-deletion integrity.
- **Evidence:** `grep` over `backend/tests` (see audit summary).
- **Required fix:** Add tests alongside P0/P1 fixes.
- **Files:** `backend/tests/**`
- **Dependencies:** P1-14.
- **Verification:** New tests exist and fail before the corresponding fix.

### P1-16 — Tests that encode outdated or undecided behavior
- **Priority:** P1 · **Area:** Testing · **Status:** TODO
- **Problem:** Some tests lock in behavior that is undecided or wrong: `admin_order.test.ts:480` "cancel a paid online order without creating a refund workflow" (refund policy P4-09); Flutter `checkout_screen_test.dart` asserts `ONLINE` orders go straight to success with no payment step (P4-01); `verify_otp_test.dart` hard-codes a 4-digit `1234` (P4-02); webhook tests compute the signature over `JSON.stringify(body)`, matching the implementation, not the provider's raw-body contract (P4-01).
- **Evidence:** Files cited above.
- **Required fix:** Mark them as "current behavior" and update them when the related decision lands. Do not delete them.
- **Files:** `backend/tests/admin_order.test.ts`, `admin_payment.test.ts`, Flutter `test/checkout_screen_test.dart`, `test/verify_otp_test.dart`
- **Dependencies:** P4-01, P4-02, P4-09.
- **Verification:** Each such test carries a reference to its pending decision ID.

### P1-17 — Flutter analyze/test not verified
- **Priority:** P1 · **Area:** Testing / Flutter · **Status:** TODO
- **Problem:** The Flutter SDK was not available during the audit, so the 49 test files (~20k lines) and lint status are unverified.
- **Evidence:** `which flutter` → not found in the audit environment.
- **Required fix:** Run `flutter analyze` and `flutter test` locally/CI; record results in `CURRENT_STATE.md`; triage failures into this backlog.
- **Files:** `apps/customer_app/**`
- **Dependencies:** P3-01 (CI).
- **Verification:** Recorded results; 0 analyzer issues and all tests pass, or new tasks filed.

### P1-18 — Missing critical Flutter tests
- **Priority:** P1 · **Area:** Testing / Flutter · **Status:** TODO
- **Problem:** No tests for decimal quantity round-trip, cart sync failure/rollback, session-expiry redirect, or checkout reconciliation with the server cart.
- **Evidence:** No test references decimal cart quantities (`CartItemModel` is int-only); no router redirect exists to test.
- **Required fix:** Add tests with P1-03, P1-06, P1-07.
- **Files:** `apps/customer_app/test/**`
- **Dependencies:** P1-03, P1-06, P1-07.
- **Verification:** Tests present and green.

### P1-19 — Admin panel has no tests
- **Priority:** P1 · **Area:** Testing / Admin · **Status:** TODO
- **Problem:** There's no test runner or tests for the admin panel (auth guard, role routes, order workflow actions, inventory adjust).
- **Evidence:** `apps/admin/package.json` has no test script or test files.
- **Required fix:** Add a test setup and cover `PrivateRoute`, `orderWorkflow.ts`, api 401/refresh handling.
- **Files:** `apps/admin/**`
- **Dependencies:** New dev-dependency approval.
- **Verification:** `npm test` runs in CI.

---

## P2 — Architecture/maintainability

### P2-01 — Business logic in controllers; no request validation layer
- **Priority:** P2 · **Area:** Backend / Architecture · **Status:** TODO
- **Problem:** Orders, cart, inventory and pricing live in 300–800-line controllers with `any`-typed `whereClause`es and ad-hoc parsing.
- **Evidence:** `customerController.ts` 800 lines, `orderController.ts` 627, `productController.ts` 535.
- **Required fix:** Extract services (orders, inventory, pricing) and a validation layer; keep the HTTP contracts unchanged.
- **Files:** `backend/src/**`
- **Dependencies:** P0-03, P1-12.
- **Verification:** Existing tests stay green; controllers become thin.

### P2-02 — Duplicated pricing and stock-restore logic
- **Priority:** P2 · **Area:** Backend · **Status:** TODO
- **Problem:** Fare/COD defaults are duplicated in `cartController`, `orderController` and `adminSettingsController` (₹30/₹499/₹199/₹20/₹100/₹5000). Cancellation stock restore is duplicated in `orderController.cancelOrder` and `adminOrderController.updateOrderStatus`. The admin store controller delegates to the customer-facing `StoreController`.
- **Evidence:** Files cited.
- **Required fix:** Single pricing service and single inventory service.
- **Files:** `backend/src/controllers/*`
- **Dependencies:** P0-06, P1-05.
- **Verification:** One implementation per rule; tests unchanged.

### P2-03 — Money handled as JS floats
- **Priority:** P2 · **Area:** Backend / Data integrity · **Status:** TODO
- **Problem:** Prices/totals are converted to `Number`, computed with `parseFloat(toFixed(2))` and written back to Decimal columns; rounding can drift across many items.
- **Evidence:** `orderController.createOrder`, `cartController.getCart`.
- **Required fix:** Use Prisma `Decimal` (decimal.js) or integer paise for arithmetic.
- **Files:** `backend/src/controllers/orderController.ts`, `cartController.ts`
- **Dependencies:** P2-02.
- **Verification:** Property tests over random carts match exact decimal arithmetic.

### P2-04 — Dead code and duplicate route aliases
- **Priority:** P2 · **Area:** Backend + Flutter · **Status:** TODO
- **Problem:** `OrderController.cancelOrder` is not routed (dead; see P4-09). `app.ts` has an unused `connectDb` import. There are duplicate aliases: `PUT|PATCH /customer/profile`, `PUT|PATCH /customer/addresses/:id`, `POST /customer/favorites` and `/favorites/:productId`, `/customer/pincodes` and `/serviceability/pincodes`, `/admin/settings` and `/admin/settings/fare-cod`, `PATCH|PUT /admin/pincodes/:id/status`, `/stores` and `/stores/nearby`. Flutter `getFeaturedProducts` is unused, and the cart provider creates a fallback `ApiClient` without local storage.
- **Evidence:** Route files; `cart_provider.dart` `cartRemoteDataSourceProvider`.
- **Required fix:** Pick canonical routes (keep aliases the clients use), remove dead code, and stop creating fallback clients inside providers.
- **Files:** `backend/src/routes/*`, `backend/src/app.ts`, Flutter `features/cart/presentation/providers/cart_provider.dart`, `features/home/data/**`
- **Dependencies:** API contract check against both clients.
- **Verification:** Clients still work; no unused handlers.

### P2-05 — Flutter architecture docs don't match the code
- **Priority:** P2 · **Area:** Flutter / Docs · **Status:** TODO
- **Problem:** `ARCHITECTURE.md`/`AGENTS.md` require `domain/` layers, `route_guards.dart`, feature names (`categories`, `products`, `payments`) and auth redirects that don't exist; repositories return raw `Map<String,dynamic>` for addresses/orders.
- **Evidence:** No `domain/` directories; `customer_address_repository.dart` and order providers return maps.
- **Required fix:** Decide the target structure (P4-15 / pending P-022), then align docs or code; introduce typed models for orders/addresses.
- **Files:** `apps/customer_app/ARCHITECTURE.md`, `AGENTS.md`, `lib/features/**`
- **Dependencies:** Pending decision P-022.
- **Verification:** Docs describe the actual structure.

### P2-06 — Admin lint errors
- **Priority:** P2 · **Area:** Admin · **Status:** TODO
- **Problem:** `npm run lint` reports 87 errors and 10 warnings (`no-explicit-any`, unused vars, `react-hooks/set-state-in-effect`).
- **Evidence:** Lint output from the audit.
- **Required fix:** Fix lint and type the API responses (`types/index.ts`).
- **Files:** `apps/admin/src/**`
- **Dependencies:** None.
- **Verification:** `npm run lint` → 0 errors.

### P2-07 — Admin performance: unpaginated lists, single 572 kB bundle
- **Priority:** P2 · **Area:** Admin + Backend · **Status:** TODO
- **Problem:** The dashboard fetches all orders (`GET /admin/orders` with no page → backend returns everything). Product, customer and store lists are also unpaginated. There's no code splitting.
- **Evidence:** `Dashboard.tsx` `api.get('/admin/orders')`; `adminOrderController.getOrders` returns everything without `page`/`limit`; build warning.
- **Required fix:** Server-side aggregates for the dashboard, pagination everywhere, route-level lazy loading.
- **Files:** `apps/admin/src/pages/Dashboard.tsx`, backend admin controllers
- **Dependencies:** None.
- **Verification:** Dashboard request count/size bounded; bundle split.

### P2-08 — Stale project documentation
- **Priority:** P2 · **Area:** Docs · **Status:** TODO
- **Problem:** `backend/README.md` tells developers to use `prisma db push` (the cause of the earlier missing migration) and lists the unused `GOOGLE_MAPS_API_KEY`. `docs/task.md`, `docs/MOBILE_TODO.md`, `apps/customer_app/MOBILE_TODO.md` and `MOBILE_INTEGRATION_REPORT.md` describe Razorpay in pubspec, a 6-digit OTP and route guards, none of which match the code.
- **Evidence:** Files cited.
- **Required fix:** Update or mark them as historical; make `migrate dev`/`migrate deploy` the only documented path.
- **Files:** `backend/README.md`, `docs/*.md`, `apps/customer_app/*.md`
- **Dependencies:** None.
- **Verification:** No doc recommends `db push`; status docs match `CURRENT_STATE.md`.

---

## P3 — Production readiness

### P3-01 — No CI pipeline
- **Priority:** P3 · **Area:** CI/CD · **Status:** TODO
- **Problem:** Nothing runs build, lint or tests automatically; `develop`/`main` protection can't require checks.
- **Evidence:** No `.github/workflows` (or other CI config) in the repo.
- **Required fix:** CI jobs: backend tsc + tests against a PostgreSQL service + `prisma migrate diff` drift check; Flutter analyze/test; admin lint/build.
- **Files:** `.github/workflows/*` (new)
- **Dependencies:** P0-03, P1-14; CI provider is pending decision P-021.
- **Verification:** PRs show required green checks.

### P3-02 — No environment validation or `.env.example`
- **Priority:** P3 · **Area:** Config · **Status:** TODO
- **Problem:** There's no example env file for backend/admin/app, and no startup validation (except `DATABASE_URL`).
- **Evidence:** No `.env.example` files; README table only.
- **Required fix:** `.env.example` per app (names only) and a typed env loader (shared with P0-02).
- **Files:** `backend/`, `apps/admin/`
- **Dependencies:** P0-02.
- **Verification:** A fresh clone can configure from the examples; missing vars fail fast.

### P3-03 — HTTP hardening: open CORS, no security headers, no proxy config
- **Priority:** P3 · **Area:** Backend / Security · **Status:** TODO
- **Problem:** `cors()` allows every origin; no security headers; no `trust proxy` (needed for correct IPs behind a host, and for P1-11); default body limits; the global handler logs full errors.
- **Evidence:** `backend/src/app.ts`.
- **Required fix:** Restrict CORS to the admin origin(s), add security headers, configure proxy trust and body limits.
- **Files:** `backend/src/app.ts`
- **Dependencies:** Hosting decision P4-13; dependency approval.
- **Verification:** Requests from unknown origins are rejected; headers present.

### P3-04 — Logging and monitoring
- **Priority:** P3 · **Area:** Ops · **Status:** TODO
- **Problem:** Only `console.*` is used: no request logging, correlation IDs, structured logs or error tracking. Notification bodies and user IDs are logged. `/health` doesn't check the DB.
- **Evidence:** `notificationService.ts`, `app.ts`.
- **Required fix:** Structured logger with redaction, request logging, DB-aware health/readiness endpoint, error reporting.
- **Files:** `backend/src/**`
- **Dependencies:** P4-13 (hosting/monitoring choice).
- **Verification:** Logs are structured with no PII/secrets; health returns 503 when the DB is down.

### P3-05 — Runtime side effects and missing graceful shutdown
- **Priority:** P3 · **Area:** Backend / Ops · **Status:** TODO
- **Problem:** `connectDb()` inserts Rajkot pincodes on every boot when the table is empty (data seeding in the runtime path). `connectDb` also calls `process.exit(1)` from library code. There's no SIGTERM handling for the Prisma pool or the HTTP server.
- **Evidence:** `backend/src/config/db.ts`, `server.ts`.
- **Required fix:** Move reference-data seeding to migrations/seed (values depend on P4-05); add graceful shutdown.
- **Files:** `backend/src/config/db.ts`, `server.ts`
- **Dependencies:** P4-05.
- **Verification:** Boot doesn't write data; SIGTERM drains cleanly.

### P3-06 — Database migration, backup and recovery process undocumented
- **Priority:** P3 · **Area:** Database / Ops · **Status:** TODO
- **Problem:** There's no documented `migrate deploy` step for deployments, no drift check, and no backup/restore policy.
- **Evidence:** README describes `db push`; there's no deploy docs.
- **Required fix:** Document the deploy-time `prisma migrate deploy`, add the CI drift check (P3-01), and define backup/PITR and restore drills (provider per P4-13).
- **Files:** `docs/DEVELOPMENT.md` or a new ops doc
- **Dependencies:** P4-13.
- **Verification:** Documented and rehearsed restore.

### P3-07 — Android release configuration not production-ready
- **Priority:** P3 · **Area:** Flutter / Android · **Status:** TODO
- **Problem:** Release builds are signed with debug keys, and `usesCleartextTraffic="true"` is set in the main manifest (applies to release).
- **Evidence:** `android/app/build.gradle.kts` (`signingConfig = signingConfigs.getByName("debug")`, TODO comment); `android/app/src/main/AndroidManifest.xml`.
- **Required fix:** Release signing via `key.properties` (already git-ignored); move cleartext to debug/profile manifests only; review `applicationId`.
- **Files:** `apps/customer_app/android/**`
- **Dependencies:** Owner provides the keystore; applicationId confirmation.
- **Verification:** `flutter build appbundle --release` is signed with the release key; no cleartext in release.

### P3-08 — Flutter build always targets the development environment
- **Priority:** P3 · **Area:** Flutter / Config · **Status:** TODO
- **Problem:** `main.dart` hard-codes `Environment.development`, so release builds hit `10.0.2.2`/`localhost` unless `--dart-define=API_BASE_URL` is passed. A personal LAN IP (`192.168.31.243`) is committed. The prod URL `https://api.uniquebasket.com/api/v1` is unverified.
- **Evidence:** `lib/main.dart`, `lib/app/config/environment.dart`.
- **Required fix:** Select the environment via `--dart-define`/flavors, require an explicit base URL for release, and remove the personal IP.
- **Files:** `apps/customer_app/lib/main.dart`, `lib/app/config/*`
- **Dependencies:** P4-13 (production domain).
- **Verification:** A release build without a base URL fails or uses the confirmed production URL.

### P3-09 — iOS permissions for features that don't exist
- **Priority:** P3 · **Area:** Flutter / iOS · **Status:** TODO
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
- **Priority:** P4 · **Area:** Pricing · **Status:** DECISION REQUIRED
- **Problem:** Values are admin-configurable, with code defaults (₹30 / ₹499 / ₹199 / COD ₹20 / ₹100–₹5000) that nobody has confirmed (pending P-011).
- **Evidence:** `schema.prisma` `DeliverySettings` defaults; controller fallbacks.
- **Required fix:** Confirm defaults/rules.
- **Dependencies:** Owner decision. **Verification:** After the decision.

### P4-08 — Quantity rules per unit
- **Priority:** P4 · **Area:** Catalog / Cart · **Status:** DECISION REQUIRED
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
- **Problem:** Existing code or docs depend on these undecided items: delivery personnel/management (P-015; admin has none); saved payment methods stored only on device (P-019, `payment_methods_provider.dart`); the `apps/customer_app/AGENTS.md` "never edit outside customer_app" rule (P-020); CI provider (P-021); the Flutter `domain/` layer (P-022); one vs many stores per manager (P1-10); supported phone countries (P1-13).
- **Evidence:** `docs/DECISIONS.md` pending table; files cited.
- **Required fix:** Owner decisions.
- **Dependencies:** Owner. **Verification:** Recorded in `docs/DECISIONS.md`.

---

## Recommended fix order

1. **Security first:** P0-01, P0-02, P0-07, then decide the interim ONLINE payment policy (P4-01).
2. **Build and test baseline:** P0-03, P1-14 (green build, a reproducible test env), P1-17 (run Flutter tests), P3-01 (CI).
3. **Order and inventory integrity:** P0-06, P0-04, P0-05, P1-12, P1-15.
4. **Auth and session:** P1-08, P1-07, P1-09, P1-10, P1-11, P1-13.
5. **Cart and quantity correctness:** get the P4-08 decision, then P1-03, P1-04, P1-05, P1-06, P1-18.
6. **Address and data integrity:** P1-02, then P1-01 after P4-04/P4-05.
7. **Maintainability:** P2-01 … P2-08.
8. **Production readiness:** P3-02 … P3-09 as P4-13 is decided.
