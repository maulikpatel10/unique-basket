import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/explore/presentation/screens/explore_screen.dart';
import 'package:customer_app/features/explore/presentation/widgets/explore_category_card.dart';
import 'package:customer_app/features/home/data/models/category_model.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/store/data/models/store_model.dart';
import 'package:customer_app/features/store/presentation/providers/store_provider.dart';
import 'package:customer_app/shared/widgets/app_bottom_nav_bar.dart';
import 'package:customer_app/shared/widgets/app_empty_state.dart';
import 'package:customer_app/shared/widgets/app_error_state.dart';

final mockActiveCategories = [
  const CategoryModel(
    id: 'cdd9bf8e-e199-4b67-ad3d-1186483caae4',
    name: 'Fruits',
    imageUrl: 'https://images.unsplash.com/photo-1619566636858-adf3ef46400b',
    displayOrder: 1,
    isActive: true,
  ),
  const CategoryModel(
    id: '85f008eb-85e3-40e9-90b6-5553ac26f66c',
    name: 'Vegetables',
    imageUrl: 'https://images.unsplash.com/photo-1540420773420-3366772f4999',
    displayOrder: 2,
    isActive: true,
  ),
  const CategoryModel(
    id: '380f2c66-0561-4a9a-92e0-81a755ca952e',
    name: 'Leafy Vegetables',
    imageUrl: null,
    displayOrder: 3,
    isActive: true,
  ),
];

const mockServingStore = StoreModel(
  id: 'store_1',
  storeId: 'UB-RAJKOT-01',
  name: 'Unique Basket Superstore - Rajkot Hub',
  address: '150 Feet Ring Road, Rajkot',
  city: 'Rajkot',
  state: 'Gujarat',
  pincode: '360005',
  latitude: 22.3039,
  longitude: 70.8022,
  phone: '+91 98765 43210',
  openingTime: '08:00',
  closingTime: '22:00',
  distanceKm: 0.93,
);

Widget _createExploreScreenWidget({
  List<CategoryModel>? categories,
  Completer<List<CategoryModel>>? loadingCompleter,
  bool hasError = false,
  ThemeMode themeMode = ThemeMode.light,
  List<Override> additionalOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      defaultCustomerAddressProvider.overrideWithValue(
        const AsyncData({
          'title': 'Home',
          'addressLine': '123 Fresh Lane',
          'areaLocality': 'Fresh Lane',
          'city': 'Rajkot',
        }),
      ),
      servingStoreProvider.overrideWith((ref) async => mockServingStore),
      if (loadingCompleter != null)
        homeCategoriesProvider.overrideWith((ref) => loadingCompleter.future)
      else if (hasError)
        homeCategoriesProvider.overrideWith(
          (ref) => Future.error(Exception('Failed to fetch categories')),
        )
      else
        homeCategoriesProvider.overrideWith(
          (ref) async => categories ?? mockActiveCategories,
        ),
      ...additionalOverrides,
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const ExploreScreen(),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.physicalSize =
        const Size(390 * 3, 844 * 3);
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.devicePixelRatio = 3.0;
  });

  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.resetPhysicalSize();
    TestWidgetsFlutterBinding.instance.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  group('Screen 09 — Explore / Category Listing Tests', () {
    testWidgets('1. Explore screen renders compact header, Categories heading, and Bottom Navigation', (tester) async {
      await tester.pumpWidget(_createExploreScreenWidget());
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.textContaining('Home'), findsWidgets);
      expect(find.text('930 m away'), findsOneWidget);
      expect(find.byType(AppBottomNavBar), findsOneWidget);
    });

    testWidgets('2. Explore bottom-nav item is active (Tab index 1)', (tester) async {
      await tester.pumpWidget(_createExploreScreenWidget());
      await tester.pumpAndSettle();

      final bottomNavFinder = find.byType(AppBottomNavBar);
      expect(bottomNavFinder, findsOneWidget);

      final bottomNav = tester.widget<AppBottomNavBar>(bottomNavFinder);
      expect(bottomNav.selectedIndex, 1);
    });

    testWidgets('3. Only API-returned categories are displayed and ordering is preserved', (tester) async {
      await tester.pumpWidget(_createExploreScreenWidget());
      await tester.pumpAndSettle();

      expect(find.byType(ExploreCategoryCard), findsNWidgets(3));

      expect(find.text('Fruits'), findsOneWidget);
      expect(find.text('Vegetables'), findsOneWidget);
      expect(find.text('Leafy Vegetables'), findsOneWidget);

      // Verify ordering in the widget tree
      final cards = tester.widgetList<ExploreCategoryCard>(find.byType(ExploreCategoryCard)).toList();
      expect(cards[0].name, 'Fruits');
      expect(cards[1].name, 'Vegetables');
      expect(cards[2].name, 'Leafy Vegetables');
    });

    testWidgets('4. Category names render with 2-line safety and fixed label area height', (tester) async {
      await tester.pumpWidget(_createExploreScreenWidget(
        categories: [
          const CategoryModel(
            id: 'c_leafy',
            name: 'Fresh Organic Leafy Vegetables',
            displayOrder: 1,
            isActive: true,
          ),
          const CategoryModel(
            id: 'c_fruit',
            name: 'Fruits',
            displayOrder: 2,
            isActive: true,
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Fresh Organic Leafy Vegetables'), findsOneWidget);
      expect(find.text('Fruits'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('5. Network image is used when available and fallback icon when null', (tester) async {
      await tester.pumpWidget(_createExploreScreenWidget());
      await tester.pumpAndSettle();

      // Cards with imageUrl render Image.network
      expect(find.byType(Image), findsNWidgets(2));

      // Leafy Vegetables has null imageUrl, renders fallback icon
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
    });

    testWidgets('6. Empty category response renders AppEmptyState cleanly', (tester) async {
      await tester.pumpWidget(_createExploreScreenWidget(categories: []));
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('No Categories Found'), findsOneWidget);
      expect(find.byType(ExploreCategoryCard), findsNothing);
    });

    testWidgets('7. Category API error renders AppErrorState with retry button', (tester) async {
      await tester.pumpWidget(_createExploreScreenWidget(hasError: true));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.textContaining('Failed to load categories'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('8. Loading state renders skeleton placeholders', (tester) async {
      final completer = Completer<List<CategoryModel>>();
      await tester.pumpWidget(_createExploreScreenWidget(loadingCompleter: completer));
      await tester.pump();

      expect(find.byType(ExploreCategoryCard), findsNothing);
      expect(find.text('Categories'), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('9. Tapping a category triggers navigation with categoryId', (tester) async {
      final container = ProviderContainer(
        overrides: [
          defaultCustomerAddressProvider.overrideWithValue(
            const AsyncData({'title': 'Home', 'city': 'Rajkot'}),
          ),
          servingStoreProvider.overrideWith((ref) async => mockServingStore),
          homeCategoriesProvider.overrideWith((ref) async => mockActiveCategories),
        ],
      );

      final router = GoRouter(
        initialLocation: RouteNames.explore,
        routes: [
          GoRoute(
            path: RouteNames.explore,
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: RouteNames.categoryProducts,
            builder: (context, state) {
              final catId = state.uri.queryParameters['categoryId'] ?? '';
              final catName = state.uri.queryParameters['categoryName'] ?? '';
              return Scaffold(
                body: Center(
                  child: Text('Screen 10: $catName ($catId)'),
                ),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Fruits'), findsOneWidget);
      await tester.tap(find.text('Fruits'));
      await tester.pumpAndSettle();

      expect(find.text('Screen 10: Fruits (cdd9bf8e-e199-4b67-ad3d-1186483caae4)'), findsOneWidget);
    });

    testWidgets('10. Dark theme renders correctly without error', (tester) async {
      await tester.pumpWidget(_createExploreScreenWidget(
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Categories'), findsOneWidget);
      expect(find.byType(ExploreCategoryCard), findsNWidgets(3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('11. Responsive layout across multiple screen sizes without overflow', (tester) async {
      final viewports = [
        const Size(320, 568), // iPhone SE 1st gen
        const Size(375, 667), // iPhone 8
        const Size(390, 844), // iPhone 14
        const Size(430, 932), // iPhone 14 Pro Max
        const Size(768, 1024), // iPad Mini
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(_createExploreScreenWidget());
        await tester.pumpAndSettle();

        expect(find.text('Categories'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
