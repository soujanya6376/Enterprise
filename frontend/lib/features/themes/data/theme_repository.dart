import 'dart:convert';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive/hive.dart';

import '../../../core/theme/theme_tokens.dart';

/// Platform identifier sent to the API. Resolved once at boot.
enum ClientPlatform {
  web('WEB'),
  android('ANDROID'),
  ios('IOS');

  const ClientPlatform(this.wireValue);
  final String wireValue;

  static ClientPlatform current() {
    if (kIsWeb) return ClientPlatform.web;
    if (Platform.isAndroid) return ClientPlatform.android;
    if (Platform.isIOS) return ClientPlatform.ios;
    // Desktop/test runners: web tokens are the safe default — they're the set
    // designed for large screens.
    return ClientPlatform.web;
  }
}

/// Fetches the active theme and caches it in Hive.
///
/// The cache is what makes the app paint instantly on cold start and keep
/// working offline; the network fetch only ever *upgrades* what's already there.
class ThemeRepository {
  ThemeRepository({required Dio dio, required Box cacheBox})
      : _dio = dio,
        _cache = cacheBox;

  final Dio _dio;
  final Box _cache;

  static const _payloadKey = 'active_theme_payload';
  static const _etagKey = 'active_theme_etag';

  /// Last known-good theme, or null on first ever launch.
  AppThemeTokens? readCached() {
    final raw = _cache.get(_payloadKey);
    if (raw is! String) return null;
    try {
      return AppThemeTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Cache written by an older build with an incompatible schema. Drop it
      // and let the network fetch repopulate rather than crashing at startup.
      _cache.delete(_payloadKey);
      _cache.delete(_etagKey);
      return null;
    }
  }

  /// Fetches the active theme for this platform.
  ///
  /// Returns null when the server says nothing changed (304), so the caller
  /// keeps the tokens it already has. Throws on parse failure — an invalid
  /// payload should surface, not silently degrade.
  Future<AppThemeTokens?> fetchActive({ClientPlatform? platform}) async {
    final target = platform ?? ClientPlatform.current();
    final etag = _cache.get(_etagKey);

    final response = await _dio.get<Map<String, dynamic>>(
      '/themes/active',
      queryParameters: {'platform': target.wireValue},
      options: Options(
        headers: {if (etag is String) 'If-None-Match': etag},
        // 304 and 404 are expected control flow, not transport errors.
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    if (response.statusCode == 304) return null;

    if (response.statusCode == 404) {
      // No theme assigned to this platform yet. Keep whatever is cached.
      return null;
    }

    final body = response.data;
    if (body == null || body['theme'] == null) {
      throw StateError('Malformed theme response for ${target.wireValue}');
    }

    final theme = AppThemeTokens.fromJson(
      Map<String, dynamic>.from(body['theme'] as Map),
    );

    // Only cache after a successful parse, so a bad payload can never poison
    // the cache and brick the next cold start.
    await _cache.put(_payloadKey, jsonEncode(theme.rawJson));
    final newEtag = response.headers.value('etag');
    if (newEtag != null) await _cache.put(_etagKey, newEtag);

    return theme;
  }

  Future<void> clearCache() async {
    await _cache.delete(_payloadKey);
    await _cache.delete(_etagKey);
  }
}
