import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/features/address/data/repositories/customer_address_repository.dart';
import 'package:customer_app/features/address/presentation/providers/customer_address_provider.dart';
import 'package:customer_app/features/address/presentation/screens/add_new_address_screen.dart';
import 'package:customer_app/features/profile_setup/data/repositories/customer_profile_repository.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';
import 'package:customer_app/shared/widgets/widgets.dart';

class MockAddressRepository implements CustomerAddressRepository {
  final Map<String, dynamic> addressesResponse;
  final bool shouldThrowOnAdd;
  int addAddressCallCount = 0;
  Map<String, dynamic>? lastAddedPayload;

  MockAddressRepository({
    this.addressesResponse = const {'addresses': []},
    this.shouldThrowOnAdd = false,
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
  }) async {
    addAddressCallCount++;
    if (shouldThrowOnAdd) {
      throw Exception('Failed to add address');
    }
    if (!['360001', '360002', '360003', '360004', '360005', '360006', '360007'].contains(pincode)) {
      throw Exception('PINCODE_NOT_SERVICEABLE: Delivery is currently not available for this pincode');
    }
    lastAddedPayload = {
      'title': title,
      'addressLine': addressLine,
      'city': city,
      'state': state,
      'pincode': pincode,
      'isDefault': isDefault,
    };
    return {
      'address': {
        'id': 'addr-new-123',
        'title': title,
        'addressLine': addressLine,
        'city': city,
        'state': state,
        'pincode': pincode,
        'isDefault': isDefault ?? false,
      }
    };
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
  }) async =>
      {};

  @override
  Future<Map<String, dynamic>> setDefaultAddress(String id) async => {};

  @override
  Future<Map<String, dynamic>> deleteAddress(String id) async => {};

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
  MockAddressRepository? addressRepo,
  MockProfileRepository? profileRepo,
  ValueChanged<Map<String, dynamic>>? onAddressSaved,
}) {
  final addrRepo = addressRepo ?? MockAddressRepository();
  final profRepo = profileRepo ?? MockProfileRepository();

  return ProviderScope(
    overrides: [
      customerAddressRepositoryProvider.overrideWithValue(addrRepo),
      customerProfileRepositoryProvider.overrideWithValue(profRepo),
    ],
    child: MaterialApp(
      home: AddNewAddressScreen(
        onAddressSaved: onAddressSaved,
      ),
    ),
  );
}

void main() {
  group('Screen 30 — Add New Address Unit & Widget Tests', () {
    testWidgets('1. Header renders AppHeader with title Add New Address and back button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(AppHeader), findsOneWidget);
      expect(find.text('Add New Address'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
    });

    testWidgets('2. Screen renders all 4 section cards and pre-populates contact details', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Section 1: Contact details
      expect(find.text('CONTACT DETAILS'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Phone Number *'), findsOneWidget);
      expect(find.text('Maulik Patel'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);

      // Section 2: Address details
      expect(find.text('ADDRESS DETAILS'), findsOneWidget);
      expect(find.text('House / Flat / Floor / Building *'), findsOneWidget);
      expect(find.text('Apartment / Road / Area / Street *'), findsOneWidget);
      expect(find.text('Landmark (Optional)'), findsOneWidget);
      expect(find.text('City *'), findsOneWidget);
      expect(find.text('State *'), findsOneWidget);
      expect(find.text('Rajkot'), findsOneWidget);
      expect(find.text('Gujarat'), findsOneWidget);
      expect(find.text('PIN Code *'), findsOneWidget);

      // Section 3: Save address as
      expect(find.text('SAVE ADDRESS AS'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // Section 4: Default delivery address
      expect(find.text('Make this my default delivery address'), findsOneWidget);
      expect(find.text('DEFAULT'), findsOneWidget);

      // Primary CTA
      expect(find.text('Save Address'), findsOneWidget);
    });

    testWidgets('3. Save Address As segmented cards switch selection correctly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Office
      final officeFinder = find.text('Office');
      await tester.ensureVisible(officeFinder);
      await tester.tap(officeFinder);
      await tester.pumpAndSettle();

      // Tap Other
      final otherFinder = find.text('Other');
      await tester.ensureVisible(otherFinder);
      await tester.tap(otherFinder);
      await tester.pumpAndSettle();

      // Tap Home
      final homeFinder = find.text('Home');
      await tester.ensureVisible(homeFinder);
      await tester.tap(homeFinder);
      await tester.pumpAndSettle();
    });

    testWidgets('4. Default address checkbox toggles state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final defaultCheckboxRow = find.text('Make this my default delivery address');
      await tester.ensureVisible(defaultCheckboxRow);

      // Tap Default Address row
      await tester.tap(defaultCheckboxRow);
      await tester.pumpAndSettle();

      // Tap again to uncheck
      await tester.tap(defaultCheckboxRow);
      await tester.pumpAndSettle();
    });

    testWidgets('5. PIN Code shows Deliverable badge only for valid Rajkot pincodes', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final pinCodeFinder = find.byType(TextField).last;
      await tester.ensureVisible(pinCodeFinder);

      // Type non-deliverable pincode
      await tester.enterText(pinCodeFinder, '380001');
      await tester.pump();
      expect(find.text('Deliverable'), findsNothing);

      // Type valid Rajkot pincode
      await tester.enterText(pinCodeFinder, '360005');
      await tester.pump();
      expect(find.text('Deliverable'), findsOneWidget);

      // Type incomplete pincode
      await tester.enterText(pinCodeFinder, '3600');
      await tester.pump();
      expect(find.text('Deliverable'), findsNothing);
    });

    testWidgets('6. Required field validation rejects empty or invalid fields', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Clear full name
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, '');

      final saveButton = find.text('Save Address');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Full name is required'), findsOneWidget);
    });

    testWidgets('7. Invalid Rajkot PIN Code is rejected on submit', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mockRepo = MockAddressRepository();
      await tester.pumpWidget(createTestWidget(addressRepo: mockRepo));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      // Building
      await tester.enterText(textFields.at(2), '123 Green Heights');
      // Street
      await tester.enterText(textFields.at(3), 'Nana Mova Road');
      // PIN Code (invalid)
      await tester.enterText(textFields.at(5), '380001');

      final saveButton = find.text('Save Address');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text('Delivery is currently not available for this pincode'), findsOneWidget);
      expect(mockRepo.addAddressCallCount, equals(0));
    });

    testWidgets('8. Valid form submission calls repository and triggers callback', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mockRepo = MockAddressRepository();
      Map<String, dynamic>? savedPayload;

      await tester.pumpWidget(createTestWidget(
        addressRepo: mockRepo,
        onAddressSaved: (payload) => savedPayload = payload,
      ));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      // Building
      await tester.enterText(textFields.at(2), '123 Green Heights');
      // Street
      await tester.enterText(textFields.at(3), 'Nana Mova Main Road');
      // Landmark
      await tester.enterText(textFields.at(4), 'Near Speedwell Party Plot');
      // PIN Code
      await tester.enterText(textFields.at(5), '360005');

      final defaultCheckboxRow = find.text('Make this my default delivery address');
      await tester.ensureVisible(defaultCheckboxRow);
      await tester.tap(defaultCheckboxRow);
      await tester.pumpAndSettle();

      // Tap Save Address
      final saveButton = find.text('Save Address');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(mockRepo.addAddressCallCount, equals(1));
      expect(mockRepo.lastAddedPayload?['title'], equals('Home'));
      expect(mockRepo.lastAddedPayload?['addressLine'], equals('123 Green Heights, Nana Mova Main Road, Near Speedwell Party Plot'));
      expect(mockRepo.lastAddedPayload?['city'], equals('Rajkot'));
      expect(mockRepo.lastAddedPayload?['state'], equals('Gujarat'));
      expect(mockRepo.lastAddedPayload?['pincode'], equals('360005'));
      expect(mockRepo.lastAddedPayload?['isDefault'], isTrue);
      expect(savedPayload, isNotNull);
    });

    testWidgets('9. API failure displays error SnackBar and keeps user on form', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mockRepo = MockAddressRepository(shouldThrowOnAdd: true);

      await tester.pumpWidget(createTestWidget(addressRepo: mockRepo));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(2), '123 Green Heights');
      await tester.enterText(textFields.at(3), 'Nana Mova Main Road');
      await tester.enterText(textFields.at(5), '360001');

      final saveButton = find.text('Save Address');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Failed to save address'), findsOneWidget);
      expect(find.text('Add New Address'), findsOneWidget);
    });

    testWidgets('10. Router integration: RouteNames.addNewAddress opens AddNewAddressScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      final mockRepo = MockAddressRepository();

      final router = GoRouter(
        initialLocation: RouteNames.addNewAddress,
        routes: [
          GoRoute(
            path: RouteNames.addNewAddress,
            builder: (context, state) => const AddNewAddressScreen(),
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

      expect(find.text('Add New Address'), findsOneWidget);
      expect(find.text('CONTACT DETAILS'), findsOneWidget);
    });

    testWidgets('11. Responsive viewports and dark mode render cleanly without overflow', (tester) async {
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
              home: const AddNewAddressScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Add New Address'), findsOneWidget);
      }
    });
  });
}
