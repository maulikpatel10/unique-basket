import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/features/home/data/models/banner_model.dart';
import 'package:customer_app/features/home/data/models/category_model.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/features/home/data/repositories/home_repository.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/search/presentation/providers/search_provider.dart';
import 'package:customer_app/features/search/presentation/screens/search_screen.dart';
import 'package:customer_app/features/search/presentation/widgets/search_no_results_card.dart';
import 'package:customer_app/features/search/presentation/widgets/search_query_suggestion_item.dart';
import 'package:customer_app/features/search/presentation/widgets/search_suggestion_row.dart';
import 'package:customer_app/features/store/data/models/store_model.dart';
import 'package:customer_app/features/store/presentation/providers/store_provider.dart';
import 'package:customer_app/shared/widgets/app_product_card.dart';
import 'package:customer_app/shared/widgets/checkout_bar.dart';

const _mockCategories = [
  CategoryModel(
    id: 'cat_fruits',
    name: 'Fresh Fruits',
    imageUrl: 'https://example.com/fruits.png',
    isActive: true,
  ),
  CategoryModel(
    id: 'cat_vegetables',
    name: 'Fresh Vegetables',
    imageUrl: 'https://example.com/veggies.png',
    isActive: true,
  ),
];

const _mockProducts = [
  ProductModel(
    id: 'p_apple_gala',
    categoryId: 'cat_fruits',
    categoryName: 'Fresh Fruits',
    name: 'Apple — Fresh Royal Gala',
    description: 'Crisp and sweet fresh Gala apples',
    price: 140.0,
    mrp: 180.0,
    unit: '1 kg',
    stockQuantity: 15.0,
    isAvailable: true,
    isActive: true,
  ),
  ProductModel(
    id: 'p_banana',
    categoryId: 'cat_fruits',
    categoryName: 'Fresh Fruits',
    name: 'Fresh Robusta Bananas',
    description: 'Naturally ripened sweet bananas',
    price: 50.0,
    mrp: 60.0,
    unit: '1 Dozen',
    stockQuantity: 20.0,
    isAvailable: true,
    isActive: true,
  ),
  ProductModel(
    id: 'p_spinach',
    categoryId: 'cat_vegetables',
    categoryName: 'Fresh Vegetables',
    name: 'Green Baby Spinach',
    description: 'Fresh organic leafy green spinach',
    price: 35.0,
    mrp: 45.0,
    unit: '250g',
    stockQuantity: 10.0,
    isAvailable: true,
    isActive: true,
  ),
  ProductModel(
    id: 'p_out_of_stock',
    categoryId: 'cat_fruits',
    categoryName: 'Fresh Fruits',
    name: 'Rare Organic Blueberries',
    description: 'Imported fresh organic blueberries',
    price: 399.0,
    mrp: 450.0,
    unit: '125g',
    stockQuantity: 0.0,
    isAvailable: false,
    isActive: true,
  ),
];

class _MockSearchRepo implements HomeRepository {
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  _MockSearchRepo() : categories = _mockCategories, products = _mockProducts;

  @override
  Future<List<CategoryModel>> getCategories() async => categories;

  @override
  Future<List<ProductModel>> getFeaturedProducts() async => products;

  @override
  Future<List<ProductModel>> getStoreProducts(String storeId, {String? categoryId}) async {
    if (categoryId != null && categoryId.isNotEmpty) {
      return products.where((p) => p.categoryId == categoryId).toList();
    }
    return products;
  }

  @override
  Future<List<BannerModel>> getBanners() async => [];
}

Widget _buildSearchTestWidget({
  required LocalStorageService localStorage,
  String? initialQuery,
  Map<String, int>? initialCart,
  GoRouter? router,
}) {
  final container = ProviderContainer(
    overrides: [
      localStorageProvider.overrideWithValue(localStorage),
      homeRepositoryProvider.overrideWithValue(_MockSearchRepo()),
      servingStoreProvider.overrideWith(
        (ref) async => const StoreModel(
          id: 'store_1',
          storeId: 'UB-RAJKOT-01',
          name: 'Unique Basket Main',
          address: 'Kalawad Road',
          city: 'Rajkot',
          state: 'Gujarat',
          pincode: '360005',
          latitude: 22.3039,
          longitude: 70.8022,
          phone: '+919876543210',
          openingTime: '07:00 AM',
          closingTime: '10:00 PM',
          distanceKm: 0.93,
        ),
      ),
    ],
  );

  if (initialCart != null) {
    for (final entry in initialCart.entries) {
      for (int i = 0; i < entry.value; i++) {
        container.read(cartNotifierProvider.notifier).increment(entry.key);
      }
    }
  }

  if (router != null) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        theme: AppTheme.lightTheme,
        routerConfig: router,
      ),
    );
  }

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: SearchScreen(initialQuery: initialQuery),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    AppConfig.initialize(
      appName: 'Unique Basket',
      environment: Environment.development,
    );
  });

  group('Global Search Edge Cases & Rapid Actions', () {
    testWidgets('1. Empty query submission with whitespace does not transition to results or crash',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, '     ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Should remain on initial empty search state with popular searches
      expect(find.text('POPULAR SEARCHES'), findsOneWidget);
      expect(find.byType(SearchNoResultsCard), findsNothing);
      expect(find.byType(AppProductCard), findsNothing);
    });

    testWidgets('2. One-character query triggers suggestions without submitting',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'a');
      await tester.pumpAndSettle();

      // Live suggestion view (Screen 17)
      expect(find.text('PRODUCT MATCHES'), findsOneWidget);
      expect(find.byType(SearchSuggestionRow), findsWidgets);
      // Results grid must NOT be rendered yet
      expect(find.textContaining('Showing'), findsNothing);
    });

    testWidgets('3. Query with leading and trailing whitespace filters correctly on submit',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, '   banana   ');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Should display Bananas in Results grid
      expect(find.textContaining('Showing'), findsOneWidget);
      expect(find.text('Fresh Robusta Bananas'), findsOneWidget);
    });

    testWidgets('4. Case-insensitive and mixed-case search works identically',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'sPiNaCh');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.textContaining('Showing'), findsOneWidget);
      expect(find.text('Green Baby Spinach'), findsOneWidget);
    });

    testWidgets('5. Long non-matching query transitions safely to SearchNoResultsCard without crashing',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'xyz123_nonexistent_long_query_!@#\$%^&*()');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.byType(SearchNoResultsCard), findsOneWidget);
      expect(find.text('No products found'), findsOneWidget);
      expect(find.text('Search Again'), findsOneWidget);
    });

    testWidgets('6. Recent searches: adding, deduplicating, and deleting individual items',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      // Submit search for "apple"
      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'apple');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Clear search to return to empty state
      final clearBtn = find.byKey(const Key('search_clear_button'));
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // Verify "apple" appears in recent searches
      expect(find.text('apple'), findsOneWidget);

      // Submit "apple" again (test deduplication)
      await tester.enterText(searchInput, 'apple');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // "apple" should appear exactly once in recent searches
      expect(find.text('apple'), findsOneWidget);

      // Submit another term "spinach"
      await tester.enterText(searchInput, 'spinach');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      expect(find.text('spinach'), findsOneWidget);
      expect(find.text('apple'), findsOneWidget);

      // Test Clear All recent searches
      final clearAllBtn = find.text('Clear All');
      expect(clearAllBtn, findsOneWidget);
      await tester.tap(clearAllBtn);
      await tester.pumpAndSettle();

      // Recent searches section should now be hidden/empty
      expect(find.text('RECENT SEARCHES'), findsNothing);
      expect(find.text('Clear All'), findsNothing);
      expect(find.text('POPULAR SEARCHES'), findsOneWidget);
    });

    testWidgets('7. Rapid consecutive submit actions do not crash or corrupt results state',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'apple');

      // Rapidly fire multiple search actions
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.textContaining('Showing'), findsOneWidget);
      expect(find.byType(AppProductCard), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('8. Rapid double-tap on suggestion item safely submits without duplicate routing',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(
        localStorage: localStorage,
        initialQuery: 'apple',
      ));
      await tester.pumpAndSettle();

      final suggestionItem = find.byType(SearchQuerySuggestionItem).first;
      expect(suggestionItem, findsOneWidget);

      // Rapid double tap
      await tester.tap(suggestionItem);
      await tester.tap(suggestionItem);
      await tester.pumpAndSettle();

      expect(find.textContaining('Showing'), findsOneWidget);
      expect(find.byType(AppProductCard), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('9. Product match suggestion row does not add item to cart or mutate cart state',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(
        localStorage: localStorage,
        initialQuery: 'banana',
      ));
      await tester.pumpAndSettle();

      final suggestionRow = find.byType(SearchSuggestionRow).first;
      expect(suggestionRow, findsOneWidget);

      await tester.tap(suggestionRow);
      await tester.pumpAndSettle();

      // Results should be displayed, but checkout bar must remain hidden (0 cart items)
      expect(find.textContaining('Showing'), findsOneWidget);
      expect(find.byType(CheckoutBar), findsNothing);
    });

    testWidgets('10. In results state, tapping Add on AppProductCard updates cart and shows CheckoutBar',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'apple');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(find.byType(AppProductCard), findsOneWidget);
      expect(find.byType(CheckoutBar), findsNothing);

      // Tap Add button on the result card
      final addBtn = find.byIcon(Icons.add_rounded);
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // CheckoutBar should now appear
      expect(find.byType(CheckoutBar), findsOneWidget);
      expect(find.text('1 Product'), findsOneWidget);
    });

    testWidgets('11. In results state, category filter chips filter results and preserve query',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      // Submit search for a general keyword matching both fruits and vegetables
      final searchInput = find.byType(TextField);
      await tester.enterText(searchInput, 'fresh');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      // Verify category chips exist
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Fresh Fruits'), findsOneWidget);
      expect(find.text('Fresh Vegetables'), findsOneWidget);

      // Tap 'All' category chip
      await tester.tap(find.text('All'), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Query in search bar is preserved
      final currentInput = tester.widget<TextField>(find.byType(TextField));
      expect(currentInput.controller?.text, equals('fresh'));
    });

    testWidgets('12. Back button when search field is focused unfocuses keyboard first without popping screen',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      final searchInputFinder = find.byType(TextField);
      await tester.tap(searchInputFinder);
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(searchInputFinder);
      expect(textField.focusNode?.hasFocus, isTrue);

      // Tap header back button while focused
      final backBtn = find.byKey(const Key('search_back_button'));
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Keyboard is unfocused, screen remains on SearchScreen
      expect(textField.focusNode?.hasFocus, isFalse);
      expect(find.byType(SearchScreen), findsOneWidget);
    });

    testWidgets('13. Popular Searches maintains identical horizontal left coordinate with and without Recent Searches',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'ub_customer_recent_searches': ['Apple (Shimla)'],
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      // With Recent Searches
      expect(find.text('RECENT SEARCHES'), findsOneWidget);
      expect(find.text('POPULAR SEARCHES'), findsOneWidget);

      final popularHeaderWithRecent = tester.getTopLeft(find.text('POPULAR SEARCHES'));
      final freshApplesWithRecent = tester.getTopLeft(find.widgetWithText(ActionChip, 'Fresh Apples'));

      // Clear all recent searches
      await tester.tap(find.text('Clear All'));
      await tester.pumpAndSettle();

      expect(find.text('RECENT SEARCHES'), findsNothing);
      expect(find.text('POPULAR SEARCHES'), findsOneWidget);

      final popularHeaderWithoutRecent = tester.getTopLeft(find.text('POPULAR SEARCHES'));
      final freshApplesWithoutRecent = tester.getTopLeft(find.widgetWithText(ActionChip, 'Fresh Apples'));

      // Horizontal coordinate dx MUST be strictly identical
      expect(popularHeaderWithRecent.dx, equals(16.0));
      expect(popularHeaderWithoutRecent.dx, equals(popularHeaderWithRecent.dx));
      expect(freshApplesWithoutRecent.dx, equals(freshApplesWithRecent.dx));
    });

    testWidgets('14. Recent searches enforces maximum of 5 items and newest-first order',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
        ],
      );

      final notifier = container.read(recentSearchesProvider.notifier);

      // Add 6 distinct searches
      notifier.addSearch('Item 1');
      notifier.addSearch('Item 2');
      notifier.addSearch('Item 3');
      notifier.addSearch('Item 4');
      notifier.addSearch('Item 5');
      notifier.addSearch('Item 6');

      final list = container.read(recentSearchesProvider);
      expect(list.length, equals(5));
      expect(list.first, equals('Item 6'));
      expect(list.contains('Item 1'), isFalse); // Oldest removed
      expect(list, equals(['Item 6', 'Item 5', 'Item 4', 'Item 3', 'Item 2']));
    });

    testWidgets('15. Repeated search moves existing term to top without duplicate',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'ub_customer_recent_searches': ['Apple', 'Banana', 'Mango', 'Potato'],
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(localStorage),
        ],
      );

      final notifier = container.read(recentSearchesProvider.notifier);
      notifier.addSearch('Banana');

      final list = container.read(recentSearchesProvider);
      expect(list.length, equals(4));
      expect(list.first, equals('Banana'));
      expect(list, equals(['Banana', 'Apple', 'Mango', 'Potato']));
    });

    testWidgets('16. Individual recent-search delete icon removes only targeted item',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'ub_customer_recent_searches': ['Apples', 'Oranges'],
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      expect(find.text('Apples'), findsOneWidget);
      expect(find.text('Oranges'), findsOneWidget);

      // Find delete icon for 'Apples'
      final deleteApples = find.descendant(
        of: find.widgetWithText(InputChip, 'Apples'),
        matching: find.byIcon(Icons.close_rounded),
      );
      await tester.tap(deleteApples);
      await tester.pumpAndSettle();

      expect(find.text('Apples'), findsNothing);
      expect(find.text('Oranges'), findsOneWidget);
    });

    testWidgets('17. Long search query in recent searches renders without RenderFlex overflow',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'ub_customer_recent_searches': [
          'Extremely Long Fresh Organic Farm Product Query For Testing Layout Stability',
        ],
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(320 * 2, 568 * 2); // Small device
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildSearchTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Extremely Long'), findsOneWidget);
    });
  });
}
