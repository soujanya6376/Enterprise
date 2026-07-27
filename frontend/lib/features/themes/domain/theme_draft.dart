import 'dart:convert';
import 'dart:ui';

import 'theme_admin_models.dart';

/// Mutable working copy of a theme's tokens while the editor is open.
///
/// Deliberately operates on the raw JSON tree rather than the parsed
/// [ThemeTokens] model: the editor needs to hold partially-edited, temporarily
/// invalid state (an admin mid-typing a hex value) without exploding, and needs
/// to round-trip unknown keys untouched so an older client can't silently drop
/// tokens a newer schema added.
class ThemeDraft {
  ThemeDraft._(this._original, this._working);

  final Map<String, dynamic> _original;
  final Map<String, dynamic> _working;

  factory ThemeDraft.from(ThemeDetail theme) {
    final tokens = Map<String, dynamic>.from(theme.tokens);
    return ThemeDraft._(
      jsonDecode(jsonEncode(tokens)) as Map<String, dynamic>,
      jsonDecode(jsonEncode(tokens)) as Map<String, dynamic>,
    );
  }

  bool get isDirty => jsonEncode(_original) != jsonEncode(_working);

  Map<String, dynamic> toJson() => jsonDecode(jsonEncode(_working)) as Map<String, dynamic>;

  Map<String, dynamic> _modeMap(Brightness brightness) {
    final modes = _working['modes'] as Map<String, dynamic>;
    final key = brightness == Brightness.dark ? 'dark' : 'light';
    return modes[key] as Map<String, dynamic>;
  }

  /// Read-only view the editor renders fields from.
  DraftMode mode(Brightness brightness) => DraftMode(_modeMap(brightness));

  // --- mutations ------------------------------------------------------------

  void _setColor(Brightness b, String group, String key, Color value) {
    final colors = _modeMap(b)['color'] as Map<String, dynamic>;
    (colors[group] as Map<String, dynamic>)[key] = _hex(value);
  }

  void setBackgroundColor(Brightness b, String key, Color value) =>
      _setColor(b, 'background', key, value);

  void setContentColor(Brightness b, String key, Color value) =>
      _setColor(b, 'content', key, value);

  void setBorderColor(Brightness b, String key, Color value) =>
      _setColor(b, 'border', key, value);

  void _setNumber(Brightness b, String group, String key, num value) {
    (_modeMap(b)[group] as Map<String, dynamic>)[key] = value;
  }

  void setSpacing(Brightness b, String key, num value) => _setNumber(b, 'spacing', key, value);
  void setRadius(Brightness b, String key, num value) => _setNumber(b, 'radius', key, value);
  void setBorderWidth(Brightness b, String key, num value) => _setNumber(b, 'borderWidth', key, value);
  void setElevation(Brightness b, String key, num value) => _setNumber(b, 'elevation', key, value);

  void setFontFamily(Brightness b, String role, String value) {
    final typography = _modeMap(b)['typography'] as Map<String, dynamic>;
    (typography['fontFamily'] as Map<String, dynamic>)[role] = value;
  }

  void setTypeScale(Brightness b, String role, String field, num value) {
    final typography = _modeMap(b)['typography'] as Map<String, dynamic>;
    final scale = typography['scale'] as Map<String, dynamic>;
    (scale[role] as Map<String, dynamic>)[field] = value;
  }

  /// Copies every token from one mode to the other — a common starting move
  /// when an admin has finished light and wants dark to begin from the same
  /// spacing/type decisions rather than from scratch.
  void copyModeTo(Brightness from, Brightness to) {
    final source = jsonDecode(jsonEncode(_modeMap(from)));
    final modes = _working['modes'] as Map<String, dynamic>;
    modes[to == Brightness.dark ? 'dark' : 'light'] = source;
  }

  void revert() {
    _working
      ..clear()
      ..addAll(jsonDecode(jsonEncode(_original)) as Map<String, dynamic>);
  }

  static String _hex(Color color) {
    final argb = color.toARGB32();
    final alpha = (argb >> 24) & 0xFF;
    final rgb = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase();
    return alpha == 0xFF ? '#$rgb' : '#${alpha.toRadixString(16).padLeft(2, '0').toUpperCase()}$rgb';
  }
}

/// Typed accessors over one mode's raw map, for the editor's field groups.
class DraftMode {
  DraftMode(this._map);
  final Map<String, dynamic> _map;

  Map<String, dynamic> get _color => _map['color'] as Map<String, dynamic>;

  Map<String, Color> _colors(String group) {
    final bucket = _color[group] as Map<String, dynamic>;
    return {
      for (final entry in bucket.entries) entry.key: _parseHex(entry.value as String),
    };
  }

  Map<String, Color> get backgroundColors => _colors('background');
  Map<String, Color> get contentColors => _colors('content');
  Map<String, Color> get borderColors => _colors('border');

  Map<String, num> _numbers(String group) {
    final bucket = _map[group] as Map<String, dynamic>;
    return {for (final e in bucket.entries) e.key: e.value as num};
  }

  Map<String, num> get spacing => _numbers('spacing');
  Map<String, num> get radius => _numbers('radius');
  Map<String, num> get borderWidth => _numbers('borderWidth');
  Map<String, num> get elevation => _numbers('elevation');

  Map<String, dynamic> get _typography => _map['typography'] as Map<String, dynamic>;

  Map<String, String> get fontFamilies {
    final families = _typography['fontFamily'] as Map<String, dynamic>;
    return {for (final e in families.entries) e.key: e.value as String};
  }

  Map<String, Map<String, num>> get typeScale {
    final scale = _typography['scale'] as Map<String, dynamic>;
    return {
      for (final role in scale.entries)
        role.key: {
          for (final field in (role.value as Map<String, dynamic>).entries)
            field.key: field.value as num,
        },
    };
  }

  static Color _parseHex(String raw) {
    var hex = raw.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }
}
