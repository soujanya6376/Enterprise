import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/storage/session_store.dart';
import 'core/theme/theme_providers.dart';
import 'features/themes/data/theme_repository.dart';
import 'features/themes/domain/theme_admin_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionStore.init();
  final session = SessionStore();
  final themeCacheBox = await Hive.openBox('theme_cache');
  final themeModeBox = await Hive.openBox('theme_mode');

  runApp(
    ProviderScope(
      overrides: [
        sessionStoreProvider.overrideWithValue(session),
        themeRepositoryProvider.overrideWith(
          (ref) => ThemeRepository(
            dio: ref.watch(dioProvider),
            cacheBox: themeCacheBox,
          ),
        ),
        themeModeStoreProvider.overrideWithValue(ThemeModeStore(themeModeBox)),
        themeAdminServiceProvider.overrideWith(
          (ref) => ThemeAdminService(ref.watch(dioProvider)),
        ),
      ],
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
    return ThemeScope(
      builder: (context, light, dark) => MaterialApp.router(
        title: 'POS Billing',
        debugShowCheckedModeBanner: false,
        theme: light,
        darkTheme: dark,
        themeMode: mode,
        routerConfig: router,
      ),
    );
  }
}
