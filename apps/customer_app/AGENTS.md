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

## 3. Responsive Design & Sizing Rules

The UNIQUE BASKET customer app uses a centralized, context-bound responsive sizing system.

### Design Baseline
The primary Figma/reference design baseline is:
- **Width**: `390 dp`
- **Height**: `844 dp`

Responsive behavior must preserve the visual intent of this baseline across supported phone sizes and tablets.

### Authoritative Responsive API
The responsive system MUST be context-bound.

Use:
```dart
context.r(value)   // General reference scaling (.r) based on 390dp width baseline
context.w(value)   // Width-specific scaling (.w)
context.h(value)   // Height-specific scaling (.h) based on 844dp height baseline
context.sp(value)  // Controlled font scaling (.sp) with accessibility TextScaler
```
These APIs derive sizing strictly from the current `BuildContext` / active `MediaQuery`.

**Prohibited Syntax**: Do NOT introduce or reintroduce context-free responsive sizing on `num` such as:
```dart
180.r
120.w
80.h
16.sp
```
Do NOT use global mutable viewport state to make context-free extensions work.

### Forbidden Responsive Architecture
Never introduce:
- `AppResponsive.update(context)` global viewport mutation
- `AppResponsiveScope`
- global `_overrideWidth` or `_overrideHeight`
- global text-scale overrides
- cached global `MediaQuery` dimensions
- `PlatformDispatcher.instance.views.first` as a substitute for the current widget context
- first-view / singleton viewport assumptions
- any other global mutable viewport state

Responsive calculations must be strictly isolated to the current widget tree/context.

### Centralized Scaling Behavior
All responsive utilities reside in `lib/app/theme/app_responsive.dart`:
- `.r` → general/reference scaling clamped to `[0.85, 1.20]`
- `.w` → width scaling clamped to `[0.85, 1.20]`
- `.h` → height scaling clamped to `[0.80, 1.20]`
- `.sp` → controlled font scaling clamped to `[0.90, 1.15]`, followed by native `TextScaler` integration

Do not bypass the centralized responsive system by creating feature-specific scaling formulas unless there is a documented, genuine requirement.

### Do Not Blindly Scale Everything
Responsive sizing does NOT mean every number should be scaled. Follow these principles:
- Use responsive sizing where visual dimensions (e.g. logos, banner heights, hero artwork) need adaptation.
- Keep borders (1.0dp / 1.5dp) and divider strokes visually stable.
- Keep minimum touch targets at least `48 dp` (`AppDimensions.minTouchTarget`).
- Do NOT scale business/data values (prices, quantities, IDs, item counts).
- Do NOT scale animation durations merely for responsiveness.
- Do NOT change business rules based on device size.
- Do NOT scale values simply because a responsive extension is available.

### Prefer Flutter's Native Responsive Layout
When layout itself should adapt, prefer Flutter's built-in layout mechanisms:
- `Expanded`, `Flexible`, `SizedBox.expand`, `double.infinity`
- `AspectRatio`, `ConstrainedBox`, `LayoutBuilder`
- `MediaQuery.sizeOf(context)`, `MediaQuery.paddingOf(context)`
- `Wrap`, `GridView`, `SliverGrid`

Do not use fixed widths/heights when a fluid layout is more appropriate. Responsive sizing and responsive layout are separate concerns.

### Tablet Behavior
Do NOT simply enlarge the phone UI on tablets:
- Use centered content layouts where appropriate.
- Constrain single-column forms with `AppBreakpoints.maxFormWidth` (440dp).
- Constrain legal/terms documentation with `AppBreakpoints.maxLegalWidth` (600dp).
- Constrain catalog/content containers with `AppBreakpoints.maxContentWidth` (720dp).
- Allow product/catalog grids to use additional horizontal space appropriately with dynamic columns.
- Preserve the intended visual hierarchy and information density without stretching.

### Typography & Accessibility
Responsive text sizing (`context.sp()`) must respect system accessibility settings.
- Do not disable or override the user's system text-size/accessibility preferences merely to preserve Figma dimensions.
- Text must remain readable and avoid clipping, overflow, overlapping, or broken button layouts.
- Validate critical flows with larger accessibility text scales.

### Design Tokens
Responsive sizing must work harmoniously with existing design tokens:
- `AppSpacing` (e.g. `AppSpacing.xs`, `sm`, `md`, `lg`, `xl`)
- `AppDimensions` (`minTouchTarget`, `buttonHeight`, `appBarHeight`, `bottomNavHeight`, `maxFormWidth`, etc.)
- `AppRadius` (`AppRadius.xs`, `sm`, `md`, `lg`, `rMd`, `rFull`)
- `AppTextStyles` (`displayLarge`, `headlineMedium`, `titleMedium`, `bodyMedium`, `price`, etc.)
- `AppColors` and `AppShadows`

Do NOT replace semantic tokens with arbitrary raw responsive numbers throughout the application.

### Touch Targets
Interactive controls must maintain a minimum practical touch target of at least `48 dp` (`AppDimensions.minTouchTarget`). Do not reduce buttons, icon buttons, tappable rows, or chips below accessible touch sizes to match a visual mockup.

### Screen-Specific Exceptions
If a screen has a legitimate reason to use a custom responsive rule, document the reason in the implementation rather than creating another global responsive mechanism. All responsive behavior must remain predictable, testable, and context-aware.

---

## 4. Testing & Verification Rules
- **Non-Destructive Testing**: NEVER delete or disable existing tests to resolve migration or build failures.
- **Responsive Viewport Coverage**: Verify responsive behavior across representative viewport sizes:
  - Small phone (e.g. `320 × 568`, `360 × 640`)
  - Baseline phone (`390 × 844`, `393 × 852`, `412 × 915`, `430 × 932`)
  - Tablet viewport (`600 × 960`, `768 × 1024`)
  - Landscape orientations (`844 × 390`, `1024 × 768`)
- **Responsive Invariants to Test**:
  - Calculations must derive strictly from the current `BuildContext` (no cross-context bleed).
  - Layouts must not overflow across supported viewports.
  - Accessibility text scaling must integrate with Flutter's `TextScaler`.
  - Content on tablets must respect max-width boundaries.
- **Verification Commands**:
  - `flutter analyze` must return **0 issues** (no warnings or errors).
  - `flutter test` must pass 100% of unit and widget tests.
- **Incremental Commits**: Validate changes incrementally after restructuring each feature.

---

## 5. Environment & Platform Configuration
- **Platform Base URL Resolution**:
  - Android Emulator: `http://10.0.2.2:5001/api/v1`
  - iOS Simulator: `http://localhost:5001/api/v1`
  - Custom / Production: Configurable via `--dart-define=API_BASE_URL=...`
- **Security & Tokens**: Never log or print full JWT access/refresh tokens in console output.
