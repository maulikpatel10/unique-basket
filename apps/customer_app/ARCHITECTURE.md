# UNIQUE BASKET Customer App — Architecture Specification

## 1. System Architecture Overview

The UNIQUE BASKET Flutter customer application follows a **Feature-First Clean Architecture** with **Riverpod State Management** and **MVVM-style Presentation**.

```
                           +------------------------+
                           |  UI Screens & Widgets  |  (Presentation)
                           +------------------------+
                                       |
                                       v
                           +------------------------+
                           | Riverpod ViewModels /  |  (Presentation)
                           |     StateNotifiers     |
                           +------------------------+
                                       |
                                       v
                           +------------------------+
                           |  Repository Contracts  |  (Domain / Feature)
                           |      & Entities        |
                           +------------------------+
                                       |
                                       v
                           +------------------------+
                           |     Repositories /     |  (Data / Feature)
                           |    RemoteDataSources   |
                           +------------------------+
                                       |
                                       v
                           +------------------------+
                           | ApiClient / Dio /      |  (Core Infrastructure)
                           | SecureStorageService   |
                           +------------------------+
```

---

## 2. Directory Structure Specification

```
customer_app/lib/
├── main.dart                      # App entry point, Riverpod ProviderScope initialization
│
├── app/                           # Global Application Setup
│   ├── app.dart                   # Root MaterialApp.router widget
│   ├── config/                    # App configuration & environment constants
│   │   ├── app_config.dart
│   │   └── environment.dart
│   ├── router/                    # GoRouter configuration & route definitions
│   │   ├── app_router.dart
│   │   ├── route_names.dart
│   │   └── route_guards.dart
│   └── theme/                     # Design tokens & Material 3 theme data
│       ├── app_theme.dart
│       ├── app_colors.dart
│       ├── app_text_styles.dart
│       ├── app_spacing.dart
│       ├── app_radius.dart
│       ├── app_shadows.dart
│       └── app_dimensions.dart
│
├── core/                          # Cross-Cutting Infrastructure (Domain-agnostic)
│   ├── constants/                 # API endpoints and system constants
│   ├── errors/                    # Failure definitions
│   ├── exceptions/                # AppException definitions
│   ├── extensions/                # Dart language extensions
│   ├── network/                   # Dio ApiClient & AuthInterceptor
│   ├── storage/                   # SecureStorage and SharedPreferences services
│   ├── utils/                     # Currency, date formatters, and debouncers
│   └── validators/                # Form & input validators
│
├── shared/                        # Multi-Feature Reusable UI Elements
│   └── widgets/                   # Standardized buttons, cards, text fields, loaders, empty states
│
└── features/                      # Feature Modules (Domain, Data, Presentation)
    ├── authentication/            # OTP phone authentication & session management
    ├── home/                      # Dashboard, banner carousel, store selector
    ├── categories/                # Category exploration and listing
    ├── products/                  # Product catalog, store inventory, details
    ├── cart/                      # Shopping cart, quantity updates, fare summary
    ├── favourites/                # Saved products and wishlist state
    ├── checkout/                  # Delivery address selection and payment initiation
    ├── orders/                    # Order history and order status details
    ├── addresses/                 # Customer address management
    ├── profile/                   # Account profile and preferences
    └── payments/                  # Payment verification and Razorpay integration
```

---

## 3. Layer Responsibilities & Boundaries

### 3.1 App Layer (`lib/app/`)
- Initializes root MaterialApp with the application theme and router.
- Provides environment-aware config resolution (`--dart-define=API_BASE_URL` with platform fallbacks).
- Manages GoRouter routing table, query parameter parsing, and session redirection guards.

### 3.2 Core Layer (`lib/core/`)
- Contains zero feature-specific business logic.
- Implements secure networking with automatic bearer token injection and 401 token refresh.
- Encapsulates low-level platform plugins (Keychain / Keystore via `flutter_secure_storage`).

### 3.3 Shared Layer (`lib/shared/`)
- Contains design system UI atoms and molecules (`AppButton`, `AppTextField`, `AppPrice`, `AppLoading`, etc.).
- Does not contain feature ViewModels or feature data sources.

### 3.4 Feature Layer (`lib/features/`)
- Self-contained vertical slices containing `data/`, `domain/`, and `presentation/` where appropriate.
- Feature providers provide reactive state streams to screens.
- Widgets specific to a single feature stay within that feature's `presentation/widgets/`.

---

## 4. State Management Standards
- All reactive state is managed via **Flutter Riverpod**.
- Immutable state classes with `copyWith()` methods for predictable state transitions.
- Providers are scoped and testable with mock repository overrides.
