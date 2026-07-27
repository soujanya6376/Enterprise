import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_providers.dart';
import '../data/theme_repository.dart';
import 'theme_admin_models.dart';

export 'theme_admin_models.dart';

/// Admin-only API calls for managing themes.
class ThemeAdminService {
  ThemeAdminService(this._dio);
  final Dio _dio;

  Future<List<ThemeSummary>> list() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/themes',
      queryParameters: {'limit': 100},
    );
    final data = (res.data?['data'] as List?) ?? const [];
    return data
        .map((e) => ThemeSummary.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ThemeDetail> detail(String id) async {
    // The detail endpoint returns the theme; live platforms come from the
    // assignments endpoint, so the editor can warn before an admin edits a
    // theme that's already running on a till.
    final results = await Future.wait([
      _dio.get<Map<String, dynamic>>('/themes/$id'),
      _dio.get<List<dynamic>>('/themes/assignments'),
    ]);

    final theme = (results[0] as Response<Map<String, dynamic>>).data!;
    final assignments = (results[1] as Response<List<dynamic>>).data ?? const [];

    final live = assignments
        .map((a) => Map<String, dynamic>.from(a as Map))
        .where((a) => (a['theme'] as Map?)?['id'] == id)
        .map((a) => a['platform'] as String)
        .toList();

    return ThemeDetail.fromJson(theme, livePlatforms: live);
  }

  Future<Map<ClientPlatform, ThemeAssignmentInfo>> assignments() async {
    final res = await _dio.get<List<dynamic>>('/themes/assignments');
    final rows = res.data ?? const [];

    final out = <ClientPlatform, ThemeAssignmentInfo>{};
    for (final row in rows) {
      final map = Map<String, dynamic>.from(row as Map);
      final platform = ClientPlatform.values
          .where((p) => p.wireValue == map['platform'])
          .firstOrNull;
      final theme = map['theme'] as Map?;
      if (platform == null || theme == null) continue;

      out[platform] = ThemeAssignmentInfo(
        id: theme['id'] as String,
        name: theme['name'] as String,
        revision: (theme['revision'] as num).toInt(),
      );
    }
    return out;
  }

  Future<void> assign(ClientPlatform platform, String themeId) async {
    await _dio.put<void>(
      '/themes/assignments/${platform.wireValue}',
      data: {'themeId': themeId},
    );
  }

  Future<ThemeDetail> updateTokens(String id, Map<String, dynamic> tokens) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/themes/$id',
        data: {'tokens': tokens},
      );
      return ThemeDetail.fromJson(res.data!);
    } on DioException catch (err) {
      throw _mapValidationError(err);
    }
  }

  Future<ThemeSummary> duplicate(String id, String name) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/themes/$id/duplicate',
      data: {'name': name},
    );
    return ThemeSummary.fromJson(res.data!);
  }

  Future<ThemeSummary> create(String name, Map<String, dynamic> tokens, {String? description}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/themes',
        data: {'name': name, if (description != null) 'description': description, 'tokens': tokens},
      );
      return ThemeSummary.fromJson(res.data!);
    } on DioException catch (err) {
      throw _mapValidationError(err);
    }
  }

  Future<void> delete(String id) => _dio.delete<void>('/themes/$id');

  /// The API returns `{ message, issues: [...] }` on a 400 from token
  /// validation. Unpack it so the editor can list every bad field.
  Object _mapValidationError(DioException err) {
    final data = err.response?.data;
    if (err.response?.statusCode == 400 && data is Map && data['issues'] is List) {
      return TokenValidationFailure(
        (data['issues'] as List).map((e) => e.toString()).toList(),
      );
    }
    return err;
  }
}

// --- providers ---------------------------------------------------------------

/// Override in main.dart with the app's authenticated Dio instance.
final themeAdminServiceProvider = Provider<ThemeAdminService>((ref) {
  throw UnimplementedError(
    'Override themeAdminServiceProvider with the app Dio client, e.g.\n'
    '  themeAdminServiceProvider.overrideWithValue(ThemeAdminService(ref.read(dioProvider)))',
  );
});

final themeListProvider = FutureProvider<List<ThemeSummary>>(
  (ref) => ref.watch(themeAdminServiceProvider).list(),
);

final themeDetailProvider = FutureProvider.family<ThemeDetail, String>(
  (ref, id) => ref.watch(themeAdminServiceProvider).detail(id),
);

final themeAssignmentsProvider =
    FutureProvider<Map<ClientPlatform, ThemeAssignmentInfo>>(
  (ref) => ref.watch(themeAdminServiceProvider).assignments(),
);

/// Convenience alias so the settings page can repaint this device immediately
/// after reassigning its own platform.
final themeControllerProviderForAdmin = Provider(
  (ref) => ref.read(themeControllerProvider.notifier),
);
