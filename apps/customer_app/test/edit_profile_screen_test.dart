import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/checkout/data/repositories/order_repository.dart';
import 'package:customer_app/features/checkout/presentation/providers/order_provider.dart';
import 'package:customer_app/features/home/presentation/providers/home_provider.dart';
import 'package:customer_app/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:customer_app/features/profile_setup/data/repositories/customer_profile_repository.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';
import 'package:customer_app/shared/widgets/app_header.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockProfileRepo implements CustomerProfileRepository {
  bool shouldThrow = false;
  Map<String, dynamic>? lastUpdatePayload;
  int updateCallCount = 0;

  @override
  Future<Map<String, dynamic>> getProfile() async {
    if (shouldThrow) {
      throw Exception('SERVER_ERROR');
    }
    return {
      'user': {
        'id': 'cust_101',
        'name': 'Maulik Patel',
        'phone': '+919876543210',
        'email': null,
        'dob': '2000-01-01T00:00:00.000Z',
      }
    };
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    DateTime? dob,
    String? gender,
  }) async {
    updateCallCount++;
    if (shouldThrow) {
      throw Exception('FAILED_UPDATE');
    }
    lastUpdatePayload = {
      'name': name,
      'email': email,
      'dob': dob?.toIso8601String(),
      'gender': gender,
    };
    return {
      'success': true,
      'data': {
        'user': {
          'id': 'cust_101',
          'name': name,
          'phone': '+919876543210',
          'email': email,
          'dob': dob?.toIso8601String(),
          'gender': gender,
        }
      }
    };
  }
}

class MockOrderRepo implements OrderRepository {
  @override
  Future<Map<String, dynamic>> createOrder({
    required String fulfillmentType,
    required String? addressId,
    required String? storeId,
    required String paymentMethod,
    required List<Map<String, dynamic>> items,
  }) async => {};

  @override
  Future<Map<String, dynamic>> getOrderById(String orderId) async => {};

  @override
  Future<List<dynamic>> getOrders() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockProfileRepo mockProfileRepo;
  late MockOrderRepo mockOrderRepo;
  late LocalStorageService localStorageService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_data': '{"name":"Maulik Patel","phone":"+919876543210","dob":"2000-01-01T00:00:00.000Z"}',
    });
    final prefs = await SharedPreferences.getInstance();
    localStorageService = LocalStorageService(prefs);
    mockProfileRepo = MockProfileRepo();
    mockOrderRepo = MockOrderRepo();
  });

  Widget createScreenHarness({
    CustomerProfileRepository? profileRepo,
    LocalStorageService? storage,
    Map<String, dynamic>? profileData,
  }) {
    return ProviderScope(
      overrides: [
        customerProfileRepositoryProvider.overrideWithValue(profileRepo ?? mockProfileRepo),
        orderRepositoryProvider.overrideWithValue(mockOrderRepo),
        localStorageProvider.overrideWithValue(storage ?? localStorageService),
        customerProfileProvider.overrideWith((ref) async => profileData ?? {
          'name': 'Maulik Patel',
          'phone': '+919876543210',
          'dob': '2000-01-01T00:00:00.000Z',
        }),
      ],
      child: const MaterialApp(
        home: EditProfileScreen(),
      ),
    );
  }

  group('Screen 26 — Edit Profile Unit & Widget Tests', () {
    testWidgets('1. Screen renders AppHeader with title Edit Profile and back button', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('2. Existing customer name populates correctly in Full Name field', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).first;
      expect(nameField, findsOneWidget);
      final textField = tester.widget<TextField>(nameField);
      expect(textField.controller?.text, 'Maulik Patel');
    });

    testWidgets('3. Mobile number renders with formatted display, lock icon, and verified pill', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.text('Primary account identifier. Cannot be edited directly.'), findsOneWidget);
    });

    testWidgets('4. Date of Birth populates formatted date and shows Optional badge', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('01 / 01 / 2000'), findsOneWidget);
      expect(find.text('Optional'), findsWidgets);
      expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
    });

    testWidgets('5. Gender selector displays default and can open bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Prefer not to say'));
      await tester.tap(find.text('Prefer not to say'));
      await tester.pumpAndSettle();

      expect(find.text('Select Gender'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);

      await tester.tap(find.text('Male'));
      await tester.pumpAndSettle();

      expect(find.text('Male'), findsOneWidget);
    });

    testWidgets('6. Avatar renders circular initials and camera badge', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('MP'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
      expect(find.text('Change Profile Photo'), findsOneWidget);
    });

    testWidgets('7. Change Profile Photo opens bottom sheet with photo options', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change Profile Photo'));
      await tester.pumpAndSettle();

      expect(find.text('Profile Photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });

    testWidgets('8. Full name validation rejects empty or too-short input', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, '');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();

      expect(find.text('Please enter your full name'), findsOneWidget);
      expect(mockProfileRepo.updateCallCount, 0);
    });

    testWidgets('9. Full name validation rejects strings > 100 chars', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'A' * 105);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();

      expect(find.text('Name cannot exceed 100 characters'), findsOneWidget);
      expect(mockProfileRepo.updateCallCount, 0);
    });

    testWidgets('10. Save Changes triggers profile update and calls repository with valid input', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'Maulik Daraniya');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();

      expect(mockProfileRepo.updateCallCount, 1);
      expect(mockProfileRepo.lastUpdatePayload?['name'], 'Maulik Daraniya');
      expect(find.text('Profile updated successfully!'), findsOneWidget);
    });

    testWidgets('11. Failed profile update preserves entered values and shows error toast', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      mockProfileRepo.shouldThrow = true;
      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'New Name');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();

      expect(mockProfileRepo.updateCallCount, 1);
      expect(find.text('Failed to update profile. Please try again.'), findsOneWidget);
      expect(find.text('New Name'), findsOneWidget);
    });

    testWidgets('12. Date of birth picker opens when tapped', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('01 / 01 / 2000'));
      await tester.tap(find.text('01 / 01 / 2000'));
      await tester.pumpAndSettle();

      expect(find.text('SELECT DATE OF BIRTH'), findsOneWidget);
    });

    testWidgets('13. Responsive viewports render cleanly without overflow', (tester) async {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(createScreenHarness());
        await tester.pumpAndSettle();

        expect(find.text('Edit Profile'), findsOneWidget);
        expect(find.text('SAVE CHANGES'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });

    testWidgets('14. Screen 25 Edit button navigates to RouteNames.editProfile', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: RouteNames.profile,
        routes: [
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: RouteNames.editProfile,
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerProfileRepositoryProvider.overrideWithValue(mockProfileRepo),
            orderRepositoryProvider.overrideWithValue(mockOrderRepo),
            localStorageProvider.overrideWithValue(localStorageService),
            customerProfileProvider.overrideWith((ref) async => {
              'name': 'Maulik Patel',
              'phone': '+919876543210',
            }),
            customerOrdersCountProvider.overrideWith((ref) => 5),
            favoritesNotifierProvider.overrideWith((ref) => FavoritesNotifier()),
            customerAddressesProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('SAVE CHANGES'), findsOneWidget);
    });

    testWidgets('15. Gender selection opens bottom sheet, selects gender, and sends to repository', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      // Tap gender selector
      await tester.ensureVisible(find.text('Prefer not to say'));
      await tester.tap(find.text('Prefer not to say'));
      await tester.pumpAndSettle();

      // Bottom sheet with gender options appears
      expect(find.text('Select Gender'), findsOneWidget);
      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // Select 'Female'
      await tester.tap(find.text('Female'));
      await tester.pumpAndSettle();

      // Verify selected gender is shown in the form
      expect(find.text('Female'), findsOneWidget);

      // Tap Save Changes
      await tester.ensureVisible(find.text('SAVE CHANGES'));
      await tester.tap(find.text('SAVE CHANGES'));
      await tester.pumpAndSettle();

      expect(mockProfileRepo.updateCallCount, 1);
      expect(mockProfileRepo.lastUpdatePayload?['gender'], 'Female');
    });

    testWidgets('16. Profile loads with pre-existing saved gender', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final profileData = {
        'name': 'Maulik Patel',
        'phone': '+919876543210',
        'gender': 'Male',
      };

      await tester.pumpWidget(createScreenHarness(profileData: profileData));
      await tester.pumpAndSettle();

      expect(find.text('Male'), findsOneWidget);
    });

    testWidgets('17. Null or empty gender renders safely with default placeholder', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      SharedPreferences.setMockInitialValues({
        'user_data': '{"name":"Maulik Patel","phone":"+919876543210"}',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      await tester.pumpWidget(createScreenHarness(storage: storage));
      await tester.pumpAndSettle();

      expect(find.text('Prefer not to say'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
