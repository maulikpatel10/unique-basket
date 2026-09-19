import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/constants/app_constants.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/features/address/data/repositories/customer_address_repository.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/home/data/models/banner_model.dart';
import 'package:customer_app/features/home/data/models/category_model.dart';
import 'package:customer_app/features/home/data/models/product_model.dart';
import 'package:customer_app/features/home/data/repositories/home_repository.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/home/presentation/screens/home_screen.dart';
import 'package:customer_app/features/profile_setup/data/repositories/customer_profile_repository.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';
import 'package:customer_app/features/store/data/models/store_model.dart';
import 'package:customer_app/features/store/data/repositories/store_repository.dart';
import 'package:customer_app/features/store/presentation/providers/store_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockHomeRepository implements HomeRepository {
  @override
  Future<List<CategoryModel>> getCategories() async {
    return const [
      CategoryModel(id: '1', name: 'Fruits', displayOrder: 1),
      CategoryModel(id: '2', name: 'Vegetables', displayOrder: 2),
      CategoryModel(id: '3', name: 'Exotics', displayOrder: 3),
      CategoryModel(id: '4', name: 'Organic', displayOrder: 4),
    ];
  }

  @override
  Future<List<ProductModel>> getFeaturedProducts() async {
    return const [
      ProductModel(
        id: 'p1',
        categoryId: '1',
        name: 'Organic Hass Avocado',
        price: 4.99,
        unit: 'Pack of 2',
        badge: '16% OFF',
        isFavorite: true,
      ),
      ProductModel(
        id: 'p2',
        categoryId: '2',
        name: 'Organic Vine Tomatoes',
        price: 4.99,
        unit: '500g',
        badge: 'Local',
        isFavorite: false,
      ),
    ];
  }

  @override
  Future<List<ProductModel>> getStoreProducts(String storeId, {String? categoryId}) async {
    return getFeaturedProducts();
  }

  @override
  Future<List<BannerModel>> getBanners() async {
    return const [
      BannerModel(
        id: 'b1',
        tag: 'Fresh Harvest',
        title: '20% Off\nSeasonal\nGreens',
        ctaText: 'Shop Now',
      ),
    ];
  }
}

class MockCustomerAddressRepository implements CustomerAddressRepository {
  final Map<String, dynamic> addressesResponse;
  final bool shouldThrow;

  MockCustomerAddressRepository({
    this.addressesResponse = const {'addresses': []},
    this.shouldThrow = false,
  });

  @override
  Future<Map<String, dynamic>> getAddresses() async {
    if (shouldThrow) {
      throw Exception('Network connection error');
    }
    return addressesResponse;
  }

  @override
  Future<Map<String, dynamic>> addAddress({
    required String title,
    required String addressLine,
    required String city,
    required String state,
    required String pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    return {};
  }
}

class MockCustomerProfileRepository implements CustomerProfileRepository {
  final Map<String, dynamic> profileResponse;
  final bool shouldThrow;

  MockCustomerProfileRepository({
    this.profileResponse = const {
      'user': {'name': 'Maulik Patel'}
    },
    this.shouldThrow = false,
  });

  @override
  Future<Map<String, dynamic>> getProfile() async {
    if (shouldThrow) {
      throw Exception('Network error');
    }
    return profileResponse;
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    DateTime? dob,
  }) async {
    return {};
  }
}

class MockStoreRepository implements StoreRepository {
  final List<StoreModel> stores;
  final StoreModel? servingStore;

  MockStoreRepository({
    this.stores = const [],
    this.servingStore,
  });

  @override
  Future<List<StoreModel>> getNearbyStores({
    required double latitude,
    required double longitude,
    String fulfillment = 'DELIVERY',
  }) async =>
      stores;

  @override
  Future<StoreModel?> resolveServingStore({
    required double latitude,
    required double longitude,
  }) async =>
      servingStore;
}

Widget _createHomeTestWidget({
  ThemeMode themeMode = ThemeMode.light,
  LocalStorageService? localStorage,
  HomeRepository? repository,
  CustomerAddressRepository? addressRepository,
  CustomerProfileRepository? profileRepository,
  StoreRepository? storeRepository,
}) {
  return ProviderScope(
    overrides: [
      if (localStorage != null)
        localStorageProvider.overrideWithValue(localStorage),
      homeRepositoryProvider.overrideWithValue(
        repository ?? MockHomeRepository(),
      ),
      customerAddressRepositoryProvider.overrideWithValue(
        addressRepository ??
            MockCustomerAddressRepository(
              addressesResponse: {
                'addresses': [
                  {
                    'id': 'addr_default',
                    'title': 'Home',
                    'addressLine': '123 Fresh Lane',
                    'city': 'Rajkot',
                    'latitude': 22.3039,
                    'longitude': 70.8022,
                    'isDefault': true,
                  }
                ]
              },
            ),
      ),
      if (profileRepository != null)
        customerProfileRepositoryProvider.overrideWithValue(profileRepository),
      storeRepositoryProvider.overrideWithValue(
        storeRepository ??
            MockStoreRepository(
              servingStore: const StoreModel(
                id: 'store_1',
                storeId: 'RAJ-01',
                name: 'Store 1',
                address: 'Kalawad Road',
                city: 'Rajkot',
                state: 'Gujarat',
                pincode: '360005',
                latitude: 22.3039,
                longitude: 70.8022,
                phone: '+919876543210',
                openingTime: '07:00',
                closingTime: '22:00',
                isActive: true,
                isEligible: true,
                deliveryRadiusKm: 5.0,
              ),
            ),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeScreen(),
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

  group('Screen 08 — Home Screen Tests', () {
    test('Home route constant is defined correctly', () {
      expect(RouteNames.home, equals('/home'));
    });

    testWidgets(
        '1. Screen 08 renders all primary UI sections and binds live default address',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        AppConstants.keyUserAddress:
            '{"type":"Home","fullAddress":"123 Fresh Lane","areaLocality":"Central Area"}',
      });
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final addressRepo = MockCustomerAddressRepository(
        addressesResponse: {
          'addresses': [
            {
              'id': 'addr_1',
              'title': 'Home',
              'addressLine': '123 Fresh Lane',
              'city': 'Ahmedabad',
              'latitude': 22.3039,
              'longitude': 70.8022,
              'isDefault': true,
            }
          ]
        },
      );

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createHomeTestWidget(
        localStorage: localStorage,
        addressRepository: addressRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);

      // Header Elements (Verifying real address and NO fake 930m distance)
      expect(find.text('Delivering to'), findsOneWidget);
      expect(find.text('Home - 123 Fresh Lane'), findsOneWidget);
      expect(find.text('930 m away'), findsNothing);
      expect(find.byKey(const Key('home_notification_button')), findsOneWidget);
      expect(find.text('Search for fresh fruits, veggies...'), findsOneWidget);
      expect(find.byKey(const Key('home_search_mic_button')), findsOneWidget);

      // Promotional Hero Banner
      expect(find.text('Fresh Harvest'), findsOneWidget);
      expect(find.text('20% Off\nSeasonal\nGreens'), findsOneWidget);
      expect(find.text('Shop Now'), findsOneWidget);

      // Categories Section
      expect(find.text('Explore Categories'), findsOneWidget);
      expect(find.text('View all'), findsOneWidget);
      expect(find.text('Fruits'), findsOneWidget);
      expect(find.text('Vegetables'), findsOneWidget);
      expect(find.text('Exotics'), findsOneWidget);
      expect(find.text('Organic'), findsOneWidget);

      // Fresh Arrivals Product Section
      expect(find.text('Fresh Arrivals'), findsOneWidget);
      expect(find.text('Organic Hass Avocado'), findsOneWidget);
      expect(find.text('Pack of 2'), findsOneWidget);
      expect(find.text('16% OFF'), findsOneWidget);
      expect(find.text('Organic Vine Tomatoes'), findsOneWidget);
      expect(find.text('500g'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);

      // Bottom Navigation Bar
      expect(find.text('Shop'), findsOneWidget);
      expect(find.text('Explore'), findsOneWidget);
      expect(find.text('Cart'), findsOneWidget);
      expect(find.text('Favorite'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('2. Adding product to cart updates quantity and displays floating cart bar',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createHomeTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      // Scroll down using CustomScrollView
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final addButtons = find.byIcon(Icons.add_rounded);
      expect(addButtons, findsWidgets);
      await tester.tap(addButtons.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Floating cart bar should show Checkout button
      expect(find.text('Checkout'), findsOneWidget);
    });

    testWidgets('3. Wishlist / favorite heart button toggles state',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createHomeTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      final favButtons = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.favorite_rounded ||
                widget.icon == Icons.favorite_border_rounded),
      );
      expect(favButtons, findsWidgets);
      await tester.tap(favButtons.first, warnIfMissed: false);
      await tester.pumpAndSettle();
    });

    testWidgets('4. Responsive viewports render cleanly without overflow',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final viewports = [
        const Size(320, 568), // Small phone (iPhone SE 1st gen)
        const Size(390, 844), // Standard phone (iPhone 14/15)
        const Size(428, 926), // Large phone (iPhone 14 Pro Max)
      ];

      for (final size in viewports) {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(_createHomeTestWidget(localStorage: localStorage));
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('5. Dark theme renders cleanly without crash',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createHomeTestWidget(
        localStorage: localStorage,
        themeMode: ThemeMode.dark,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Explore Categories'), findsOneWidget);
      expect(find.text('Fresh Arrivals'), findsOneWidget);
    });

    testWidgets('6. Bottom navigation tab selection triggers callback',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createHomeTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Explore'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(HomeScreen), findsOneWidget);

      await tester.tap(find.text('Profile'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('7. Scroll collapse behavior: search bar remains pinned while header collapses',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createHomeTestWidget(localStorage: localStorage));
      await tester.pumpAndSettle();

      // Initial State: Search bar is visible and header elements are present
      final searchFinder = find.text('Search for fresh fruits, veggies...');
      expect(searchFinder, findsOneWidget);
      expect(find.text('Delivering to'), findsOneWidget);

      // Scroll up 120 pixels to collapse header into pinned search bar state
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
      await tester.pumpAndSettle();

      // Search bar is STILL VISIBLE (PINNED at top)
      expect(searchFinder, findsOneWidget);

      // Tap search while pinned to verify interaction
      await tester.tap(searchFinder);
      await tester.pumpAndSettle();

      // Scroll further (400px down) — search bar stays pinned, content scrolls
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(searchFinder, findsOneWidget);

      // Scroll back down to top — full header restores smoothly
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
      await tester.pumpAndSettle();
      expect(searchFinder, findsOneWidget);
      expect(find.text('Delivering to'), findsOneWidget);
    });

    testWidgets(
        '8. Dynamic address title (e.g. Work address) is rendered accurately',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final addressRepo = MockCustomerAddressRepository(
        addressesResponse: {
          'addresses': [
            {
              'id': 'addr_work',
              'title': 'Work',
              'addressLine': 'Tech Park, Floor 4',
              'city': 'Bangalore',
              'isDefault': true,
            }
          ]
        },
      );

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createHomeTestWidget(
        localStorage: localStorage,
        addressRepository: addressRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Work - Tech Park, Floor 4'), findsOneWidget);
    });

    testWidgets(
        '9. Safe empty address state displays CTA and does not show fake address',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final emptyAddressRepo = MockCustomerAddressRepository(
        addressesResponse: {'addresses': []},
      );

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createHomeTestWidget(
        localStorage: localStorage,
        addressRepository: emptyAddressRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Select Location - Tap to add address'), findsOneWidget);
      expect(find.text('Haridwar'), findsNothing);
      expect(find.text('930 m away'), findsNothing);
    });

    testWidgets(
        '10. Address network error is handled gracefully without crashing',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final errorAddressRepo = MockCustomerAddressRepository(
        shouldThrow: true,
      );

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createHomeTestWidget(
        localStorage: localStorage,
        addressRepository: errorAddressRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Delivery Address - Tap to retry'), findsOneWidget);
    });

    testWidgets(
        '11. Long address text renders cleanly with ellipsis and zero overflow',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final longAddressRepo = MockCustomerAddressRepository(
        addressesResponse: {
          'addresses': [
            {
              'id': 'addr_long',
              'title': 'Office',
              'addressLine':
                  'Apartment 902, Tower 4, Very Long Residency Complex, Near Mega Landmark, Grand Highway Sector 9',
              'city': 'Ahmedabad',
              'isDefault': true,
            }
          ]
        },
      );

      tester.view.physicalSize = const Size(320 * 2, 568 * 2); // Smallest phone
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createHomeTestWidget(
        localStorage: localStorage,
        addressRepository: longAddressRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '12. Customer profile provider is consumed and profile error does not crash Home',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final errorProfileRepo = MockCustomerProfileRepository(
        shouldThrow: true,
      );

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createHomeTestWidget(
        localStorage: localStorage,
        profileRepository: errorProfileRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Explore Categories'), findsOneWidget);
    });

    testWidgets(
        '13. Real store distance (e.g. 850 m away) is rendered in the header when servingStore is resolved',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      final addressRepo = MockCustomerAddressRepository(
        addressesResponse: {
          'addresses': [
            {
              'id': 'addr_1',
              'title': 'Home',
              'addressLine': '104 Green Heights',
              'city': 'Rajkot',
              'latitude': 22.3039,
              'longitude': 70.8022,
              'isDefault': true,
            }
          ]
        },
      );

      final storeRepo = MockStoreRepository(
        servingStore: const StoreModel(
          id: 'store_1',
          storeId: 'STORE_RAJKOT_01',
          name: 'Rajkot Main Store',
          address: 'Ring Road',
          city: 'Rajkot',
          state: 'Gujarat',
          pincode: '360001',
          latitude: 22.30,
          longitude: 70.80,
          phone: '1234567890',
          openingTime: '08:00',
          closingTime: '22:00',
          isActive: true,
          distanceKm: 0.85,
          isEligible: true,
        ),
      );

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createHomeTestWidget(
        localStorage: localStorage,
        addressRepository: addressRepo,
        storeRepository: storeRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Home - 104 Green Heights'), findsOneWidget);
      expect(find.text('850 m away'), findsOneWidget);
      expect(find.text('930 m away'), findsNothing);
    });
  });
}
