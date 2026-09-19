import 'package:customer_app/app/app.dart';
import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('CustomerApp Root Tests', () {
    testWidgets('App initializes with ProviderScope and renders without crashing',
        (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final localStorage = LocalStorageService(prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(localStorage),
          ],
          child: const CustomerApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CustomerApp), findsOneWidget);
    });
  });
}
