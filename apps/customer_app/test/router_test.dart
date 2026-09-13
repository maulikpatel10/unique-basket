import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:customer_app/app/router/app_router.dart';
import 'package:customer_app/app/router/route_names.dart';

void main() {
  test('Router initializes with initial location', () {
    final container = ProviderContainer();
    final router = container.read(routerProvider);

    expect(router.routeInformationProvider.value.uri.path, equals(RouteNames.initial));
  });
}
