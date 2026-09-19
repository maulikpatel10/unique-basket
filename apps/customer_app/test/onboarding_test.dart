import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:customer_app/features/onboarding/presentation/widgets/onboarding_pagination.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _createTestWidget({
  required Widget child,
  ThemeMode themeMode = ThemeMode.light,
  LocalStorageService? localStorage,
}) {
  return ProviderScope(
    overrides: [
      if (localStorage != null)
        localStorageProvider.overrideWithValue(localStorage),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingScreen Widget Tests', () {
    test('Onboarding route constant is defined correctly', () {
      expect(RouteNames.onboarding, equals('/onboarding'));
    });

    test('OnboardingScreen contains exactly 3 items matching specifications', () {
      expect(OnboardingScreen.items.length, equals(3));

      expect(
        OnboardingScreen.items[0].title,
        contains('Freshness'),
      );
      expect(
        OnboardingScreen.items[1].title,
        contains('Your favorites'),
      );
      expect(
        OnboardingScreen.items[2].title,
        contains('From our basket'),
      );
    });

    testWidgets('Renders first page with Skip button, logo, title, subtitle, and Next CTA',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      await tester.pumpWidget(
        _createTestWidget(
          localStorage: localStorage,
          child: const OnboardingScreen(),
        ),
      );

      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Freshness\nyou can trust'), findsOneWidget);
      expect(
        find.text(
            'Carefully selected fruits and vegetables,\nfresh from the farm to your family.'),
        findsOneWidget,
      );
      expect(find.text('Next'), findsOneWidget);
      expect(find.byType(OnboardingPagination), findsOneWidget);
    });

    testWidgets('Tapping Next button advances through pages to Get Started and persists completion',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      bool completed = false;

      await tester.pumpWidget(
        _createTestWidget(
          localStorage: localStorage,
          child: OnboardingScreen(
            onComplete: () {
              completed = true;
            },
          ),
        ),
      );

      // Page 1
      expect(find.text('Freshness\nyou can trust'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 2
      expect(find.text('Your favorites,\nmade simple'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Page 3
      expect(find.text('From our basket\nto your door'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Complete on Page 3
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(localStorage.getBool(AppConstants.keyOnboardingCompleted), isTrue);
    });

    testWidgets('Tapping Skip triggers onComplete immediately and persists completion',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      bool completed = false;

      await tester.pumpWidget(
        _createTestWidget(
          localStorage: localStorage,
          child: OnboardingScreen(
            onComplete: () {
              completed = true;
            },
          ),
        ),
      );

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(localStorage.getBool(AppConstants.keyOnboardingCompleted), isTrue);
    });

    testWidgets('Swiping left advances to next page',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      await tester.pumpWidget(
        _createTestWidget(
          localStorage: localStorage,
          child: const OnboardingScreen(),
        ),
      );

      expect(find.text('Freshness\nyou can trust'), findsOneWidget);

      // Swipe left
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Your favorites,\nmade simple'), findsOneWidget);
    });
  });

  group('Onboarding Responsive Viewport Tests', () {
    const viewports = [
      Size(320, 568), // Small phone
      Size(360, 800), // Standard Android phone
      Size(390, 844), // iPhone baseline
      Size(430, 932), // Large iPhone
      Size(600, 960), // Small tablet
      Size(768, 1024), // Large tablet
    ];

    for (final size in viewports) {
      testWidgets('Renders without overflow on viewport ${size.width}x${size.height}',
          (WidgetTester tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;

        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final localStorage = LocalStorageService(prefs);

        await tester.pumpWidget(
          _createTestWidget(
            localStorage: localStorage,
            child: const OnboardingScreen(),
          ),
        );

        expect(find.byType(OnboardingScreen), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Advance to page 2 and page 3 to verify all slides
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
      });
    }
  });
}
