# UNIQUE BASKET — Mobile Development TODO & Progress Tracker

> **HISTORICAL DOCUMENT — not maintained.** It may describe plans, providers or behaviour that do not match the current code (e.g. Razorpay in the app, 6-digit OTP, route guards).
> Current implementation: `docs/CURRENT_STATE.md` · Decisions: `docs/DECISIONS.md` · Backlog: `docs/TASKS.md`.

## Status Legend
- `[x]` **DONE**
- `[-]` **IN PROGRESS**
- `[ ]` **TODO**
- `[!]` **BLOCKED**

---

## 1. Phase A — Inspection & Architecture (COMPLETE)
- [x] Inspect existing backend routes, controllers, middleware, and services
- [x] Inspect Prisma database schema and data models
- [x] Inspect Admin Panel architecture, API structure, and RBAC rules
- [x] Map all usable customer REST endpoints
- [x] Create `MOBILE_INTEGRATION_REPORT.md`
- [x] Create `MOBILE_API_MAP.md`
- [x] Create `MOBILE_ARCHITECTURE.md`
- [x] Create `MOBILE_TODO.md`

---

## 2. Phase B — Flutter Foundation & Core (COMPLETE)
- [x] Initialize Flutter project in `customer_app/`
- [x] Configure `pubspec.yaml` (Dio, Riverpod, Flutter Secure Storage, GoRouter, Razorpay, Google Fonts, SharedPreferences)
- [x] Setup core environment configuration (`AppConfig`, `Env` with Dev/Prod/LAN/Emulator Base URLs)
- [x] Implement centralized Dio API client with `AuthInterceptor` (auto token injection & 401 refresh mechanism)
- [x] Implement `SecureStorageService` for JWT tokens & `LocalStorageService` for cached settings/favourites
- [x] Implement App Theme, Brand Colors (`#10B981`), Typography (`AppTextStyles`), and UI Tokens (`AppSpacing`)
- [x] Implement Reusable Atomic Widgets (`AppButton`, `AppTextField`, `AppPhoneField`, `AppPrice`, `AppQuantitySelector`, `AppLoading`, `AppEmptyState`, `AppErrorState`, `AppPrimaryCard`)
- [x] Implement Data Models (`UserModel`, `CategoryModel`, `ProductModel`, `StoreModel`, `CartModel`, `CartItemModel`, `OrderModel`, `OrderItemModel`, `PaymentModel`, `FareSettingsModel`, `BannerModel`, `AddressModel`)
- [x] Implement Remote Data Sources & Repositories (`AuthRepository`, `CategoryRepository`, `ProductRepository`, `StoreRepository`, `CartRepository`, `OrderRepository`, `PaymentRepository`)
- [x] Implement Auth State Management (`AuthState`, `AuthNotifier`, `authStateProvider` with session restoration)
- [x] Configure GoRouter with Auth-Aware Navigation & Protected Route Redirects (`RouteNames`, `app_router.dart`)
- [x] Create Unit Test Suite for Models, Error Mapping, AuthState, and Currency Formatting
- [x] Verify backend tests pass 100% (`14/14 test suites, 171/171 tests`)
- [x] Verify admin panel builds cleanly (`0 TypeScript errors`)

---

## 3. Phase C — Authentication Flow (COMPLETE)
- [x] Welcome / Onboarding Screen UI with UNIQUE BASKET branding & value proposition
- [x] Mobile Phone Number Entry with +91 indicator & strict 10-digit validation
- [x] OTP Verification Screen with interactive 6-digit PIN boxes, 30s Countdown Timer & Resend
- [x] Session Restoration & Auto-login on app launch via AuthNotifier and SecureStorage
- [x] Logout functionality & Secure Token cleanup (safe client cleanup on network failure)
- [x] Auth-aware GoRouter redirects (protected routes protected, auth routes redirect to home)
- [x] Unit & Flow Test Suite for Phone/OTP validation, AuthNotifier, and Routing rules

---

## 4. Phase D — Home & Dashboard (COMPLETE)
- [x] Home Screen Layout with App Bar, Store/Location selector & Header actions
- [x] Marketing Banners Carousel with auto-scroll, image caching & dot indicators
- [x] Category Horizontal Explorer with category pills and dynamic routing
- [x] Featured "Fresh Picks" & Store Popular Products horizontal rails
- [x] Pull-to-refresh data re-fetching & skeleton loading states
- [x] ProductCard with discount badges, favourites heart toggle, and live cart quantity selector
- [x] Live CartBottomPill floating basket summary for rapid checkout navigation
- [x] CustomerBottomNav bar across Home, Categories, Favourites, Orders, and Account

---

## 5. Phase E — Catalog, Categories & Search
- [x] **Phase E.1 — Categories Screen + Category Navigation (COMPLETE)**
  - [x] Full Categories browsing screen (`CategoriesScreen`) with responsive 2-column grid
  - [x] CategoryCard widget with image caching, fallback icon, and semantic labels
  - [x] Connected to existing `GET /api/v1/categories` via Riverpod `categoriesListProvider`
  - [x] Connected Home "View All" category action to Categories screen
  - [x] Tapping a category navigates to `/products?categoryId={id}&categoryName={name}`
  - [x] Pull-to-refresh, skeleton loading, empty state, and error state with retry
  - [x] Full test coverage with 9 unit/widget tests passing
- [x] **Phase E.2 — Category Products Screen with Store Inventory integration (COMPLETE)**
  - [x] Full category product listing screen (`ProductsScreen`) with responsive 2-column grid
  - [x] Dynamic store inventory integration watching `selectedStoreProvider`
  - [x] Automatic reaction to store switching, reloading products for the newly selected store
  - [x] Reuses existing `ProductCard` with stock availability status and Add to Cart quantity selector
  - [x] Cart integration with real-time `cartStateProvider` and floating `CartBottomPill`
  - [x] Favourites toggle integration with `favouritesProvider`
  - [x] Missing/invalid category ID validation and graceful empty/error state handling
  - [x] Full test suite in `category_products_test.dart` with 9 passing tests
- [ ] **Phase E.3 — Product Search with Debounce & Suggestions**
- [ ] **Phase E.4 — Product Detail Page (Images, Pricing, MRP, Unit/Weight, Stock Status)**
- [ ] **Phase E.5 — Local Favourites / Wishlist Screen**

---

## 6. Phase F — Server-Side Persistent Cart
- [ ] Cart Screen with Item Listing
- [ ] Server-side Quantity Increment / Decrement
- [ ] Item Removal with confirmation
- [ ] Live Subtotal Calculation display
- [ ] Empty Cart State with "Start Shopping" call to action

---

## 7. Phase G — Customer Addresses
- [ ] Customer Address List Screen
- [ ] Add New Address with Coordinates / Map selector
- [ ] Edit / Delete Address
- [ ] Select Active Delivery Address

---

## 8. Phase H — Checkout & Payment
- [ ] Checkout Summary Screen
- [ ] Fulfillment Selection (`DELIVERY` vs `PICKUP`)
- [ ] Dynamic Store Proximity & Delivery Radius verification
- [ ] Server Fares & COD calculation display (Delivery Fee, COD Charge, Free Threshold)
- [ ] Payment Method Selection (`COD` vs `ONLINE`)
- [ ] Razorpay Flutter SDK Integration for Online Payments
- [ ] Transactional Order Placement submission

---

## 9. Phase I — Orders & Tracking
- [ ] Order Success / Confirmation Screen with Order Number
- [ ] Customer Order History List
- [ ] Order Details Screen with Line Items, Totals, Store, and Payment Metadata
- [ ] Customer Order Progress Timeline / Stepper

---

## 10. Phase J — Customer Account & Profile
- [ ] Account Profile Screen
- [ ] Edit Customer Name & Email
- [ ] Saved Addresses shortcut
- [ ] Order History shortcut
- [ ] Wishlist shortcut
- [ ] Logout with confirmation

---

## 11. Phase K — Quality, Verification & Production Readiness
- [ ] Unit tests for API models & serialization
- [ ] Unit tests for Riverpod Cart & Auth notifiers
- [ ] Verify existing backend test suite (`cd backend && npm test`) continues passing 100%
- [ ] Verify Admin Panel build (`cd admin && npm run build`) continues passing 100%

---

## 12. Phase 2 (Deferred Scope — DO NOT IMPLEMENT NOW)
- [ ] Delivery personnel accounts & authentication
- [ ] Delivery driver assignment
- [ ] Driver order dashboard & route management
- [ ] Live driver GPS tracking
- [ ] Delivery person COD collection interface
