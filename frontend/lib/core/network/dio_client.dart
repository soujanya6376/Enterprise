import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../storage/session_store.dart';

/// Configured Dio instance with auth + refresh interceptors.
class DioClient {
  DioClient(this._session) {
    dio = Dio(BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ));
    dio.interceptors.add(_authInterceptor());
  }

  final SessionStore _session;
  late final Dio dio;

  InterceptorsWrapper _authInterceptor() => InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _session.accessToken;
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (err, handler) async {
          final isAuthCall = err.requestOptions.path.contains('/auth/');
          if (err.response?.statusCode == 401 && !isAuthCall) {
            final refreshed = await _tryRefresh();
            if (refreshed) {
              final req = err.requestOptions;
              req.headers['Authorization'] = 'Bearer ${_session.accessToken}';
              try {
                final clone = await dio.fetch(req);
                return handler.resolve(clone);
              } catch (_) {/* fall through */}
            }
          }
          handler.next(err);
        },
      );

  Future<bool> _tryRefresh() async {
    final refresh = _session.refreshToken;
    if (refresh == null) return false;
    try {
      final res = await Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl))
          .post('/auth/refresh', data: {'refreshToken': refresh});
      final token = res.data['accessToken'] as String?;
      if (token != null) {
        await _session.setAccessToken(token);
        return true;
      }
    } catch (_) {}
    await _session.clear();
    return false;
  }
}
