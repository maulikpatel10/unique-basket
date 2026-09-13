# UNIQUE BASKET Customer Mobile App — Architecture Migration Plan

## 1. Executive Summary
This document outlines the step-by-step migration of the UNIQUE BASKET Flutter customer application from the existing hybrid structure into a clean, feature-first, MVVM-style production architecture with Riverpod state management and GoRouter navigation.

All existing business logic, authentication, networking, caching, and UI behaviors will be strictly preserved.

---

## 2. Current Folder Structure (Pre-Migration)

```
customer_app/lib/
├── app.dart
├── main.dart
├── core/
│   ├── config/ (app_config.dart, env.dart)
│   ├── constants/ (api_endpoints.dart, app_constants.dart)
│   ├── errors/ (app_exception.dart, failure.dart)
│   ├── network/ (api_client.dart, auth_interceptor.dart)
│   ├── providers/ (core_providers.dart)
│   ├── storage/ (local_storage_service.dart, secure_storage_service.dart)
│   ├── theme/ (app_colors.dart, app_spacing.dart, app_text_styles.dart, app_theme.dart)
│   ├── utils/ (currency_formatter.dart, date_formatter.dart, debouncer.dart)
│   └── widgets/ (app_button.dart, app_empty_state.dart, app_error_state.dart, app_loading.dart, app_phone_field.dart, app_price.dart, app_primary_card.dart, app_quantity_selector.dart, app_text_field.dart)
├── data/
│   ├── datasources/ (auth, cart, category, order, payment, product, store)
│   ├── models/ (address, banner, cart_item, cart, category, fare_settings, order_item, order, payment, product, store, user)
│   └── repositories/ (auth, cart, category, order, payment, product, store)
├── features/
│   ├── account/presentation/screens/account_screen.dart
│   ├── addresses/presentation/screens/addresses_screen.dart
│   ├── auth/presentation/ (providers, screens)
│   ├── cart/presentation/ (providers, screens)
│   ├── categories/presentation/ (providers, screens, widgets)
│   ├── checkout/presentation/screens/checkout_screen.dart
│   ├── favourites/presentation/ (providers, screens)
│   ├── home/presentation/ (providers, screens, widgets)
│   ├── orders/presentation/screens/ (orders_screen.dart, order_detail_screen.dart)
│   └── products/presentation/ (providers, screens)
└── routes/
    ├── app_router.dart
    └── route_names.dart
```

---

## 3. Target Architecture Structure

```
customer_app/lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   ├── config/
│   │   ├── app_config.dart
│   │   └── environment.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   ├── route_names.dart
│   │   └── route_guards.dart
│   └── theme/
│       ├── app_theme.dart
│       ├── app_colors.dart
│       ├── app_text_styles.dart
│       ├── app_spacing.dart
│       ├── app_radius.dart
│       ├── app_shadows.dart
│       └── app_dimensions.dart
│
├── core/
│   ├── constants/
│   │   ├── api_endpoints.dart
│   │   └── app_constants.dart
│   ├── errors/
│   │   └── failure.dart
│   ├── exceptions/
│   │   └── app_exception.dart
│   ├── extensions/
│   │   └── string_extensions.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   └── auth_interceptor.dart
│   ├── storage/
│   │   ├── local_storage_service.dart
│   │   └── secure_storage_service.dart
│   ├── utils/
│   │   ├── currency_formatter.dart
│   │   ├── date_formatter.dart
│   │   └── debouncer.dart
│   └── validators/
│       └── app_validators.dart
│
├── shared/
│   └── widgets/
│       ├── app_button.dart
│       ├── app_empty_state.dart
│       ├── app_error_state.dart
│       ├── app_loading.dart
│       ├── app_phone_field.dart
│       ├── app_price.dart
│       ├── app_primary_card.dart
│       ├── app_quantity_selector.dart
│       └── app_text_field.dart
│
└── features/
    ├── authentication/
    │   ├── data/
    │   │   ├── datasources/auth_remote_datasource.dart
    │   │   ├── models/user_model.dart
    │   │   └── repositories/auth_repository.dart
    │   └── presentation/
    │       ├── providers/ (auth_provider.dart, auth_state.dart)
    │       └── screens/ (welcome_screen.dart, login_screen.dart, otp_verification_screen.dart)
    ├── home/
    │   ├── data/
    │   │   ├── datasources/store_remote_datasource.dart
    │   │   ├── models/ (banner_model.dart, store_model.dart)
    │   │   └── repositories/store_repository.dart
    │   └── presentation/
    │       ├── providers/ (banner_provider.dart, store_provider.dart)
    │       ├── screens/home_screen.dart
    │       └── widgets/ (banner_carousel.dart, cart_bottom_pill.dart, category_section.dart, customer_bottom_nav.dart, home_header.dart, home_search_bar.dart, product_card.dart, product_section.dart, store_selector_modal.dart)
    ├── categories/
    │   ├── data/
    │   │   ├── datasources/category_remote_datasource.dart
    │   │   ├── models/category_model.dart
    │   │   └── repositories/category_repository.dart
    │   └── presentation/
    │       ├── providers/category_provider.dart
    │       ├── screens/categories_screen.dart
    │       └── widgets/category_card.dart
    ├── products/
    │   ├── data/
    │   │   ├── datasources/product_remote_datasource.dart
    │   │   ├── models/product_model.dart
    │   │   └── repositories/product_repository.dart
    │   └── presentation/
    │       ├── providers/product_provider.dart
    │       └── screens/ (products_screen.dart, product_detail_screen.dart)
    ├── cart/
    │   ├── data/
    │   │   ├── datasources/cart_remote_datasource.dart
    │   │   ├── models/ (cart_model.dart, cart_item_model.dart, fare_settings_model.dart)
    │   │   └── repositories/cart_repository.dart
    │   └── presentation/
    │       ├── providers/cart_provider.dart
    │       └── screens/cart_screen.dart
    ├── favourites/
    │   └── presentation/
    │       ├── providers/favourites_provider.dart
    │       └── screens/favourites_screen.dart
    ├── orders/
    │   ├── data/
    │   │   ├── datasources/order_remote_datasource.dart
    │   │   ├── models/ (order_model.dart, order_item_model.dart)
    │   │   └── repositories/order_repository.dart
    │   └── presentation/
    │       └── screens/ (orders_screen.dart, order_detail_screen.dart)
    ├── checkout/
    │   └── presentation/
    │       └── screens/checkout_screen.dart
    ├── addresses/
    │   ├── data/
    │   │   └── models/address_model.dart
    │   └── presentation/
    │       └── screens/addresses_screen.dart
    ├── profile/
    │   └── presentation/
    │       └── screens/account_screen.dart
    └── payments/
        └── data/
            ├── datasources/payment_remote_datasource.dart
            ├── models/payment_model.dart
            └── repositories/payment_repository.dart
```

---

## 4. Migration Mapping Table

| Source Path (Old) | Target Path (New) | Refactoring Scope |
|---|---|---|
| `lib/app.dart` | `lib/app/app.dart` | Update router and theme imports |
| `lib/core/config/app_config.dart` | `lib/app/config/app_config.dart` | Update environment imports |
| `lib/core/config/env.dart` | `lib/app/config/environment.dart` | Standardize config class naming |
| `lib/routes/app_router.dart` | `lib/app/router/app_router.dart` | Update feature imports, extract guards |
| `lib/routes/route_names.dart` | `lib/app/router/route_names.dart` | Centralize route constants |
| `lib/core/theme/*` | `lib/app/theme/*` | Add design tokens (radius, shadows, dimensions) |
| `lib/core/errors/app_exception.dart` | `lib/core/exceptions/app_exception.dart` | Dedicated exception boundary |
| `lib/core/widgets/*` | `lib/shared/widgets/*` | Shared UI components |
| `lib/data/datasources/auth_*` | `lib/features/authentication/data/datasources/*` | Feature encapsulation |
| `lib/data/models/user_model.dart` | `lib/features/authentication/data/models/user_model.dart` | Feature model ownership |
| `lib/data/repositories/auth_*` | `lib/features/authentication/data/repositories/*` | Feature repository ownership |
| `lib/features/auth/*` | `lib/features/authentication/presentation/*` | Feature presentation consolidation |
| `lib/data/datasources/category_*` | `lib/features/categories/data/datasources/*` | Feature encapsulation |
| `lib/data/models/category_model.dart`| `lib/features/categories/data/models/*` | Feature model ownership |
| `lib/data/repositories/category_*`| `lib/features/categories/data/repositories/*` | Feature repository ownership |
| `lib/data/datasources/product_*` | `lib/features/products/data/datasources/*` | Feature encapsulation |
| `lib/data/models/product_model.dart` | `lib/features/products/data/models/*` | Feature model ownership |
| `lib/data/repositories/product_*`| `lib/features/products/data/repositories/*` | Feature repository ownership |
| `lib/data/datasources/store_*` | `lib/features/home/data/datasources/*` | Feature encapsulation |
| `lib/data/models/store_model.dart` | `lib/features/home/data/models/*` | Feature model ownership |
| `lib/data/models/banner_model.dart`| `lib/features/home/data/models/*` | Feature model ownership |
| `lib/data/repositories/store_*` | `lib/features/home/data/repositories/*` | Feature repository ownership |
| `lib/data/datasources/cart_*` | `lib/features/cart/data/datasources/*` | Feature encapsulation |
| `lib/data/models/cart_*` | `lib/features/cart/data/models/*` | Feature model ownership |
| `lib/data/repositories/cart_*` | `lib/features/cart/data/repositories/*` | Feature repository ownership |
| `lib/data/datasources/order_*` | `lib/features/orders/data/datasources/*` | Feature encapsulation |
| `lib/data/models/order_*` | `lib/features/orders/data/models/*` | Feature model ownership |
| `lib/data/repositories/order_*` | `lib/features/orders/data/repositories/*` | Feature repository ownership |
| `lib/data/datasources/payment_*`| `lib/features/payments/data/datasources/*` | Feature encapsulation |
| `lib/data/models/payment_model.dart`| `lib/features/payments/data/models/*` | Feature model ownership |
| `lib/data/repositories/payment_*`| `lib/features/payments/data/repositories/*` | Feature repository ownership |
| `lib/data/models/address_model.dart`| `lib/features/addresses/data/models/*` | Feature model ownership |
| `lib/features/account/*` | `lib/features/profile/*` | Standardized feature naming |

---

## 5. Migration Execution Phases

1. **Phase 1: App Foundation Setup**
   - Create `lib/app/config/`, `lib/app/theme/`, `lib/app/router/`, `lib/app/app.dart`.
   - Update `main.dart` to import from `lib/app/app.dart`.

2. **Phase 2: Core & Shared Organization**
   - Move `lib/core/widgets/` to `lib/shared/widgets/`.
   - Setup `lib/core/exceptions/`, `lib/core/validators/`, `lib/core/extensions/`.

3. **Phase 3: Feature Migration (Authentication & Home)**
   - Move `auth` $\to$ `features/authentication/`.
   - Move `store` & `banner` $\to$ `features/home/`.

4. **Phase 4: Feature Migration (Catalog - Categories & Products)**
   - Move `category` $\to$ `features/categories/`.
   - Move `product` $\to$ `features/products/`.

5. **Phase 5: Feature Migration (Cart, Orders, Payments, Addresses, Profile)**
   - Move `cart` $\to$ `features/cart/`.
   - Move `order` $\to$ `features/orders/`.
   - Move `payment` $\to$ `features/payments/`.
   - Move `address` $\to$ `features/addresses/`.
   - Move `account` $\to$ `features/profile/`.

6. **Phase 6: Cleanup & Obsolete Folder Deletion**
   - Clean up empty `lib/data/` and `lib/routes/` folders.
   - Update all import statements across `lib/` and `test/`.

7. **Phase 7: Verification**
   - Run `flutter analyze` $\to$ 0 issues.
   - Run `flutter test` $\to$ 58/58 tests passing.
