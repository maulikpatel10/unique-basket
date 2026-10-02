# UNIQUE BASKET — Customer Mobile Application

The **UNIQUE BASKET Customer Application** is a cross-platform mobile app built with **Flutter** for browsing multi-store catalog inventory, managing carts, placing hyper-local grocery delivery/pickup orders, and tracking payments.

---

## Foundation Architecture

This codebase provides the clean, production-grade foundation for the Customer Application:

```text
apps/customer_app/
├── android/                  # Android native platform project
├── ios/                      # iOS native platform project
├── lib/
│   ├── app/                  # Application bootstrap, routing, and design system
│   │   ├── config/           # AppConfig and Environment configuration
│   │   ├── router/           # Minimal GoRouter foundation
│   │   └── theme/            # Material 3 design tokens and ThemeData
│   │
│   ├── core/                 # Shared core infrastructure
│   │   ├── constants/        # Global constants and storage keys
│   │   ├── errors/           # Exception and Failure hierarchy
│   │   ├── extensions/       # Global Dart extensions
│   │   ├── network/          # Generic Dio ApiClient and AuthInterceptor
│   │   ├── providers/        # Core Riverpod providers (storage, network)
│   │   ├── storage/          # Local (SharedPreferences) & SecureStorage
│   │   ├── utils/            # Formatters and debouncer utilities
│   │   └── validators/       # Input validation rules
│   │
│   ├── shared/
│   │   └── widgets/          # Generic UI primitives (AppButton, AppLoading, etc.)
│   │
│   ├── app.dart              # Root MaterialApp.router widget
│   └── main.dart             # Application main entry point
│
├── test/                     # Foundation test suites
├── pubspec.yaml              # Flutter dependencies and configuration
└── README.md
```

> **Note on Features**:
> Business feature modules will be introduced iteratively in dedicated feature branches under `lib/features/` (e.g., `feature/customer-app/authentication`, `feature/customer-app/home`, `feature/customer-app/catalog`, `feature/customer-app/cart`, `feature/customer-app/orders`).

---

## Tech Stack

- **Framework**: Flutter (`>=3.16.0`) & Dart SDK (`>=3.0.0 <4.0.0`)
- **State Management**: Flutter Riverpod (`v2.5.1`)
- **Navigation & Routing**: GoRouter (`v14.1.4`)
- **Networking**: Dio (`v5.4.3`)
- **Persistence**: `shared_preferences` & `flutter_secure_storage`
- **Typography & UI**: `google_fonts` (Inter) & `flutter_svg`

---

## Prerequisites

- **Flutter SDK**: `3.16.0` or higher
- **Dart SDK**: `3.0.0` or higher
- **UNIQUE BASKET Backend API**: Running locally on `http://localhost:5001/api/v1`

---

## Environment & API Configuration

The application supports configurable API base URLs via `--dart-define`:

```bash
# Connect to local development backend (default for iOS Simulator)
flutter run

# Connect to custom LAN / staging backend
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:5001/api/v1

# Release / staging builds MUST pass the API URL (the production domain is not decided yet).
# Release builds default to APP_ENV=production and refuse to start without API_BASE_URL.
flutter build appbundle --release --dart-define=API_BASE_URL=https://<api-host>/api/v1
flutter run --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=https://<staging-api-host>/api/v1
```

---

## Running the Application

```bash
# 1. Navigate to customer app directory
cd apps/customer_app

# 2. Fetch Flutter dependencies
flutter pub get

# 3. Launch on connected device or simulator
flutter run
```

---

## Running Tests & Code Quality

```bash
# Run automated foundation tests
flutter test

# Run static code analysis
flutter analyze
```
