# UNIQUE BASKET — Mobile Architecture Specification

**Framework**: Flutter (Dart) — Android & iOS  
**State Management**: Riverpod (StateNotifier / AsyncNotifier)  
**Networking**: Dio with Centralized Interceptors & Token Refresh  
**Local Storage**: Flutter Secure Storage (JWT/Tokens) & Hive / Shared Preferences (Local cache & Favourites)

---

## 1. Project Directory Structure

```
mobile/
├── android/
├── ios/
├── assets/
│   ├── icons/
│   ├── images/
│   └── fonts/
│
├── lib/
│   ├── main.dart                      # App entrypoint & ProviderScope initialization
│   ├── app.dart                       # MaterialApp configuration & router setup
│   │
│   ├── core/
│   │   ├── config/                    # Environment (dev/prod) & API base URLs
│   │   ├── constants/                 # App constants, asset paths, API paths
│   │   ├── errors/                    # Failure classes & API exception mappers
│   │   ├── network/                   # Dio client, auth interceptor, retry logic
│   │   ├── storage/                   # Secure storage wrapper for JWT tokens
│   │   ├── theme/                     # Brand colors, typography, theme data
│   │   ├── utils/                     # Formatting (currency, date, unit converters)
│   │   └── widgets/                   # Reusable atomic UI components
│   │       ├── app_button.dart
│   │       ├── app_text_field.dart
│   │       ├── product_card.dart
│   │       ├── category_card.dart
│   │       ├── loading_indicator.dart
│   │       ├── empty_state_view.dart
│   │       ├── error_view.dart
│   │       ├── quantity_selector.dart
│   │       └── price_tag.dart
│   │
│   ├── data/
│   │   ├── models/                    # Data Transfer Objects (DTOs) & JSON serializers
│   │   │   ├── user_model.dart
│   │   │   ├── category_model.dart
│   │   │   ├── product_model.dart
│   │   │   ├── cart_model.dart
│   │   │   ├── order_model.dart
│   │   │   ├── store_model.dart
│   │   │   ├── address_model.dart
│   │   │   └── fare_settings_model.dart
│   │   │
│   │   ├── datasources/               # Remote API Data Sources
│   │   └── repositories/              # Repository implementations
│   │
│   ├── features/                      # Feature modules (Presentation + State)
│   │   ├── auth/                      # Welcome, Phone Login, OTP Verification
│   │   ├── home/                      # Dashboard, Banner Carousel, Featured Lists
│   │   ├── categories/                # Category Explorer & Category Products
│   │   ├── products/                  # Product Listing, Details, Search, Decimal Qty
│   │   ├── favourites/                # Saved / Wishlist products
│   │   ├── cart/                      # Persistent cart, subtotal, quantity updates
│   │   ├── addresses/                 # Address list, Map/Form address creation
│   │   ├── checkout/                  # Delivery/Pickup selection, Fares, COD/Online
│   │   ├── orders/                    # Order Confirmation, History, Detail Stepper
│   │   ├── account/                   # Profile, Settings, Support, Logout
│   │   └── notifications/             # Push token handling & notification center
│   │
│   └── routes/                        # GoRouter / Navigator route definitions
│
├── test/                              # Unit & Widget Test Suite
└── pubspec.yaml                       # Dependencies & Assets configuration
```

---

## 2. Core Architectural Principles

### 2.1 Backend as Source of Truth
- The customer application never calculates or commits authoritative financial calculations (subtotals, delivery fees, COD charges, discounts, grand totals) independently.
- The app sends intent to the backend, displays server-calculated figures, and gracefully shows backend validation messages if constraints are violated.

### 2.2 Centralized Network Layer & Interceptors
- **Dio Client** configured with:
  - Base URL from environment config.
  - Connect/Receive timeout (15 seconds).
  - Auth Interceptor automatically appending `Authorization: Bearer <token>`.
  - Automatic `401 Unauthorized` token refreshing via `/auth/refresh`.
  - Global error mapper converting backend error codes (`INSUFFICIENT_STOCK`, `COD_DISABLED`, `NO_DELIVERY_AVAILABLE`) into user-friendly UI feedback.

### 2.3 State Management Workflow (Riverpod)
- UI triggers actions on Riverpod Notifiers/Providers.
- Notifiers communicate with Repositories.
- Repositories call Data Sources and return Domain Models or throw typed Failures.
- Notifiers expose immutable State objects (AsyncValue: data, loading, error) consumed via `ref.watch()`.

---

## 3. Brand & Visual Design System

- **Primary Green Accent**: `#10B981` (Emerald-500) / `#059669` (Brand Green)
- **Backgrounds**: Light clean theme for customer app (`#F8FAFC` slate background, `#FFFFFF` crisp cards) with sleek dark accents matching Unique Basket identity.
- **Typography**: Modern sans-serif (Inter / Outfit / Roboto).
- **Component Geometry**: Rounded corners (`8px–12px`), subtle soft shadows, high-contrast readable labels.
- **Responsive**: Safe-area aware, debounced search inputs, keyboard-avoiding scroll views.
