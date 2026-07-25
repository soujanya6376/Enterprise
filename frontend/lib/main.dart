import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/storage/session_store.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionStore.init();
  final session = SessionStore();

  runApp(
    ProviderScope(
      overrides: [sessionStoreProvider.overrideWithValue(session)],
      child: const PosApp(),
    ),
  );
}

class PosApp extends ConsumerWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final mode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'POS Billing',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: [ThemeMode.system, ThemeMode.light, ThemeMode.dark][mode],
      routerConfig: router,
    );
  }
}
