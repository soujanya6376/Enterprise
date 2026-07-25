import 'package:hive_flutter/hive_flutter.dart';

/// Lightweight persistent session storage backed by Hive.
class SessionStore {
  static const _box = 'session';
  static const _kAccess = 'accessToken';
  static const _kRefresh = 'refreshToken';
  static const _kUser = 'user';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_box);
  }

  Box get _b => Hive.box(_box);

  String? get accessToken => _b.get(_kAccess) as String?;
  String? get refreshToken => _b.get(_kRefresh) as String?;
  Map? get user => _b.get(_kUser) as Map?;
  String? get role => user?['role'] as String?;
  bool get isLoggedIn => accessToken != null;

  Future<void> save({
    required String accessToken,
    required String refreshToken,
    required Map user,
  }) async {
    await _b.putAll({_kAccess: accessToken, _kRefresh: refreshToken, _kUser: user});
  }

  Future<void> setAccessToken(String token) => _b.put(_kAccess, token);

  Future<void> clear() => _b.clear();
}
