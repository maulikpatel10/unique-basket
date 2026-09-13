import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:customer_app/app/app.dart';
import 'package:customer_app/app/config/app_config.dart';
import 'package:customer_app/app/config/environment.dart';
import 'package:customer_app/core/providers/core_providers.dart';
import 'package:customer_app/core/storage/local_storage_service.dart';

void main() {
  setUp(() {
    AppConfig.initialize(
      appName: 'Unique Basket',
      environment: Environment.development,
    );
  });

  testWidgets('CustomerApp bootstrap renders initial foundation view', (WidgetTester tester) async {
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

    expect(find.text('UNIQUE BASKET'), findsOneWidget);
    expect(find.text('Customer Application'), findsOneWidget);
  });
}
