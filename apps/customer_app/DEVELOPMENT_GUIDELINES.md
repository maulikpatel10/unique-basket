# UNIQUE BASKET Customer App — Development Guidelines

## 1. Code Style & Conventions
- **Language**: Dart (Flutter 3.x+ with sound null safety).
- **Linter**: Follow standard Flutter recommended linter rules. All code must pass `flutter analyze` with 0 warnings/errors.
- **Naming Conventions**:
  - Files and directories: `snake_case.dart`
  - Classes and Enums: `PascalCase`
  - Variables, functions, and providers: `camelCase`
  - Constants: `camelCase` or `kPascalCase`

---

## 2. Directory & Component Placement Rules
1. **New UI Component**:
   - If used in only one feature $\to$ `lib/features/<feature>/presentation/widgets/`
   - If used across 2+ features without domain logic $\to$ `lib/shared/widgets/`
2. **New Business Entity / API Model**:
   - Model $\to$ `lib/features/<feature>/data/models/`
   - Remote DataSource $\to$ `lib/features/<feature>/data/datasources/`
   - Repository $\to$ `lib/features/<feature>/data/repositories/`
3. **New State / Provider**:
   - Feature StateNotifier $\to$ `lib/features/<feature>/presentation/providers/`
   - Infrastructure provider $\to$ `lib/core/providers/`

---

## 3. Pull-To-Refresh & Error Handling Pattern
Every listing screen must implement a consistent AsyncValue error/loading pattern:
```dart
ref.watch(myFeatureProvider).when(
  data: (items) => RefreshIndicator(
    onRefresh: () async => ref.invalidate(myFeatureProvider),
    child: items.isEmpty
        ? AppEmptyState(message: 'No items available')
        : ListView.builder(...),
  ),
  loading: () => const AppLoading(),
  error: (err, stack) => AppErrorState(
    message: err.toString(),
    onRetry: () => ref.invalidate(myFeatureProvider),
  ),
);
```

---

## 4. Testing & QA Checklist
Before submitting changes:
1. Run `flutter analyze` and fix all warnings.
2. Run `flutter test` and ensure all unit/widget tests pass.
3. Verify on both Android Emulator (`10.0.2.2:5001`) and iOS Simulator (`localhost:5001`).
