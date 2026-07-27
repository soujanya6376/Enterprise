/// Models for the admin-facing theme screens.
///
/// Distinct from the runtime `AppThemeTokens` in core/theme: the admin list
/// deliberately carries metadata only (token payloads are several KB each), and
/// the editor needs the raw untyped token tree so it can hold partially-edited
/// state. Runtime code should keep using the parsed model instead.
library;

class ThemeSummary {
  const ThemeSummary({
    required this.id,
    required this.name,
    this.description,
    required this.revision,
    required this.livePlatforms,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final int revision;

  /// Platforms currently running this theme — drives the "live" badge.
  final List<String> livePlatforms;
  final DateTime updatedAt;

  factory ThemeSummary.fromJson(Map<String, dynamic> json) => ThemeSummary(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        revision: (json['revision'] as num).toInt(),
        livePlatforms: ((json['assignments'] as List?) ?? const [])
            .map((a) => (a as Map)['platform'] as String)
            .toList(),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

class ThemeDetail {
  const ThemeDetail({
    required this.id,
    required this.name,
    this.description,
    required this.revision,
    required this.schemaVersion,
    required this.tokens,
    required this.livePlatforms,
  });

  final String id;
  final String name;
  final String? description;
  final int revision;
  final int schemaVersion;

  /// Raw token tree, untyped on purpose — see the note in ThemeDraft.
  final Map<String, dynamic> tokens;
  final List<String> livePlatforms;

  factory ThemeDetail.fromJson(
    Map<String, dynamic> json, {
    List<String> livePlatforms = const [],
  }) =>
      ThemeDetail(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        revision: (json['revision'] as num).toInt(),
        schemaVersion: (json['schemaVersion'] as num).toInt(),
        tokens: Map<String, dynamic>.from(json['tokens'] as Map),
        livePlatforms: livePlatforms,
      );
}

class ThemeAssignmentInfo {
  const ThemeAssignmentInfo({required this.id, required this.name, required this.revision});
  final String id;
  final String name;
  final int revision;
}

/// Raised when the API rejects a token payload. Carries every field-level
/// problem so the editor can show them all at once.
class TokenValidationFailure implements Exception {
  const TokenValidationFailure(this.issues);
  final List<String> issues;

  @override
  String toString() => 'Token validation failed:\n${issues.join('\n')}';
}
