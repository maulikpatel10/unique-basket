import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('Brand Color Tokens', () {
    test('Official brand color hex values match specifications', () {
      expect(AppColors.primary, equals(const Color(0xFF014D40)));
      expect(AppColors.secondary, equals(const Color(0xFFE7F5F4)));
      expect(AppColors.tertiary, equals(const Color(0xFF8F4E00)));
    });

    test('Semantic color tokens are non-null and defined', () {
      expect(AppColors.onPrimary, equals(const Color(0xFFFFFFFF)));
      expect(AppColors.onSecondary, equals(AppColors.primary));
      expect(AppColors.onTertiary, equals(const Color(0xFFFFFFFF)));
      expect(AppColors.background, isNotNull);
      expect(AppColors.surface, isNotNull);
      expect(AppColors.error, equals(const Color(0xFFDC2626)));
    });
  });

  group('Typography System (Montserrat)', () {
    test('Font family references Montserrat', () {
      expect(AppTextStyles.fontFamily.toLowerCase(), contains('montserrat'));
    });

    test('Standard type scales are defined with appropriate weights', () {
      expect(AppTextStyles.displayLarge.fontSize, equals(57.0));
      expect(AppTextStyles.headlineMedium.fontSize, equals(28.0));
      expect(AppTextStyles.titleMedium.fontSize, equals(16.0));
      expect(AppTextStyles.bodyMedium.fontSize, equals(14.0));
      expect(AppTextStyles.labelSmall.fontSize, equals(11.0));
    });

    test('Semantic price and button text styles are available', () {
      expect(AppTextStyles.button.fontSize, equals(15.0));
      expect(AppTextStyles.price.fontWeight, equals(FontWeight.w700));
      expect(AppTextStyles.priceLarge.fontSize, equals(22.0));
    });

    test('createTextTheme builds full Material 3 text theme', () {
      final textTheme = AppTextStyles.createTextTheme(Brightness.light);
      expect(textTheme.headlineMedium, isNotNull);
      expect(textTheme.bodyMedium, isNotNull);
      expect(textTheme.labelLarge, isNotNull);
    });
  });

  group('Material 3 Theme Integration', () {
    test('Light theme builds with Material 3 and brand colorScheme', () {
      final theme = AppTheme.lightTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.light));
      expect(theme.colorScheme.primary, equals(const Color(0xFF014D40)));
      expect(theme.colorScheme.secondary, equals(const Color(0xFFE7F5F4)));
      expect(theme.colorScheme.tertiary, equals(const Color(0xFF8F4E00)));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.background));
      expect(theme.cardTheme.elevation, equals(0));
    });

    test('Dark theme builds with Material 3 and brand colorScheme', () {
      final theme = AppTheme.darkTheme;

      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, equals(Brightness.dark));
      expect(theme.colorScheme.primary, equals(const Color(0xFF014D40)));
      expect(theme.colorScheme.secondary, equals(const Color(0xFFE7F5F4)));
      expect(theme.colorScheme.tertiary, equals(const Color(0xFF8F4E00)));
      expect(theme.scaffoldBackgroundColor, equals(AppColors.backgroundDark));
      expect(theme.colorScheme.surface, equals(AppColors.surfaceDark));
    });

    test('Aliases AppTheme.light and AppTheme.dark work correctly', () {
      expect(AppTheme.light.colorScheme.primary, equals(AppTheme.lightTheme.colorScheme.primary));
      expect(AppTheme.dark.colorScheme.primary, equals(AppTheme.darkTheme.colorScheme.primary));
    });
  });

  group('Spacing, Radius, Dimensions & Shadows Tokens', () {
    test('Spacing scale follows consistent progression', () {
      expect(AppSpacing.none, equals(0.0));
      expect(AppSpacing.xs, equals(4.0));
      expect(AppSpacing.sm, equals(8.0));
      expect(AppSpacing.md, equals(16.0));
      expect(AppSpacing.lg, equals(24.0));
      expect(AppSpacing.xl, equals(32.0));
      expect(AppSpacing.xxl, equals(40.0));
      expect(AppSpacing.xxxl, equals(48.0));
    });

    test('Radius scalar values and BorderRadius objects are valid', () {
      expect(AppRadius.xs, equals(4.0));
      expect(AppRadius.md, equals(12.0));
      expect(AppRadius.rMd.topLeft.x, equals(12.0));
      expect(AppRadius.rFull.topLeft.x, equals(999.0));
    });

    test('Dimensions contain accessibility min touch target standard', () {
      expect(AppDimensions.minTouchTarget, equals(48.0));
      expect(AppDimensions.buttonHeight, equals(48.0));
      expect(AppDimensions.appBarHeight, equals(56.0));
      expect(AppDimensions.bottomNavHeight, equals(64.0));
      expect(AppDimensions.maxFormWidth, equals(440.0));
      expect(AppDimensions.maxLegalWidth, equals(600.0));
      expect(AppDimensions.maxContentWidth, equals(720.0));
    });

    test('Shadow elevation lists are defined', () {
      expect(AppShadows.none, isEmpty);
      expect(AppShadows.sm, isNotEmpty);
      expect(AppShadows.md, isNotEmpty);
      expect(AppShadows.lg, isNotEmpty);
      expect(AppShadows.primary, isNotEmpty);
    });
  });

  group('Responsive System & Extensions (Context-Bound)', () {
    test('Breakpoints have accurate thresholds and max-width limits', () {
      expect(AppBreakpoints.smallPhone, equals(360.0));
      expect(AppBreakpoints.phone, equals(600.0));
      expect(AppBreakpoints.tablet, equals(600.0));
      expect(AppBreakpoints.desktop, equals(1024.0));
      expect(AppBreakpoints.shortScreen, equals(680.0));
      expect(AppBreakpoints.maxFormWidth, equals(440.0));
      expect(AppBreakpoints.maxLegalWidth, equals(600.0));
      expect(AppBreakpoints.maxContentWidth, equals(720.0));
    });

    testWidgets('Context-bound responsive calculations at baseline (390 x 844)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                expect(context.screenWidth, equals(390.0));
                expect(context.screenHeight, equals(844.0));
                expect(context.isPhone, isTrue);
                expect(context.isTablet, isFalse);
                expect(context.isSmallPhone, isFalse);
                expect(context.isCompact, isFalse);

                // Baseline scaling (1.0x factor)
                expect(context.r(100), equals(100.0));
                expect(context.w(100), equals(100.0));
                expect(context.h(100), equals(100.0));
                expect(context.sp(16), equals(16.0));
                expect(context.responsiveWidth(0.5), equals(195.0));
                expect(context.responsiveHeight(0.5), equals(422.0));
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Width and height clamping behaviors (min/max bounds)',
        (WidgetTester tester) async {
      // 1. Oversized Tablet screen (780 x 1200) -> tests maximum clamps
      tester.view.physicalSize = const Size(780 * 2, 1200 * 2);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Width scale 780 / 390 = 2.0 -> clamped to 1.20 max
                expect(context.w(100), equals(120.0));
                expect(context.r(100), equals(120.0));

                // Height scale 1200 / 844 = 1.42 -> clamped to 1.20 max
                expect(context.h(100), equals(120.0));

                // Font scale clamped to 1.15 max
                expect(context.sp(20), equals(23.0)); // 20 * 1.15 = 23.0

                expect(context.isTablet, isTrue);
                expect(context.isPhone, isFalse);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      // 2. Very small screen (300 x 500) -> tests minimum clamps
      tester.view.physicalSize = const Size(300 * 2, 500 * 2);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Width scale 300 / 390 = 0.769 -> clamped to 0.85 min
                expect(context.w(100), equals(85.0));
                expect(context.r(100), equals(85.0));

                // Height scale 500 / 844 = 0.592 -> clamped to 0.80 min
                expect(context.h(100), equals(80.0));

                // Font scale clamped to 0.90 min
                expect(context.sp(20), equals(18.0)); // 20 * 0.90 = 18.0

                expect(context.isSmallPhone, isTrue);
                expect(context.isCompact, isTrue);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Font scaling integrates with OS accessibility TextScaler',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(1.5),
            ),
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  // At baseline 390 width, fontDimensionScale = 1.0.
                  // TextScaler 1.5x -> 16.0 * 1.0 * 1.5 = 24.0.
                  expect(context.sp(16), equals(24.0));
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Multi-viewport responsive matrix without exceptions',
        (WidgetTester tester) async {
      const viewports = <Size>[
        Size(320, 568),
        Size(360, 640),
        Size(390, 844),
        Size(393, 852),
        Size(412, 915),
        Size(430, 932),
        Size(600, 960),
        Size(768, 1024),
        Size(844, 390), // Landscape phone
        Size(1024, 768), // Landscape tablet
      ];

      for (final vp in viewports) {
        tester.view.physicalSize = Size(vp.width * 2, vp.height * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  expect(context.r(24), isPositive);
                  expect(context.w(100), isPositive);
                  expect(context.h(100), isPositive);
                  expect(context.sp(16), isPositive);

                  if (vp.width >= vp.height) {
                    expect(context.responsive.isLandscape, isTrue);
                  } else {
                    expect(context.responsive.isPortrait, isTrue);
                  }
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
      }

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
    });

    testWidgets('Context correctness / View isolation test (prevents global state bug)',
        (WidgetTester tester) async {
      // In this test, we render two distinct nested MediaQuery subtree contexts:
      // Context A with 390 width (baseline -> scale = 1.0)
      // Context B with 780 width (oversized -> scale = 1.20)
      // We verify that calculating from Context A returns 100.0, and from Context B returns 120.0,
      // proving zero shared mutable static state or cross-talk between contexts.

      late BuildContext contextA;
      late BuildContext contextB;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                MediaQuery(
                  data: const MediaQueryData(size: Size(390, 844)),
                  child: Builder(
                    builder: (ctx) {
                      contextA = ctx;
                      return const SizedBox();
                    },
                  ),
                ),
                MediaQuery(
                  data: const MediaQueryData(size: Size(780, 844)),
                  child: Builder(
                    builder: (ctx) {
                      contextB = ctx;
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Context A must calculate using 390 width -> 100.0
      expect(contextA.w(100), equals(100.0));
      expect(contextA.r(100), equals(100.0));

      // Context B must calculate using 780 width -> 120.0
      expect(contextB.w(100), equals(120.0));
      expect(contextB.r(100), equals(120.0));

      // Re-querying Context A AFTER Context B was queried must STILL return 100.0 (strictly isolated)
      expect(contextA.w(100), equals(100.0));
      expect(contextA.r(100), equals(100.0));
    });
  });
}
