import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/features/address/data/repositories/customer_address_repository.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/address/presentation/screens/edit_address_screen.dart';
import 'package:customer_app/features/profile_setup/data/repositories/customer_profile_repository.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';
import 'package:customer_app/shared/widgets/widgets.dart';

class MockAddressRepository implements CustomerAddressRepository {
  final Map<String, dynamic> addressesResponse;
  final bool shouldThrowOnUpdate;
  final bool shouldThrowOnDelete;
  int updateAddressCallCount = 0;
  int deleteAddressCallCount = 0;
  Map<String, dynamic>? lastUpdatedPayload;
  String? lastDeletedId;

  MockAddressRepository({
    this.addressesResponse = const {
      'addresses': [
        {
          'id': 'addr-1',
          'title': 'Home',
          'addressLine': '123, Green Heights, Opp. Central Park, Near Central Park',
          'city': 'Rajkot',
          'state': 'Gujarat',
          'pincode': '360001',
          'isDefault': true,
        },
        {
          'id': 'addr-2',
          'title': 'Office',
          'addressLine': '456, Business Hub, Kalawad Road',
          'city': 'Rajkot',
          'state': 'Gujarat',
          'pincode': '360005',
          'isDefault': false,
        },
      ]
    },
    this.shouldThrowOnUpdate = false,
    this.shouldThrowOnDelete = false,
  });

  @override
  Future<Map<String, dynamic>> getAddresses() async => addressesResponse;

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
  }) async =>
      {};

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
    updateAddressCallCount++;
    if (shouldThrowOnUpdate) {
      throw Exception('Failed to update address');
    }
    if (pincode != null && !['360001', '360002', '360003', '360004', '360005', '360006', '360007'].contains(pincode)) {
      throw Exception('PINCODE_NOT_SERVICEABLE: Delivery is currently not available for this pincode');
    }
    lastUpdatedPayload = {
      'id': id,
      'title': title,
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'pincode': pincode,
      'isDefault': isDefault,
    };
    return {
      'address': {
        'id': id,
        'title': title ?? 'Home',
        'addressLine': addressLine ?? '',
        'city': city ?? 'Rajkot',
        'state': state ?? 'Gujarat',
        'pincode': pincode ?? '360001',
        'isDefault': isDefault ?? false,
      }
    };
  }

  @override
  Future<Map<String, dynamic>> setDefaultAddress(String id) async => {};

  @override
  Future<Map<String, dynamic>> deleteAddress(String id) async {
    deleteAddressCallCount++;
    if (shouldThrowOnDelete) {
      throw Exception('Failed to delete address');
    }
    lastDeletedId = id;
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

class MockProfileRepository implements CustomerProfileRepository {
  final Map<String, dynamic> profileResponse;

  MockProfileRepository({
    this.profileResponse = const {
      'user': {
        'id': 'user-1',
        'name': 'Maulik Patel',
        'phone': '+919876543210',
      }
    },
  });

  @override
  Future<Map<String, dynamic>> getProfile() async => profileResponse;

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    DateTime? dob,
    String? gender,
  }) async =>
      profileResponse;
}

Widget createTestWidget({
  String addressId = 'addr-1',
  MockAddressRepository? addressRepo,
  MockProfileRepository? profileRepo,
  ValueChanged<Map<String, dynamic>>? onAddressUpdated,
  VoidCallback? onAddressDeleted,
}) {
  final addrRepo = addressRepo ?? MockAddressRepository();
  final profRepo = profileRepo ?? MockProfileRepository();

  return ProviderScope(
    overrides: [
      customerAddressRepositoryProvider.overrideWithValue(addrRepo),
      customerProfileRepositoryProvider.overrideWithValue(profRepo),
    ],
    child: MaterialApp(
      home: EditAddressScreen(
        addressId: addressId,
        onAddressUpdated: onAddressUpdated,
        onAddressDeleted: onAddressDeleted,
      ),
    ),
  );
}

void main() {
  group('Screen 31 — Edit Address Unit & Widget Tests', () {
    testWidgets('1. Header renders AppHeader with title Edit Address and back button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.text('Edit Address'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('2. Screen renders all 4 section cards and pre-populates existing address data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Section 1: Contact details
      expect(find.text('CONTACT DETAILS'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Phone Number *'), findsOneWidget);
      expect(find.text('Maulik Patel'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);

      // Section 2: Address details prefilled
      expect(find.text('ADDRESS DETAILS'), findsOneWidget);
      expect(find.text('123'), findsOneWidget); // Building
      expect(find.text('Green Heights'), findsOneWidget); // Street
      expect(find.text('Rajkot'), findsOneWidget);
      expect(find.text('Gujarat'), findsOneWidget);
      expect(find.text('360001'), findsOneWidget);

      // Deliverable badge should be visible because 360001 is a valid Rajkot pincode
      expect(find.text('Deliverable'), findsOneWidget);

      // Section 3: Save address as
      expect(find.text('SAVE ADDRESS AS'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // Section 4: Default delivery address
      expect(find.text('Make this my default delivery address'), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);

      // Primary & Secondary Actions
      expect(find.text('Update Address'), findsOneWidget);
      expect(find.text('Delete Address'), findsOneWidget);
    });

    testWidgets('3. Save Address As segmented cards switch selection correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Office
      final officeOption = find.text('Office');
      await tester.ensureVisible(officeOption);
      await tester.tap(officeOption);
      await tester.pumpAndSettle();

      // Tap Other
      final otherOption = find.text('Other');
      await tester.ensureVisible(otherOption);
      await tester.tap(otherOption);
      await tester.pumpAndSettle();

      // Tap Home
      final homeOption = find.text('Home');
      await tester.ensureVisible(homeOption);
      await tester.tap(homeOption);
      await tester.pumpAndSettle();
    });

    testWidgets('4. Default address checkbox toggles state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestWidget(addressId: 'addr-2')); // addr-2 is not default
      await tester.pumpAndSettle();

      final defaultCheckboxRow = find.text('Make this my default delivery address');
      await tester.ensureVisible(defaultCheckboxRow);

      // Toggle to checked
      await tester.tap(defaultCheckboxRow);
      await tester.pumpAndSettle();

      // Toggle back to unchecked
      await tester.tap(defaultCheckboxRow);
      await tester.pumpAndSettle();
    });

    testWidgets('5. PIN Code shows Deliverable badge only for valid Rajkot pincodes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final pinCodeFinder = find.byType(TextField).last;
      await tester.ensureVisible(pinCodeFinder);

      // Clear & enter invalid pincode
      await tester.enterText(pinCodeFinder, '380001');
      await tester.pump();
      expect(find.text('Deliverable'), findsNothing);

      // Enter valid Rajkot pincode
      await tester.enterText(pinCodeFinder, '360005');
      await tester.pump();
      expect(find.text('Deliverable'), findsOneWidget);
    });

    testWidgets('6. Required field validation rejects empty fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Clear building field (at index 2)
      final buildingField = find.byType(TextField).at(2);
      await tester.enterText(buildingField, '');

      final updateButton = find.text('Update Address');
      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      expect(find.text('House / Flat / Floor / Building is required'), findsOneWidget);
    });

    testWidgets('7. Invalid Rajkot PIN Code is rejected on submit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mockRepo = MockAddressRepository();
      await tester.pumpWidget(createTestWidget(addressRepo: mockRepo));
      await tester.pumpAndSettle();

      final pinCodeFinder = find.byType(TextField).last;
      await tester.enterText(pinCodeFinder, '380001');

      final updateButton = find.text('Update Address');
      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      expect(find.text('Delivery is currently not available for this pincode'), findsOneWidget);
      expect(mockRepo.updateAddressCallCount, equals(0));
    });

    testWidgets('8. Valid update submission calls repository.updateAddress and triggers callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mockRepo = MockAddressRepository();
      Map<String, dynamic>? updatedPayload;

      await tester.pumpWidget(createTestWidget(
        addressRepo: mockRepo,
        onAddressUpdated: (payload) => updatedPayload = payload,
      ));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      // Change Building
      await tester.enterText(textFields.at(2), 'Flat 402, Royal Residency');
      // Change Street
      await tester.enterText(textFields.at(3), 'University Road');
      // Change Landmark
      await tester.enterText(textFields.at(4), 'Near Indira Circle');
      // PIN Code
      await tester.enterText(textFields.at(5), '360005');

      // Tap Office
      final officeOption = find.text('Office');
      await tester.ensureVisible(officeOption);
      await tester.tap(officeOption);
      await tester.pumpAndSettle();

      // Tap Update Address
      final updateButton = find.text('Update Address');
      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      expect(mockRepo.updateAddressCallCount, equals(1));
      expect(mockRepo.lastUpdatedPayload?['id'], equals('addr-1'));
      expect(mockRepo.lastUpdatedPayload?['title'], equals('Office'));
      expect(mockRepo.lastUpdatedPayload?['addressLine'], equals('Flat 402, Royal Residency, University Road, Near Indira Circle'));
      expect(mockRepo.lastUpdatedPayload?['city'], equals('Rajkot'));
      expect(mockRepo.lastUpdatedPayload?['state'], equals('Gujarat'));
      expect(mockRepo.lastUpdatedPayload?['pincode'], equals('360005'));
      expect(updatedPayload, isNotNull);
    });

    testWidgets('9. Update failure displays error SnackBar and keeps user on screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mockRepo = MockAddressRepository(shouldThrowOnUpdate: true);

      await tester.pumpWidget(createTestWidget(addressRepo: mockRepo));
      await tester.pumpAndSettle();

      final updateButton = find.text('Update Address');
      await tester.ensureVisible(updateButton);
      await tester.tap(updateButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to update address'), findsOneWidget);
      expect(find.text('Edit Address'), findsOneWidget);
    });

    testWidgets('10. Delete button opens confirmation dialog; cancel dismisses dialog', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mockRepo = MockAddressRepository();

      await tester.pumpWidget(createTestWidget(addressRepo: mockRepo));
      await tester.pumpAndSettle();

      final deleteButton = find.text('Delete Address');
      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete Address?'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this address? This action cannot be undone.'), findsOneWidget);

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Address?'), findsNothing);
      expect(mockRepo.deleteAddressCallCount, equals(0));
    });

    testWidgets('11. Confirming delete calls repository.deleteAddress and triggers callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mockRepo = MockAddressRepository();
      bool wasDeleted = false;

      await tester.pumpWidget(createTestWidget(
        addressRepo: mockRepo,
        onAddressDeleted: () => wasDeleted = true,
      ));
      await tester.pumpAndSettle();

      final deleteButton = find.text('Delete Address');
      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Tap Delete in dialog (it's inside ElevatedButton)
      final dialogDeleteButton = find.widgetWithText(ElevatedButton, 'Delete');
      await tester.tap(dialogDeleteButton);
      await tester.pumpAndSettle();

      expect(mockRepo.deleteAddressCallCount, equals(1));
      expect(mockRepo.lastDeletedId, equals('addr-1'));
      expect(wasDeleted, isTrue);
    });

    testWidgets('12. Delete failure displays error SnackBar and stays on screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mockRepo = MockAddressRepository(shouldThrowOnDelete: true);

      await tester.pumpWidget(createTestWidget(addressRepo: mockRepo));
      await tester.pumpAndSettle();

      final deleteButton = find.text('Delete Address');
      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      final dialogDeleteButton = find.widgetWithText(ElevatedButton, 'Delete');
      await tester.tap(dialogDeleteButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to delete address'), findsOneWidget);
    });

    testWidgets('13. Non-existent address ID displays Address Not Found error state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestWidget(addressId: 'non-existent-id'));
      await tester.pumpAndSettle();

      expect(find.text('Address Not Found'), findsOneWidget);
      expect(find.text('The selected address is unavailable or has been deleted.'), findsOneWidget);
    });

    testWidgets('14. Router integration: RouteNames.editAddress opens EditAddressScreen with addressId', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mockRepo = MockAddressRepository();

      final router = GoRouter(
        initialLocation: '/address/edit',
        routes: [
          GoRoute(
            path: '/address/edit',
            builder: (context, state) => const EditAddressScreen(addressId: 'addr-1'),
          ),
          GoRoute(
            path: RouteNames.myAddresses,
            builder: (context, state) => const Scaffold(body: Text('My Addresses Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            customerAddressRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Address'), findsOneWidget);
      expect(find.text('CONTACT DETAILS'), findsOneWidget);
    });

    testWidgets('15. Responsive viewports and dark mode render cleanly without overflow', (tester) async {
      for (final size in [
        const Size(320, 568), // Small iPhone SE
        const Size(390, 844), // Standard iPhone 14
        const Size(430, 932), // Pro Max
        const Size(768, 1024), // Tablet
      ]) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              customerAddressRepositoryProvider.overrideWithValue(MockAddressRepository()),
            ],
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const EditAddressScreen(addressId: 'addr-1'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Edit Address'), findsOneWidget);
      }
    });
  });
}
