import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers.dart';
import '../../../core/storage/session_store.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.watch(sessionStoreProvider));
});

class AuthRepository {
  AuthRepository(this._dio, this._session);
  final Dio _dio;
  final SessionStore _session;

  Future<Map> login(String username, String password) async {
    final res = await _dio.post('/auth/login', data: {
      'username': username,
      'password': password,
    });
    final data = res.data as Map;
    await _session.save(
      accessToken: data['accessToken'],
      refreshToken: data['refreshToken'],
      user: data['user'] as Map,
    );
    return data['user'] as Map;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (_) {}
    await _session.clear();
  }
}
