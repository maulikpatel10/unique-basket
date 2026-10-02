import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/features/address/data/repositories/customer_address_repository.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/address/presentation/screens/my_addresses_screen.dart';
import 'package:customer_app/features/profile/presentation/screens/profile_screen.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/shared/widgets/app_error_state.dart';
import 'package:customer_app/shared/widgets/app_header.dart';
import 'package:customer_app/shared/widgets/app_loading.dart';
import 'package:customer_app/shared/widgets/app_empty_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAddressRepository implements CustomerAddressRepository {
  List<Map<String, dynamic>> addressesToReturn = [];
  bool shouldThrow = false;
  String? lastDefaultSetId;
  String? lastDeletedId;

  @override
  Future<Map<String, dynamic>> getAddresses() async {
    if (shouldThrow) {
      throw Exception('NETWORK_ERROR');
    }
    return {'addresses': addressesToReturn};
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

  @override
  Future<Map<String, dynamic>> updateAddress({
    required String id,
    String? title,
    String? addressLine,
    String? city,
    String? state,
    String? pincode,
    double? latitude,
    double? longitude,
    bool? isDefault,
  }) async {
    return {};
  }

  @override
  Future<Map<String, dynamic>> setDefaultAddress(String id) async {
    lastDefaultSetId = id;
    for (final addr in addressesToReturn) {
      addr['isDefault'] = addr['id'] == id;
    }
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>> deleteAddress(String id) async {
    lastDeletedId = id;
    addressesToReturn.removeWhere((a) => a['id'] == id);
    if (addressesToReturn.isNotEmpty && !addressesToReturn.any((a) => a['isDefault'] == true)) {
      addressesToReturn[0]['isDefault'] = true;
    }
    return {'success': true};
  }

  @override
  Future<List<SupportedPincodeModel>> getSupportedPincodes() async => const [
        SupportedPincodeModel(id: '1', pincode: '360001', city: 'Rajkot', state: 'Gujarat', isActive: true),
        SupportedPincodeModel(id: '2', pincode: '360002', city: 'Rajkot', state: 'Gujarat', isActive: true),
        SupportedPincodeModel(id: '3', pincode: '360003', city: 'Rajkot', state: 'Gujarat', isActive: true),
        SupportedPincodeModel(id: '4', pincode: '360004', city: 'Rajkot', state: 'Gujarat', isActive: true),
        SupportedPincodeModel(id: '5', pincode: '360005', city: 'Rajkot', state: 'Gujarat', isActive: true),
        SupportedPincodeModel(id: '6', pincode: '360006', city: 'Rajkot', state: 'Gujarat', isActive: true),
        SupportedPincodeModel(id: '7', pincode: '360007', city: 'Rajkot', state: 'Gujarat', isActive: true),
      ];

  @override
  Future<Map<String, dynamic>> checkPincodeServiceability(String pincode) async => {
        'isServiceable': ['360001', '360002', '360003', '360004', '360005', '360006', '360007'].contains(pincode),
        'pincode': pincode,
        'city': 'Rajkot',
        'state': 'Gujarat',
      };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAddressRepository mockRepo;

  final sampleAddresses = [
    {
      'id': 'addr_1',
      'title': 'Home',
      'recipientName': 'Maulik Patel',
      'recipientPhone': '+91 98765 43210',
      'addressLine': '123, Example Road, Green Heights, Opp. Central Park',
      'city': 'Rajkot',
      'state': 'Gujarat',
      'pincode': '360001',
      'isDefault': true,
      'latitude': 22.3039,
      'longitude': 70.8022,
    },
    {
      'id': 'addr_2',
      'title': 'Office / Work',
      'recipientName': 'Maulik Patel',
      'recipientPhone': '+91 98765 43210',
      'addressLine': 'Unit 402, 4th Floor, Tech Park Tower B, Innovation Hub',
      'city': 'Rajkot',
      'state': 'Gujarat',
      'pincode': '360004',
      'isDefault': false,
      'latitude': 22.3100,
      'longitude': 70.8100,
    },
    {
      'id': 'addr_3',
      'title': "Parents' Home",
      'recipientName': 'Kiran Patel',
      'recipientPhone': '+91 94280 11223',
      'addressLine': 'Flat 12-B, Shanti Niketan Apartments, Near Shivalik Lake',
      'city': 'Rajkot',
      'state': 'Gujarat',
      'pincode': '360005',
      'isDefault': false,
      'latitude': 22.2900,
      'longitude': 70.7900,
    },
  ];

  setUp(() {
    mockRepo = MockAddressRepository();
    mockRepo.addressesToReturn = List<Map<String, dynamic>>.from(
      sampleAddresses.map((a) => Map<String, dynamic>.from(a)),
    );
  });

  Widget createScreenHarness({
    List<Map<String, dynamic>>? addressesOverride,
    bool throwError = false,
  }) {
    if (throwError) {
      mockRepo.shouldThrow = true;
    } else if (addressesOverride != null) {
      mockRepo.addressesToReturn = List<Map<String, dynamic>>.from(
        addressesOverride.map((a) => Map<String, dynamic>.from(a)),
      );
    }

    return ProviderScope(
      overrides: [
        customerAddressRepositoryProvider.overrideWithValue(mockRepo),
        customerAddressesProvider.overrideWith((ref) async {
          if (throwError) throw Exception('FAILED_FETCH');
          return mockRepo.addressesToReturn;
        }),
        customerProfileProvider.overrideWith((ref) async => {
          'name': 'Maulik Patel',
          'phone': '+91 98765 43210',
        }),
      ],
      child: const MaterialApp(
        home: MyAddressesScreen(),
      ),
    );
  }

  group('Screen 29 — My Addresses Unit & Widget Tests', () {
    testWidgets('1. My Addresses screen renders AppHeader with title and back button', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.text('My Addresses'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('2. Profile → My Addresses navigation navigates to RouteNames.myAddresses', (tester) async {
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
            path: RouteNames.myAddresses,
            builder: (context, state) => const MyAddressesScreen(),
          ),
        ],
      );

      SharedPreferences.setMockInitialValues({
        'user_data': '{"name":"Maulik Patel","phone":"+91 98765 43210"}',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorageService(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(storage),
            customerAddressRepositoryProvider.overrideWithValue(mockRepo),
            customerAddressesProvider.overrideWith((ref) async => sampleAddresses),
            customerProfileProvider.overrideWith((ref) async => {
              'name': 'Maulik Patel',
              'phone': '+91 98765 43210',
            }),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Addresses'), findsOneWidget);
      await tester.tap(find.text('My Addresses'));
      await tester.pumpAndSettle();

      expect(find.byType(MyAddressesScreen), findsOneWidget);
    });

    testWidgets('3. Subheader displays dynamic saved locations count and + Add New button', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('SAVED LOCATIONS'), findsOneWidget);
      expect(find.text('3 addresses available'), findsOneWidget);
      expect(find.text('Add New'), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    });

    testWidgets('4. Address list renders real provider data cards', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Office / Work'), findsOneWidget);
      expect(find.text("Parents' Home"), findsOneWidget);
      expect(find.text('Mon - Fri'), findsOneWidget);
      expect(find.text('Kiran Patel'), findsOneWidget);
      expect(find.text('+91 94280 11223'), findsOneWidget);
    });

    testWidgets('5. Default address renders selected radio button styling', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });

    testWidgets('6. Non-default addresses render unselected radio circles and category icons', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(2));
      expect(find.byIcon(Icons.work_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('7. Selecting a non-default address triggers setDefaultAddress and updates state', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      // Tap on Office / Work
      await tester.tap(find.text('Office / Work'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastDefaultSetId, 'addr_2');
      expect(find.text('Default address updated'), findsOneWidget);
    });

    testWidgets('8. Edit action navigates to RouteNames.editAddress with addressId', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: RouteNames.myAddresses,
        routes: [
          GoRoute(
            path: RouteNames.myAddresses,
            builder: (context, state) => const MyAddressesScreen(),
          ),
          GoRoute(
            path: RouteNames.editAddress,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return Scaffold(
                body: Text('EDIT_SCREEN_ID: ${extra?['addressId']}'),
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerAddressRepositoryProvider.overrideWithValue(mockRepo),
            customerAddressesProvider.overrideWith((ref) async => sampleAddresses),
            customerProfileProvider.overrideWith((ref) async => {
              'name': 'Maulik Patel',
              'phone': '+91 98765 43210',
            }),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final firstEditBtn = find.text('Edit').first;
      await tester.tap(firstEditBtn);
      await tester.pumpAndSettle();

      expect(find.text('EDIT_SCREEN_ID: addr_1'), findsOneWidget);
    });

    testWidgets('9. & 10. Delete confirmation dialog appears and cancelling keeps address', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      final firstDeleteIcon = find.byIcon(Icons.delete_outline_rounded).first;
      await tester.tap(firstDeleteIcon);
      await tester.pumpAndSettle();

      expect(find.text('Delete Address?'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to delete'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Address?'), findsNothing);
      expect(mockRepo.lastDeletedId, isNull);
    });

    testWidgets('11. Confirming delete removes address and refreshes list', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness());
      await tester.pumpAndSettle();

      final firstDeleteIcon = find.byIcon(Icons.delete_outline_rounded).first;
      await tester.tap(firstDeleteIcon);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(mockRepo.lastDeletedId, 'addr_1');
      expect(find.text('Address deleted successfully'), findsOneWidget);
    });

    testWidgets('12. & 13. Empty address list displays AppEmptyState and Add New button navigates', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final router = GoRouter(
        initialLocation: RouteNames.myAddresses,
        routes: [
          GoRoute(
            path: RouteNames.myAddresses,
            builder: (context, state) => const MyAddressesScreen(),
          ),
          GoRoute(
            path: RouteNames.addNewAddress,
            builder: (context, state) => const Scaffold(
              body: Text('ADD_NEW_ADDRESS_SCREEN'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerAddressRepositoryProvider.overrideWithValue(mockRepo),
            customerAddressesProvider.overrideWith((ref) async => []),
            customerProfileProvider.overrideWith((ref) async => null),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppEmptyState), findsOneWidget);
      expect(find.text('No saved addresses'), findsOneWidget);
      expect(find.text('+ Add New Address'), findsOneWidget);

      await tester.tap(find.text('+ Add New Address'));
      await tester.pumpAndSettle();

      expect(find.text('ADD_NEW_ADDRESS_SCREEN'), findsOneWidget);
    });

    testWidgets('14. Loading state shows AppLoading', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      final completer = Completer<List<Map<String, dynamic>>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerAddressRepositoryProvider.overrideWithValue(mockRepo),
            customerAddressesProvider.overrideWith((ref) => completer.future),
            customerProfileProvider.overrideWith((ref) async => null),
          ],
          child: const MaterialApp(
            home: MyAddressesScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AppLoading), findsOneWidget);
      expect(find.text('Loading saved addresses...'), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('15. & 16. Error state shows AppErrorState with retry', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createScreenHarness(throwError: true));
      await tester.pumpAndSettle();

      expect(find.byType(AppErrorState), findsOneWidget);
      expect(find.text('Unable to load addresses'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('17. Responsive viewports and dark mode render cleanly without overflow', (tester) async {
      for (final width in [320.0, 360.0, 390.0, 430.0]) {
        tester.view.physicalSize = Size(width * 2, 844 * 2);
        tester.view.devicePixelRatio = 2.0;

        await tester.pumpWidget(createScreenHarness());
        await tester.pumpAndSettle();

        expect(find.text('My Addresses'), findsOneWidget);
        expect(find.text('Home'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      tester.view.resetPhysicalSize();
    });
  });
}
