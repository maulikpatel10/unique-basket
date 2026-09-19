import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/app/router/route_names.dart';
import 'package:customer_app/app/theme/app_theme.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:customer_app/features/profile_setup/data/repositories/customer_profile_repository.dart';
import 'package:customer_app/features/profile_setup/presentation/providers/customer_profile_provider.dart';
import 'package:customer_app/features/profile_setup/presentation/screens/profile_setup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockCustomerProfileRepository implements CustomerProfileRepository {
  String? updatedName;
  String? updatedEmail;
  DateTime? updatedDob;

  @override
  Future<Map<String, dynamic>> getProfile() async {
    return {
      'success': true,
      'data': {
        'user': {
          'id': 'cust_123',
          'phone': '+919876543210',
          'name': updatedName ?? 'Rahul Sharma',
          'dob': updatedDob?.toIso8601String(),
        }
      }
    };
  }

  @override
  Future<Map<String, dynamic>> updateProfile({
    required String name,
    String? email,
    DateTime? dob,
  }) async {
    updatedName = name;
    updatedEmail = email;
    updatedDob = dob;
    return {
      'success': true,
      'data': {
        'user': {
          'id': 'cust_123',
          'phone': '+919876543210',
          'name': name,
          'dob': dob != null ? DateTime.utc(dob.year, dob.month, dob.day).toIso8601String() : null,
        }
      }
    };
  }
}

Widget _createTestWidget({
  String phoneNumber = '+91 98765 43210',
  ValueChanged<Map<String, dynamic>>? onProfileCompleted,
  ThemeMode themeMode = ThemeMode.light,
  LocalStorageService? localStorage,
  CustomerProfileRepository? profileRepository,
}) {
  return ProviderScope(
    overrides: [
      if (localStorage != null)
        localStorageProvider.overrideWithValue(localStorage),
      customerProfileRepositoryProvider.overrideWithValue(
        profileRepository ?? MockCustomerProfileRepository(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: ProfileSetupScreen(
        phoneNumber: phoneNumber,
        onProfileCompleted: onProfileCompleted,
      ),
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

  group('Screen 06 — Profile Setup Screen Tests', () {
    test('Profile setup route constants are defined correctly', () {
      expect(RouteNames.profileSetup, equals('/profile-setup'));
      expect(RouteNames.devProfileSetup, equals('/dev/profile-setup'));
    });

    testWidgets('1. Screen 06 renders without visible Back button',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(localStorage: localStorage));
      await tester.pump();

      expect(find.byType(ProfileSetupScreen), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('2. Screen 06 has NO Step indicator / STEP 3 OF 4',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(localStorage: localStorage));
      await tester.pump();

      expect(find.text('STEP 3 OF 4'), findsNothing);
    });

    testWidgets('2b. Tapping Add photo avatar opens photo selection bottom sheet',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(localStorage: localStorage));
      await tester.pump();

      expect(find.text('Add photo'), findsOneWidget);
      expect(find.byKey(const Key('profile_avatar_picker_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('profile_avatar_picker_button')));
      await tester.pumpAndSettle();

      expect(find.text('Profile Photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
    });

    testWidgets('3. PopScope prevents system back action from returning to OTP screen',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(localStorage: localStorage));
      await tester.pump();

      final popScopeFinder = find.byWidgetPredicate(
        (widget) => widget is PopScope && widget.canPop == false,
      );
      expect(popScopeFinder, findsOneWidget);
    });

    testWidgets('4. Valid name input and submission triggers onProfileCompleted',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      Map<String, dynamic>? completedProfile;

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(
        localStorage: localStorage,
        onProfileCompleted: (data) => completedProfile = data,
      ));
      await tester.pump();

      // Enter name
      final nameFields = find.byType(TextField);
      expect(nameFields, findsWidgets);
      await tester.enterText(nameFields.first, 'Rahul Sharma');
      await tester.pump();

      // Tap Continue button
      final continueButton = find.text('Continue');
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pump(const Duration(milliseconds: 400));

      expect(completedProfile, isNotNull);
      expect(completedProfile?['name'], equals('Rahul Sharma'));
      expect(completedProfile?['phone'], equals('+91 98765 43210'));
    });

    testWidgets('5. Dark theme renders cleanly without error',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(
        localStorage: localStorage,
        themeMode: ThemeMode.dark,
      ));
      await tester.pump();

      expect(find.byType(ProfileSetupScreen), findsOneWidget);
      expect(find.text('Create your profile'), findsOneWidget);
    });

    testWidgets('6. Date of birth selection and persistence in profile update',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);
      final mockRepo = MockCustomerProfileRepository();

      Map<String, dynamic>? completedProfile;

      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestWidget(
        localStorage: localStorage,
        profileRepository: mockRepo,
        onProfileCompleted: (data) => completedProfile = data,
      ));
      await tester.pump();

      // Enter name
      final nameFields = find.byType(TextField);
      await tester.enterText(nameFields.first, 'Priya Patel');
      await tester.pump();

      // Tap Date of Birth field
      final dobField = find.text('DD / MM / YYYY');
      expect(dobField, findsOneWidget);
      await tester.tap(dobField);
      await tester.pumpAndSettle();

      // In the DatePicker dialog, tap OK to select the default date (e.g. 1 Jan 2000)
      final okButton = find.text('OK');
      if (okButton.evaluate().isNotEmpty) {
        await tester.tap(okButton);
        await tester.pumpAndSettle();
      }

      // Tap Continue
      final continueButton = find.text('Continue');
      await tester.tap(continueButton);
      await tester.pump(const Duration(milliseconds: 400));

      expect(completedProfile, isNotNull);
      expect(completedProfile?['name'], equals('Priya Patel'));
      expect(mockRepo.updatedName, equals('Priya Patel'));
      expect(mockRepo.updatedDob, isNotNull);
    });

    test('7. Date serialization is calendar-day safe and avoids timezone shifting', () {
      final calendarDate = DateTime(2000, 8, 15);
      final utcIso = DateTime.utc(calendarDate.year, calendarDate.month, calendarDate.day).toIso8601String();
      expect(utcIso, equals('2000-08-15T00:00:00.000Z'));

      final parsedUtc = DateTime.parse(utcIso).toUtc();
      final reconstructed = DateTime(parsedUtc.year, parsedUtc.month, parsedUtc.day);
      expect(reconstructed.year, equals(2000));
      expect(reconstructed.month, equals(8));
      expect(reconstructed.day, equals(15));
    });
  });
}
