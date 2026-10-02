import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/cart/presentation/providers/cart_provider.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

/// App-wide messenger so background events (e.g. cart sync failures) can be shown on any screen.
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class CustomerApp extends ConsumerWidget {
  const CustomerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // P1-06: surface cart changes the server rejected, then clear the message
    ref.listen<String?>(cartSyncErrorProvider, (previous, next) {
      if (next == null) return;
      appScaffoldMessengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(next)));
      ref.read(cartSyncErrorProvider.notifier).state = null;
    });

    return MaterialApp.router(
      title: 'Unique Basket',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      scaffoldMessengerKey: appScaffoldMessengerKey,
      routerConfig: router,
    );
  }
}
