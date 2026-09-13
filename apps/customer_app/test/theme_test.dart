import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/app/theme/app_colors.dart';
import 'package:customer_app/app/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppTheme returns valid Material 3 ThemeData with brand colors', () {
    final theme = AppTheme.lightTheme;

    expect(theme.useMaterial3, isTrue);
    expect(theme.primaryColor, equals(AppColors.primary));
    expect(theme.colorScheme.primary, equals(AppColors.primary));
    expect(theme.scaffoldBackgroundColor, equals(AppColors.background));
  });
}
