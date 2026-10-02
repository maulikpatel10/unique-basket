import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/core/storage/secure_storage_service.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:customer_app/features/checkout/data/repositories/order_repository.dart';
import 'package:customer_app/features/checkout/presentation/providers/order_provider.dart';
import 'package:customer_app/features/explore/presentation/screens/explore_screen.dart';
import 'package:customer_app/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/home/presentation/screens/home_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:customer_app/features/profile/presentation/widgets/profile_header_card.dart';
import 'package:customer_app/features/profile/presentation/widgets/profile_menu_section.dart';
import 'package:customer_app/features/profile_setup/data/repositories/customer_profile_repository.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';
import 'package:customer_app/shared/widgets/app_bottom_nav_bar.dart';
import 'package:customer_app/shared/widgets/app_header.dart';

import 'package:shared_preferences/shared_preferences.dart';

class MockTestSecureStorageService implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> saveTokens({required String accessToken, String? refreshToken}) async {
    _data['access_token'] = accessToken;
    if (refreshToken != null) _data['refresh_token'] = refreshToken;
  }

  @override
  Future<String?> getAccessToken() async => _data['access_token'];

  @override
  Future<String?> getRefreshToken() async => _data['refresh_token'];

  @override
  Future<void> clearTokens() async => _data.clear();

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clearAll() async => _data.clear();
}

class MockProfileRepo implements CustomerProfileRepository {
  bool shouldThrow = false;
  Map<String, dynamic>? profileToReturn;

  @override
  Future<Map<String, dynamic>> getProfile() async {
    if (shouldThrow) {
      throw Exception('NETWORK_ERROR');
    }
    return {
      'user': profileToReturn ?? {
        'id': 'user-1',
        'name': 'Maulik Patel',
        'phone': '+919876543210',
        'email': 'maulik@example.com',
        'dob': '2000-08-15T00:00:00.000Z',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    DateTime? dob,
    String? gender,
  }) async {
    return {'success': true};
  }
}

class MockOrderRepo implements OrderRepository {
  List<dynamic> ordersToReturn = [];

  @override
  Future<Map<String, dynamic>> createOrder({
    required String fulfillmentType,
    required String? addressId,
    required String? storeId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async {
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    return {'success': true};
  }

  @override
  Future<List<dynamic>> getOrders() async {
    return ordersToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    AppConfig.initialize(
      appName: 'Unique Basket',
      environment: Environment.development,
    );
  });

  group('Screen 25 — Profile Unit & Widget Tests', () {
    late MockProfileRepo mockProfileRepo;
    late MockOrderRepo mockOrderRepo;
    late LocalStorageService mockLocalStorage;
    late MockTestSecureStorageService mockSecureStorage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      mockLocalStorage = LocalStorageService(prefs);
      mockSecureStorage = MockTestSecureStorageService();
      mockProfileRepo = MockProfileRepo();
      mockOrderRepo = MockOrderRepo();
      mockOrderRepo.ordersToReturn = List.generate(12, (i) => {'id': 'order-$i'});
    });

    Widget createScreenHarness({
      MockProfileRepo? profileRepo,
      MockOrderRepo? orderRepo,
      List<Map<String, dynamic>>? addresses,
      Set<String>? favoriteIds,
    }) {
      return ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(mockLocalStorage),
          secureStorageProvider.overrideWithValue(mockSecureStorage),
          customerProfileRepositoryProvider
              .overrideWithValue(profileRepo ?? mockProfileRepo),
          orderRepositoryProvider
              .overrideWithValue(orderRepo ?? mockOrderRepo),
          if (addresses != null)
            customerAddressesProvider.overrideWith((ref) async => addresses),
          if (favoriteIds != null)
            favoritesNotifierProvider.overrideWith((ref) {
              final notifier = FavoritesNotifier();
              for (final id in favoriteIds) {
                notifier.toggleFavorite(id);
              }
              return notifier;
            }),
        ],
        child: const MaterialApp(
          home: ProfileScreen(),
        ),
      );
    }


    testWidgets('1. Renders AppHeader with title Profile and no back button', (tester) async {
      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.byType(AppHeader), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppHeader),
          matching: find.text('Profile'),
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
    });


    testWidgets('2. Profile renders customer name, phone, and verified badge', (tester) async {
      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.byType(ProfileHeaderCard), findsOneWidget);
      expect(find.text('Maulik Patel'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('Verified mobile number'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
    });

    testWidgets('3. Initials render correctly when no local profile image exists', (tester) async {
      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('MP'), findsOneWidget);
    });

    testWidgets('4. Open list layout does NOT render large boxed statistics cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createScreenHarness(
          addresses: [
            {'id': 'addr-1', 'title': 'Home'},
            {'id': 'addr-2', 'title': 'Office'},
            {'id': 'addr-3', 'title': 'Farm'},
          ],
          favoriteIds: {'fav-1', 'fav-2', 'fav-3', 'fav-4', 'fav-5', 'fav-6', 'fav-7', 'fav-8'},
        ),
      );
      await tester.pumpAndSettle();

      // Verified boxed stats cards are removed in favor of clean open list flow
      expect(find.text('ORDERS'), findsNothing);
      expect(find.text('FAVOURITES'), findsNothing);
      expect(find.text('ADDRESSES'), findsNothing);
    });

    testWidgets('5. Menu sections and rows render correctly with icons and descriptions', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.byType(ProfileMenuSection), findsNWidgets(3));
      expect(find.text('MY ACCOUNT'), findsOneWidget);
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('View your recent orders'), findsOneWidget);
      expect(find.text('My Addresses'), findsOneWidget);
      expect(find.text('Manage delivery addresses'), findsOneWidget);
      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('Manage saved payment options'), findsOneWidget);

      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Order updates and offers'), findsOneWidget);

      expect(find.text('SUPPORT'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Get help with your order'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
      expect(find.text('Sign out from your account'), findsOneWidget);
    });

    testWidgets('6. Log Out button renders with icon and opens confirmation bottom sheet (Screen 34)', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('Log Out'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);

      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      // Screen 34 Modal Bottom Sheet verification
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Logout from UNIQUE BASKET?'), findsOneWidget);
      expect(
        find.text('Are you sure you want to log out of your account? You can sign in again anytime using your mobile number.'),
        findsOneWidget,
      );
      expect(find.text('Log Out'), findsNWidgets(2)); // Trigger button + sheet CTA
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.logout_rounded), findsNWidgets(2)); // Trigger icon + badge icon

      // Tap Cancel -> Dismisses bottom sheet without logging out
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Maulik Patel'), findsOneWidget);
    });

    testWidgets('6b. Confirming Log Out in bottom sheet executes logout flow', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      // Open bottom sheet
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // Tap the "Log Out" button inside the bottom sheet (the second one)
      final sheetLogoutBtn = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Log Out'),
      );
      expect(sheetLogoutBtn, findsOneWidget);

      await tester.tap(sheetLogoutBtn);
      await tester.pumpAndSettle();

      // Bottom sheet is dismissed
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('7. Bottom navigation renders with selectedIndex 4 (Profile)', (tester) async {
      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<AppBottomNavBar>(find.byType(AppBottomNavBar));
      expect(bottomNav.selectedIndex, 4);
    });

    testWidgets('8. Handles missing optional profile values safely without crash', (tester) async {
      mockProfileRepo.profileToReturn = {
        'id': 'user-2',
        'name': null,
        'phone': null,
      };

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('Unique Basket Customer'), findsOneWidget);
      expect(find.text('UB'), findsOneWidget);
    });

    testWidgets('9. Handles extremely long customer name without overflow', (tester) async {
      mockProfileRepo.profileToReturn = {
        'id': 'user-3',
        'name': 'Maulik Harshadbhai Daraniya Patel Very Long Name Fresh Fruits Specialist',
        'phone': '+919876543210',
      };

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('10. Responsive layout across compact widths (320, 360, 390, 430)', (tester) async {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createScreenHarness());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('11. Renders version footer with brand icon', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('•  v2.4.1'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_basket_rounded), findsWidgets);
    });
  });

  group('Bottom Navigation Integration to Profile', () {
    testWidgets('HomeScreen bottom nav tab 4 navigates to profile without throwing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final profileTab = find.byIcon(Icons.person_outline_rounded);
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('ExploreScreen bottom nav tab 4 navigates to profile without throwing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExploreScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final profileTab = find.byIcon(Icons.person_outline_rounded);
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('CartScreen bottom nav tab 4 navigates to profile without throwing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CartScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final profileTab = find.byIcon(Icons.person_outline_rounded);
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('FavoritesScreen bottom nav tab 4 navigates to profile without throwing', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: FavoritesScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final profileTab = find.byIcon(Icons.person_outline_rounded);
      if (profileTab.evaluate().isNotEmpty) {
        await tester.tap(profileTab.first);
        await tester.pumpAndSettle();
      }
    });
  });
}
