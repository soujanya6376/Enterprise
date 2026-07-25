import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'network/dio_client.dart';
import 'storage/session_store.dart';

/// SessionStore is provided after init() in main.dart via override.
final sessionStoreProvider = Provider<SessionStore>((ref) {
  throw UnimplementedError('Override sessionStoreProvider in main()');
});

final dioProvider = Provider<Dio>((ref) {
  final session = ref.watch(sessionStoreProvider);
  return DioClient(session).dio;
});

/// App-wide theme mode (light/dark/system).
final themeModeProvider = StateProvider((ref) => 0); // 0 system, 1 light, 2 dark
