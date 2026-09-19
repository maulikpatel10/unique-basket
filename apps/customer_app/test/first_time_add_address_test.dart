import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/features/address/presentation/screens/first_time_add_address_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _createTestWidget({
  ValueChanged<Map<String, dynamic>>? onAddressSaved,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: FirstTimeAddAddressScreen(
        onAddressSaved: onAddressSaved,
      ),
    ),
  );
}

void main() {
  group('Screen 07 — First Time Add Address Tests', () {
    testWidgets('1. Screen renders all primary UI elements and legitimate field labels',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // Top navigation elements
      expect(find.byType(Image), findsOneWidget); // Logo
      expect(find.text('STEP 4 OF 4'), findsNothing);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);

      // PopScope check
      final popScopeFinder = find.byWidgetPredicate(
        (widget) => widget is PopScope && widget.canPop == false,
      );
      expect(popScopeFinder, findsOneWidget);

      // Headings
      expect(find.text('Add delivery address'), findsOneWidget);
      expect(
        find.text('Where should we deliver your fresh produce?'),
        findsOneWidget,
      );

      // Address Type Pills
      expect(find.text('SAVE ADDRESS AS'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      // Legitimate Field Labels remain
      expect(find.textContaining('FULL ADDRESS'), findsOneWidget);
      expect(find.textContaining('AREA / LOCALITY'), findsOneWidget);
      expect(find.textContaining('CITY'), findsOneWidget);
      expect(find.textContaining('STATE'), findsOneWidget);
      expect(find.textContaining('PIN CODE'), findsOneWidget);
      expect(find.textContaining('LANDMARK'), findsOneWidget);
      expect(find.textContaining('DELIVERY NOTE'), findsOneWidget);

      // Verify "required" and "optional" text badges are completely removed
      expect(find.text('required'), findsNothing);
      expect(find.text('optional'), findsNothing);

      // Fixed read-only City and State
      expect(find.text('Rajkot'), findsOneWidget);
      expect(find.text('Gujarat'), findsOneWidget);

      // Hints
      expect(
        find.text('Flat 402, Green Meadows, 4th Main Road'),
        findsOneWidget,
      );
      expect(find.text('Indiranagar Stage 2'), findsOneWidget);
      expect(find.text('360005'), findsOneWidget);
      expect(find.text('Near Nana Mova'), findsOneWidget);
      expect(find.text('e.g. Leave at door, ring bell'), findsOneWidget);

      // Primary CTA Button
      expect(find.text('Save & Continue'), findsOneWidget);

      // Footer note
      expect(
        find.text(
            'This address will be saved as your default delivery location.'),
        findsOneWidget,
      );
    });

    testWidgets('2. Address Type pill switching works',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // Tap 'Work'
      await tester.tap(find.text('Work'));
      await tester.pumpAndSettle();

      // Tap 'Other'
      await tester.tap(find.text('Other'));
      await tester.pumpAndSettle();

      // Tap 'Home'
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
    });

    testWidgets('3. Entering fewer than 6 digits shows no pincode delivery error while typing',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      final pinCodeField = find.byType(TextField).at(2);
      await tester.enterText(pinCodeField, '3600');
      await tester.pump();

      // Bottom sheet should NOT appear while typing
      expect(find.text("We're not delivering here yet"), findsNothing);
      // Inline error should NOT appear while typing
      expect(find.text("Sorry, we currently don't deliver to this pincode."), findsNothing);
      expect(find.text("PIN code must be 6 digits"), findsNothing);
    });

    testWidgets('4. Entering valid pincode (360001) shows no delivery error while typing',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      final pinCodeField = find.byType(TextField).at(2);
      await tester.enterText(pinCodeField, '360001');
      await tester.pump();

      expect(find.text("We're not delivering here yet"), findsNothing);
      expect(find.text("Sorry, we currently don't deliver to this pincode."), findsNothing);
    });

    testWidgets('5. Entering invalid pincode (360008) shows NO error while typing, but triggers error upon Save & Continue',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool addressSaved = false;
      await tester.pumpWidget(_createTestWidget(
        onAddressSaved: (_) => addressSaved = true,
      ));
      await tester.pumpAndSettle();

      // Fill Full Address and Area
      final fullAddressField = find.byType(TextField).at(0);
      await tester.enterText(fullAddressField, 'Flat 402, Green Meadows');
      await tester.pump();

      final areaLocalityField = find.byType(TextField).at(1);
      await tester.enterText(areaLocalityField, 'Indiranagar');
      await tester.pump();

      // Enter invalid pincode 360008
      final pinCodeField = find.byType(TextField).at(2);
      await tester.enterText(pinCodeField, '360008');
      await tester.pump();

      // While typing, NO bottom sheet and NO inline error
      expect(find.text("We're not delivering here yet"), findsNothing);
      expect(find.text("Sorry, we currently don't deliver to this pincode."), findsNothing);

      // Now tap Save & Continue
      await tester.tap(find.text('Save & Continue'));
      await tester.pumpAndSettle();

      // Error bottom sheet must appear on Save & Continue
      expect(find.text("We're not delivering here yet"), findsOneWidget);
      expect(
        find.textContaining('Sorry, UNIQUE BASKET is currently unavailable at PIN code 360008.'),
        findsOneWidget,
      );
      expect(find.text('Change PIN Code'), findsOneWidget);
      expect(find.text('Enter a different address'), findsOneWidget);
      expect(find.byIcon(Icons.location_off_outlined), findsOneWidget);

      // Dismiss bottom sheet via "Change PIN Code"
      await tester.tap(find.text('Change PIN Code'));
      await tester.pumpAndSettle();

      expect(find.text("We're not delivering here yet"), findsNothing);
      // Inline error remains visible after dismissal until edited
      expect(
        find.text("Sorry, we currently don't deliver to this pincode."),
        findsOneWidget,
      );

      // Submission was NOT performed
      expect(addressSaved, isFalse);

      // Editing pincode clears the error immediately
      await tester.enterText(pinCodeField, '36000');
      await tester.pump();
      expect(
        find.text("Sorry, we currently don't deliver to this pincode."),
        findsNothing,
      );

      // Type valid pincode 360005
      await tester.enterText(pinCodeField, '360005');
      await tester.pump();
      expect(
        find.text("Sorry, we currently don't deliver to this pincode."),
        findsNothing,
      );

      // Tap Save & Continue again -> now succeeds
      await tester.tap(find.text('Save & Continue'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 400));

      expect(addressSaved, isTrue);
    });

    testWidgets(
        '6. All 7 allowed Rajkot pincodes (360001-360007) succeed on Save & Continue',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const validPincodes = [
        '360001',
        '360002',
        '360003',
        '360004',
        '360005',
        '360006',
        '360007',
      ];

      for (final pincode in validPincodes) {
        Map<String, dynamic>? savedPayload;

        await tester.pumpWidget(_createTestWidget(
          onAddressSaved: (payload) => savedPayload = payload,
        ));
        await tester.pumpAndSettle();

        // Fill Full Address
        final fullAddressField = find.byType(TextField).at(0);
        await tester.enterText(fullAddressField, 'Flat 101, Galaxy Heights');
        await tester.pump();

        // Fill Area / Locality
        final areaLocalityField = find.byType(TextField).at(1);
        await tester.enterText(areaLocalityField, 'Kalawad Road');
        await tester.pump();

        // Fill PIN Code
        final pinCodeField = find.byType(TextField).at(2);
        await tester.enterText(pinCodeField, pincode);
        await tester.pump();

        // Tap Save & Continue
        await tester.tap(find.text('Save & Continue'));
        await tester.pump();
        await tester.pumpAndSettle(const Duration(milliseconds: 400));

        // Bottom sheet should NOT appear for valid pincode
        expect(find.text("We're not delivering here yet"), findsNothing);

        // Address should be saved successfully
        expect(savedPayload, isNotNull,
            reason: 'Pincode $pincode should be valid');
        expect(savedPayload!['pinCode'], pincode);
        expect(savedPayload!['city'], 'Rajkot');
        expect(savedPayload!['state'], 'Gujarat');
      }
    });

    testWidgets(
        '7. Non-allowed 6-digit pincodes (360008, 360009, 380001, 400001, 123456, 000000) are blocked on Save & Continue',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const invalidPincodes = [
        '360008',
        '360009',
        '380001',
        '400001',
        '123456',
        '000000',
      ];

      for (final invalidPin in invalidPincodes) {
        bool addressSaved = false;

        await tester.pumpWidget(_createTestWidget(
          onAddressSaved: (_) => addressSaved = true,
        ));
        await tester.pumpAndSettle();

        // Fill Full Address
        final fullAddressField = find.byType(TextField).at(0);
        await tester.enterText(fullAddressField, 'Flat 402, Green Meadows');
        await tester.pump();

        // Fill Area / Locality
        final areaLocalityField = find.byType(TextField).at(1);
        await tester.enterText(areaLocalityField, 'Indiranagar');
        await tester.pump();

        // Fill Invalid PIN Code
        final pinCodeField = find.byType(TextField).at(2);
        await tester.enterText(pinCodeField, invalidPin);
        await tester.pump();

        // Verify NO error shown while typing
        expect(find.text("We're not delivering here yet"), findsNothing);

        // Tap Save & Continue
        await tester.tap(find.text('Save & Continue'));
        await tester.pumpAndSettle();

        // Bottom sheet appears now
        expect(find.text("We're not delivering here yet"), findsOneWidget);
        expect(addressSaved, isFalse,
            reason: 'Pincode $invalidPin must not be saved');

        // Dismiss sheet
        await tester.tap(find.text('Change PIN Code'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('8. City and State are read-only (Rajkot & Gujarat, non-editable)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      // Verify City is displayed as Rajkot
      expect(find.text('Rajkot'), findsOneWidget);

      // Verify State is displayed as Gujarat
      expect(find.text('Gujarat'), findsOneWidget);

      // Exactly 5 TextFields exist in the form (Full Address, Area/Locality, PIN Code, Landmark, Delivery Note)
      // City and State are read-only containers without TextFields
      expect(find.byType(TextField), findsNWidgets(5));
    });

    testWidgets('9. Duplicate Save & Continue submissions are prevented while loading',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      int submissionCount = 0;
      await tester.pumpWidget(_createTestWidget(
        onAddressSaved: (_) => submissionCount++,
      ));
      await tester.pumpAndSettle();

      // Fill Full Address
      final fullAddressField = find.byType(TextField).at(0);
      await tester.enterText(fullAddressField, 'Flat 101, Galaxy Heights');
      await tester.pump();

      // Fill Area / Locality
      final areaLocalityField = find.byType(TextField).at(1);
      await tester.enterText(areaLocalityField, 'Kalawad Road');
      await tester.pump();

      // Fill PIN Code
      final pinCodeField = find.byType(TextField).at(2);
      await tester.enterText(pinCodeField, '360005');
      await tester.pump();

      // Tap Save & Continue
      await tester.tap(find.text('Save & Continue'));
      await tester.pump(const Duration(milliseconds: 50)); // Loading state active

      // Try tapping Save & Continue again while submitting
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
      await tester.pump();

      await tester.pumpAndSettle(const Duration(milliseconds: 400));
      expect(submissionCount, 1);
    });

    testWidgets('10. Dark theme renders correctly without crash',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(themeMode: ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(find.text('Add delivery address'), findsOneWidget);
      expect(find.text('STEP 4 OF 4'), findsNothing);
      expect(find.text('Rajkot'), findsOneWidget);
      expect(find.text('Gujarat'), findsOneWidget);
    });

    testWidgets(
        '11. Responsive check across various screen sizes without overflow',
        (WidgetTester tester) async {
      final viewports = [
        const Size(320, 568), // iPhone SE 1st gen / small compact
        const Size(360, 640), // Small Android
        const Size(360, 800), // Standard Android
        const Size(390, 844), // iPhone 12/13/14
        const Size(412, 915), // Pixel 7
        const Size(430, 932), // iPhone 14/15 Pro Max
        const Size(600, 960), // Small Tablet
        const Size(768, 1024), // iPad
      ];

      for (final size in viewports) {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;

        FlutterErrorDetails? errorDetails;
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          errorDetails = details;
          originalOnError?.call(details);
        };

        await tester.pumpWidget(_createTestWidget());
        await tester.pumpAndSettle();

        FlutterError.onError = originalOnError;

        if (errorDetails != null) {
          debugPrint(
              'DEBUG OVERFLOW DETAILS on $size: ${errorDetails?.toString()}');
        }

        expect(errorDetails, isNull, reason: 'Overflow on viewport: $size');
      }

      tester.view.resetPhysicalSize();
    });

    testWidgets('12. Screen 07 does NOT render STEP 4 OF 4 indicator',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('STEP 4 OF 4'), findsNothing);
    });
  });
}
