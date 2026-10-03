# UNIQUE BASKET Customer App — Architecture (current implementation)

This document describes how the Flutter customer app is **actually built today**.
Project decision D-010 (`docs/DECISIONS.md`): the app has **no separate `domain/` layer**, and none is to be
introduced. Working code is not refactored just to match older documentation.

## 1. Layers

```
  Screens & widgets                         features/<f>/presentation/screens, widgets
        │  ref.watch / ref.read
        ▼
  Riverpod providers / StateNotifiers       features/<f>/presentation/providers
        │
        ▼
  Repositories (abstract class + Impl)      features/<f>/data/repositories
        │
        ▼
  Remote data sources + models (JSON)       features/<f>/data/datasources, data/models
        │
        ▼
  ApiClient (Dio + AuthInterceptor),        core/network, core/storage
  SecureStorageService, LocalStorageService
        │
        ▼
  Backend REST API  /api/v1/*  (authoritative for prices, totals, fees, stock, order/payment state)
```

- Each repository is declared as an `abstract class` next to its `…Impl` in `data/repositories/`.
  That abstract class is the contract that providers depend on and that tests fake. There is no separate domain package.
- Models in `data/models/` are the app's data types (parsed from backend JSON). There are no separate entity classes.
- Business rules (prices, fees, thresholds, stock, order state) come from the backend. The app displays server values
  and only uses local fallbacks while data loads (see `DeliverySettingsModel` defaults).

## 2. Directory structure

```
lib/
├── main.dart                 ProviderScope + app bootstrap
├── app/
│   ├── app.dart              MaterialApp.router
│   ├── config/               app_config.dart, environment.dart (APP_ENV, API_BASE_URL)
│   ├── router/               app_router.dart (GoRouter + auth redirect), route_names.dart
│   └── theme/                design tokens + app_responsive.dart (context-bound sizing)
├── core/                     app-wide infrastructure, no feature logic
│   ├── constants/            api_endpoints.dart, app_constants.dart
│   ├── errors/               app_exception.dart, failure.dart
│   ├── extensions/
│   ├── network/              api_client.dart, auth_interceptor.dart (token refresh)
│   ├── providers/            core_providers.dart (storage, ApiClient)
│   ├── services/             startup_state_resolver.dart
│   ├── session/              session_expiry_notifier.dart
│   ├── storage/              secure_storage_service.dart, local_storage_service.dart
│   ├── utils/                currency/date formatters, debouncer, jwt_utils
│   └── validators/           app_validators.dart
├── shared/widgets/           UI used by 2+ features (exported via widgets.dart)
└── features/<feature>/
    ├── data/                 datasources/, models/, repositories/   (only where the feature calls the API)
    └── presentation/         providers/, screens/, widgets/
```

Current features: `address`, `authentication`, `cart`, `checkout`, `explore`, `favorites`, `home`, `legal`,
`notifications`, `onboarding`, `orders`, `payment`, `product`, `profile`, `profile_setup`, `search`, `splash`, `store`.
UI-only features (for example `explore`, `legal`, `onboarding`, `search`, `splash`) have only `presentation/`.
`payment/` holds UI only. No payment SDK is integrated, and the payment provider is undecided (P-001).

## 3. Rules

- Screens and providers use repositories. They never call Dio, `ApiClient` or data sources directly.
- Riverpod is the only state management and DI mechanism. GoRouter is the only navigation mechanism.
  Route names and paths live in `route_names.dart`.
- Feature-specific widgets stay in the feature. Only genuinely shared UI goes in `lib/shared/`.
- `lib/core/` contains no feature business logic.
- Endpoints live in `core/constants/api_endpoints.dart`. Storage keys live in `core/constants/app_constants.dart`.
- Tests override repositories/providers with fakes through Riverpod (`test/`, flat).

See `apps/customer_app/CLAUDE.md` for conventions and `AGENTS.md` for agent rules.
