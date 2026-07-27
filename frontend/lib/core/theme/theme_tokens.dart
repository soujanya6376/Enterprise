import 'dart:ui';

/// Dart mirror of the v1 token contract in docs/THEMING.md.
///
/// Every field is required. Parsing throws [TokenParseException] on a missing or
/// malformed key rather than substituting a default — a theme that silently
/// half-loads would ship a broken-looking till screen, which is worse than
/// falling back to the last known-good cached theme.
class TokenParseException implements Exception {
  TokenParseException(this.path, this.reason);
  final String path;
  final String reason;
  @override
  String toString() => 'TokenParseException at $path: $reason';
}

// --- primitive readers -------------------------------------------------------

Map<String, dynamic> _obj(dynamic v, String path) {
  if (v is! Map) throw TokenParseException(path, 'expected an object');
  return Map<String, dynamic>.from(v);
}

Color _color(Map<String, dynamic> src, String key, String path) {
  final raw = src[key];
  if (raw is! String) throw TokenParseException('$path.$key', 'expected a hex string');
  var hex = raw.replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex'; // #RRGGBB -> opaque
  if (hex.length != 8) throw TokenParseException('$path.$key', 'expected #RRGGBB or #AARRGGBB');
  final value = int.tryParse(hex, radix: 16);
  if (value == null) throw TokenParseException('$path.$key', 'not valid hex');
  return Color(value);
}

double _num(Map<String, dynamic> src, String key, String path) {
  final raw = src[key];
  if (raw is! num) throw TokenParseException('$path.$key', 'expected a number');
  return raw.toDouble();
}

String _str(Map<String, dynamic> src, String key, String path) {
  final raw = src[key];
  if (raw is! String || raw.trim().isEmpty) {
    throw TokenParseException('$path.$key', 'expected a non-empty string');
  }
  return raw;
}

// --- token groups ------------------------------------------------------------

class BackgroundColors {
  const BackgroundColors({
    required this.canvas,
    required this.surface,
    required this.raised,
    required this.inverse,
    required this.accent,
    required this.danger,
    required this.success,
    required this.warning,
  });

  final Color canvas, surface, raised, inverse, accent, danger, success, warning;

  factory BackgroundColors.fromJson(dynamic json, String path) {
    final m = _obj(json, path);
    return BackgroundColors(
      canvas: _color(m, 'canvas', path),
      surface: _color(m, 'surface', path),
      raised: _color(m, 'raised', path),
      inverse: _color(m, 'inverse', path),
      accent: _color(m, 'accent', path),
      danger: _color(m, 'danger', path),
      success: _color(m, 'success', path),
      warning: _color(m, 'warning', path),
    );
  }
}

class ContentColors {
  const ContentColors({
    required this.primary,
    required this.secondary,
    required this.muted,
    required this.onAccent,
    required this.onInverse,
    required this.danger,
  });

  final Color primary, secondary, muted, onAccent, onInverse, danger;

  factory ContentColors.fromJson(dynamic json, String path) {
    final m = _obj(json, path);
    return ContentColors(
      primary: _color(m, 'primary', path),
      secondary: _color(m, 'secondary', path),
      muted: _color(m, 'muted', path),
      onAccent: _color(m, 'onAccent', path),
      onInverse: _color(m, 'onInverse', path),
      danger: _color(m, 'danger', path),
    );
  }
}

class BorderColors {
  const BorderColors({
    required this.subtle,
    required this.standard,
    required this.strong,
    required this.accent,
    required this.focus,
  });

  final Color subtle, standard, strong, accent, focus;

  factory BorderColors.fromJson(dynamic json, String path) {
    final m = _obj(json, path);
    return BorderColors(
      subtle: _color(m, 'subtle', path),
      // JSON key is "default"; Dart reserves it, so the field is `standard`.
      standard: _color(m, 'default', path),
      strong: _color(m, 'strong', path),
      accent: _color(m, 'accent', path),
      focus: _color(m, 'focus', path),
    );
  }
}

class ColorTokens {
  const ColorTokens({required this.background, required this.content, required this.border});
  final BackgroundColors background;
  final ContentColors content;
  final BorderColors border;

  factory ColorTokens.fromJson(dynamic json, String path) {
    final m = _obj(json, path);
    return ColorTokens(
      background: BackgroundColors.fromJson(m['background'], '$path.background'),
      content: ContentColors.fromJson(m['content'], '$path.content'),
      border: BorderColors.fromJson(m['border'], '$path.border'),
    );
  }
}

class SpacingTokens {
  const SpacingTokens(this._steps);
  final List<double> _steps;

  /// `spacing.step(4)` → 16.0 by default. Widgets use this instead of literals.
  double step(int n) {
    if (n < 0 || n >= _steps.length) {
      throw RangeError('spacing step $n is outside 0..${_steps.length - 1}');
    }
    return _steps[n];
  }

  double get none => step(0);
  double get xs => step(1);
  double get sm => step(2);
  double get md => step(4);
  double get lg => step(5);
  double get xl => step(6);

  factory SpacingTokens.fromJson(dynamic json, String path) {
    final m = _obj(json, path);
    return SpacingTokens(
      List<double>.generate(9, (i) => _num(m, '$i', path)),
    );
  }
}

class RadiusTokens {
  const RadiusTokens({
    required this.none,
    required this.sm,
    required this.md,
    required this.lg,
    required this.pill,
  });
  final double none, sm, md, lg, pill;

  factory RadiusTokens.fromJson(dynamic json, String path) {
    final m = _obj(json, path);
    return RadiusTokens(
      none: _num(m, 'none', path),
      sm: _num(m, 'sm', path),
      md: _num(m, 'md', path),
      lg: _num(m, 'lg', path),
      pill: _num(m, 'pill', path),
    );
  }
}

class BorderWidthTokens {
  const BorderWidthTokens({required this.none, required this.hairline, required this.thick});
  final double none, hairline, thick;

  factory BorderWidthTokens.fromJson(dynamic json, String path) {
    final m = _obj(json, path);
    return BorderWidthTokens(
      none: _num(m, 'none', path),
      hairline: _num(m, 'hairline', path),
      thick: _num(m, 'thick', path),
    );
  }
}

class ElevationTokens {
  const ElevationTokens({
    required this.none,
    required this.sm,
    required this.md,
    required this.lg,
  });
  final double none, sm, md, lg;

  factory ElevationTokens.fromJson(dynamic json, String path) {
    final m = _obj(json, path);
    return ElevationTokens(
      none: _num(m, 'none', path),
      sm: _num(m, 'sm', path),
      md: _num(m, 'md', path),
      lg: _num(m, 'lg', path),
    );
  }
}

class TypeStyleToken {
  const TypeStyleToken({
    required this.size,
    required this.weight,
    required this.height,
    required this.letterSpacing,
  });
  final double size;
  final int weight;
  final double height;
  final double letterSpacing;

  FontWeight get fontWeight => FontWeight.values[(weight ~/ 100) - 1];

  factory TypeStyleToken.fromJson(dynamic json, String path) {
    final m = _obj(json, path);
    final weight = _num(m, 'weight', path);
    if (weight % 100 != 0 || weight < 100 || weight > 900) {
      throw TokenParseException('$path.weight', 'must be 100–900 in steps of 100');
    }
    return TypeStyleToken(
      size: _num(m, 'size', path),
      weight: weight.toInt(),
      height: _num(m, 'height', path),
      letterSpacing: _num(m, 'letterSpacing', path),
    );
  }
}

class TypographyTokens {
  const TypographyTokens({
    required this.displayFamily,
    required this.bodyFamily,
    required this.monoFamily,
    required this.display,
    required this.title,
    required this.body,
    required this.label,
    required this.caption,
    required this.mono,
  });

  final String displayFamily, bodyFamily, monoFamily;
  final TypeStyleToken display, title, body, label, caption, mono;

  factory TypographyTokens.fromJson(dynamic json, String path) {
    final m = _obj(json, path);
    final families = _obj(m['fontFamily'], '$path.fontFamily');
    final scale = _obj(m['scale'], '$path.scale');
    return TypographyTokens(
      displayFamily: _str(families, 'display', '$path.fontFamily'),
      bodyFamily: _str(families, 'body', '$path.fontFamily'),
      monoFamily: _str(families, 'mono', '$path.fontFamily'),
      display: TypeStyleToken.fromJson(scale['display'], '$path.scale.display'),
      title: TypeStyleToken.fromJson(scale['title'], '$path.scale.title'),
      body: TypeStyleToken.fromJson(scale['body'], '$path.scale.body'),
      label: TypeStyleToken.fromJson(scale['label'], '$path.scale.label'),
      caption: TypeStyleToken.fromJson(scale['caption'], '$path.scale.caption'),
      mono: TypeStyleToken.fromJson(scale['mono'], '$path.scale.mono'),
    );
  }
}

/// One mode (light or dark) of a theme.
class ThemeTokens {
  const ThemeTokens({
    required this.color,
    required this.spacing,
    required this.radius,
    required this.borderWidth,
    required this.typography,
    required this.elevation,
  });

  final ColorTokens color;
  final SpacingTokens spacing;
  final RadiusTokens radius;
  final BorderWidthTokens borderWidth;
  final TypographyTokens typography;
  final ElevationTokens elevation;

  factory ThemeTokens.fromJson(dynamic json, String path) {
    final m = _obj(json, path);
    return ThemeTokens(
      color: ColorTokens.fromJson(m['color'], '$path.color'),
      spacing: SpacingTokens.fromJson(m['spacing'], '$path.spacing'),
      radius: RadiusTokens.fromJson(m['radius'], '$path.radius'),
      borderWidth: BorderWidthTokens.fromJson(m['borderWidth'], '$path.borderWidth'),
      typography: TypographyTokens.fromJson(m['typography'], '$path.typography'),
      elevation: ElevationTokens.fromJson(m['elevation'], '$path.elevation'),
    );
  }
}

/// A full theme: identity plus both modes.
class AppThemeTokens {
  const AppThemeTokens({
    required this.id,
    required this.name,
    required this.revision,
    required this.light,
    required this.dark,
    required this.rawJson,
  });

  final String id;
  final String name;
  final int revision;
  final ThemeTokens light;
  final ThemeTokens dark;

  /// Kept so the client can re-cache the exact payload it received without
  /// round-tripping through the parsed model and risking drift.
  final Map<String, dynamic> rawJson;

  static const supportedSchemaVersion = 1;

  factory AppThemeTokens.fromJson(Map<String, dynamic> json) {
    final tokens = _obj(json['tokens'], 'tokens');
    final version = tokens['schemaVersion'];
    if (version != supportedSchemaVersion) {
      throw TokenParseException(
        'tokens.schemaVersion',
        'this build supports v$supportedSchemaVersion, got $version — update the app',
      );
    }
    final modes = _obj(tokens['modes'], 'tokens.modes');
    return AppThemeTokens(
      id: json['id'] as String,
      name: json['name'] as String,
      revision: (json['revision'] as num).toInt(),
      light: ThemeTokens.fromJson(modes['light'], 'tokens.modes.light'),
      dark: ThemeTokens.fromJson(modes['dark'], 'tokens.modes.dark'),
      rawJson: json,
    );
  }

  ThemeTokens forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
