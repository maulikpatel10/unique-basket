# UNIQUE BASKET Customer App — Agent Guidelines & Invariants

This file defines the mandatory engineering rules, architectural invariants, and constraints for all AI coding agents working on the `customer_app/` repository.

---

## 1. Scope & Isolation
- **Customer App Boundary**: All modifications, creations, and deletions MUST be strictly confined within `customer_app/`.
- **Protected Directories**: NEVER modify or create files in `backend/`, `admin/`, or repository root level (such as root `ARCHITECTURE.md` or root configuration).
- **Inspect Before Modifying**: Always read and understand existing files, contracts, and providers before creating new implementations.

---

## 2. Architectural Invariants
- **Feature-First**: All domain, data, and presentation code for a given business capability MUST reside within `lib/features/<feature_name>/`.
- **Clean Architecture Boundaries**:
  - `Domain` defines business entities and repository contracts. Domain MUST NOT depend on Flutter UI, Dio, or platform plugins.
  - `Data` implements data sources, DTOs/models, and repository implementations.
  - `Presentation` contains screens, widgets, and Riverpod StateNotifiers/ViewModels.
  - `Presentation` MUST NEVER invoke Dio or raw RemoteDataSources directly.
- **Cross-Cutting Core**: `lib/core/` is reserved ONLY for app-wide infrastructure (Network client, Storage abstractions, Core Failures, Utility formatters, Validators).
- **Reusable Shared UI**: `lib/shared/` holds genuinely shared, multi-feature UI components (`AppButton`, `AppPrice`, `AppEmptyState`, etc.). Do NOT place feature-specific widgets in shared.
- **Routing & Navigation**: GoRouter is the single navigation framework. Route paths and names are centralized in `lib/app/router/`.
- **State Management**: Riverpod is the sole state-management and DI solution. Do not introduce BLoC, GetX, or other libraries.

---

## 3. Testing & Verification Rules
- **Non-Destructive Testing**: NEVER delete or disable existing tests to resolve migration or build failures.
- **Verification Commands**:
  - `flutter analyze` must return **0 issues** (no warnings or errors).
  - `flutter test` must pass 100% of unit and widget tests.
- **Incremental Commits**: Validate changes incrementally after restructuring each feature.

---

## 4. Environment & Platform Configuration
- **Platform Base URL Resolution**:
  - Android Emulator: `http://10.0.2.2:5001/api/v1`
  - iOS Simulator: `http://localhost:5001/api/v1`
  - Custom / Production: Configurable via `--dart-define=API_BASE_URL=...`
- **Security & Tokens**: Never log or print full JWT access/refresh tokens in console output.
