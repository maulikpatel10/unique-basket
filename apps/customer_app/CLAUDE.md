# Customer App (Flutter) — Claude Code Conventions

Read root `/CLAUDE.md` and `docs/DECISIONS.md` first. Existing `AGENTS.md`, `ARCHITECTURE.md`, `DEVELOPMENT_GUIDELINES.md` are reference; where they disagree with current code, the code is the CURRENT IMPLEMENTATION and the conflict needs an owner decision.

## Stack (current)
Flutter, Riverpod 2 (StateNotifier/providers), GoRouter, Dio, flutter_secure_storage, shared_preferences, intl, equatable, google_fonts, flutter_svg, image_picker.

Do not add packages for payment, OTP/SMS, location, maps, or push notifications — those providers are **DECISION REQUIRED**. Ask first.

## Structure
```
lib/app/        app.dart, config/, router/ (app_router.dart, route_names.dart), theme/
lib/core/       constants, errors, network (ApiClient, AuthInterceptor), storage, providers, utils, validators, services
lib/shared/     widgets used by 2+ features (export via widgets.dart)
lib/features/<feature>/data/{datasources,models,repositories}
lib/features/<feature>/presentation/{providers,screens,widgets}
```
- Feature-specific widgets stay in the feature. Only genuinely shared UI goes in `lib/shared/`.
- Screens/providers call repositories; never Dio or data sources directly.
- Riverpod is the only state management / DI. GoRouter is the only navigation. Route names/paths live in `route_names.dart`.
- Endpoints live in `core/constants/api_endpoints.dart`. Storage keys in `core/constants/app_constants.dart`; add new user-scoped keys to `userScopedStorageKeys` so logout clears them.

## Data & business logic
- Backend is authoritative for prices, totals, fees, stock, store assignment, order/payment status. Display server values; don't recompute authoritative totals.
- Don't hard-code business rules (fees, thresholds, COD limits); read from backend (`/customer/delivery-settings`).
- Use `AppConstants` currency (₹/INR/en_IN) and `currency_formatter.dart`.
- Checkout currently sends `DELIVERY` only and ONLINE has no payment SDK — do not change payment/pickup behavior without a decision (P-001, P-002, P-006).
- OTP length in UI (4) is undecided (P-004); don't change without approval.

## UI conventions
- Use design tokens: `AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`, `AppShadows`, `AppDimensions`.
- Responsive: context-bound API only — `context.r()`, `context.w()`, `context.h()`, `context.sp()` (baseline 390×844). No `num` extensions like `16.r`, no global viewport state.
- Don't scale borders, business values, or durations. Touch targets ≥ 48dp. Respect system text scale.
- Tablet: constrain widths with `AppBreakpoints` (form 440, legal 600, content 720).
- Lists: `AsyncValue.when` with `AppLoading`, `AppEmptyState`, `AppErrorState` (+ retry) and pull-to-refresh.

## Naming
Files `snake_case.dart`; classes `PascalCase`; vars/functions/providers `camelCase`.

## Security
- Tokens only in `SecureStorageService`. Never log tokens or OTPs.
- Base URL via `--dart-define=API_BASE_URL`; no secrets in Dart code.

## Testing
- `flutter analyze` → 0 issues; `flutter test` → all pass.
- Tests live in `test/` (flat). Add widget/flow tests for new screens and providers; override repositories with fakes via Riverpod.
- UI changes: check small phone (360×640), baseline (390×844), tablet (768×1024), landscape, and large text scale.
- Never delete or skip tests.
