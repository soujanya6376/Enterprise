import 'package:flutter/material.dart';

import 'theme_tokens.dart';

/// Makes the raw tokens reachable from any widget without prop-drilling:
///   `context.tokens.color.background.surface`
///   `context.tokens.spacing.md`
class TokenTheme extends InheritedWidget {
  const TokenTheme({super.key, required this.tokens, required super.child});

  final ThemeTokens tokens;

  static ThemeTokens of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<TokenTheme>();
    assert(widget != null, 'No TokenTheme in scope. Wrap the app in ThemeScope.');
    return widget!.tokens;
  }

  @override
  bool updateShouldNotify(TokenTheme oldWidget) => oldWidget.tokens != tokens;
}

extension TokenContext on BuildContext {
  ThemeTokens get tokens => TokenTheme.of(this);
}

/// Builds Flutter's [ThemeData] from a token set.
///
/// Everything Material draws by default — scaffold background, card colour,
/// input borders, button shapes — is wired to a token here, so a widget that
/// uses stock Material components is already themed correctly and never needs a
/// hardcoded colour. Anything Material doesn't cover, widgets read from
/// `context.tokens` directly.
abstract final class AppTheme {
  static ThemeData from(ThemeTokens t, Brightness brightness) {
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: t.color.background.accent,
      onPrimary: t.color.content.onAccent,
      secondary: t.color.background.accent,
      onSecondary: t.color.content.onAccent,
      error: t.color.background.danger,
      onError: t.color.content.onAccent,
      surface: t.color.background.surface,
      onSurface: t.color.content.primary,
    );

    TextStyle style(TypeStyleToken s, String family, Color color) => TextStyle(
          fontFamily: family,
          fontSize: s.size,
          fontWeight: s.fontWeight,
          height: s.height,
          letterSpacing: s.letterSpacing,
          color: color,
        );

    final typo = t.typography;
    final primary = t.color.content.primary;
    final secondary = t.color.content.secondary;

    final textTheme = TextTheme(
      displayLarge: style(typo.display, typo.displayFamily, primary),
      displayMedium: style(typo.display, typo.displayFamily, primary),
      headlineMedium: style(typo.title, typo.displayFamily, primary),
      titleLarge: style(typo.title, typo.displayFamily, primary),
      titleMedium: style(typo.label, typo.bodyFamily, primary),
      bodyLarge: style(typo.body, typo.bodyFamily, primary),
      bodyMedium: style(typo.body, typo.bodyFamily, primary),
      bodySmall: style(typo.caption, typo.bodyFamily, secondary),
      labelLarge: style(typo.label, typo.bodyFamily, primary),
      labelMedium: style(typo.label, typo.bodyFamily, secondary),
      labelSmall: style(typo.caption, typo.bodyFamily, t.color.content.muted),
    );

    OutlineInputBorder inputBorder(Color color, double width) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(t.radius.md),
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: t.color.background.canvas,
      canvasColor: t.color.background.canvas,
      dividerColor: t.color.border.subtle,
      fontFamily: typo.bodyFamily,
      textTheme: textTheme,

      dividerTheme: DividerThemeData(
        color: t.color.border.subtle,
        thickness: t.borderWidth.hairline,
        space: t.spacing.md,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: t.color.background.surface,
        foregroundColor: t.color.content.primary,
        elevation: t.elevation.none,
        scrolledUnderElevation: t.elevation.sm,
        titleTextStyle: style(typo.title, typo.displayFamily, primary),
      ),

      cardTheme: CardThemeData(
        color: t.color.background.raised,
        elevation: t.elevation.sm,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radius.lg),
          side: BorderSide(color: t.color.border.subtle, width: t.borderWidth.hairline),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: t.color.background.raised,
        elevation: t.elevation.lg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radius.lg)),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: t.color.background.surface,
        contentPadding: EdgeInsets.symmetric(
          horizontal: t.spacing.md,
          vertical: t.spacing.sm,
        ),
        border: inputBorder(t.color.border.standard, t.borderWidth.hairline),
        enabledBorder: inputBorder(t.color.border.standard, t.borderWidth.hairline),
        focusedBorder: inputBorder(t.color.border.focus, t.borderWidth.thick),
        errorBorder: inputBorder(t.color.background.danger, t.borderWidth.hairline),
        focusedErrorBorder: inputBorder(t.color.background.danger, t.borderWidth.thick),
        labelStyle: style(typo.label, typo.bodyFamily, secondary),
        hintStyle: style(typo.body, typo.bodyFamily, t.color.content.muted),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: t.color.background.accent,
          foregroundColor: t.color.content.onAccent,
          elevation: t.elevation.none,
          padding: EdgeInsets.symmetric(
            horizontal: t.spacing.lg,
            vertical: t.spacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radius.md)),
          textStyle: style(typo.label, typo.bodyFamily, t.color.content.onAccent),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: t.color.content.primary,
          padding: EdgeInsets.symmetric(
            horizontal: t.spacing.lg,
            vertical: t.spacing.sm,
          ),
          side: BorderSide(color: t.color.border.standard, width: t.borderWidth.hairline),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radius.md)),
          textStyle: style(typo.label, typo.bodyFamily, primary),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: t.color.background.accent,
          textStyle: style(typo.label, typo.bodyFamily, t.color.background.accent),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: t.color.background.surface,
        side: BorderSide(color: t.color.border.subtle, width: t.borderWidth.hairline),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radius.pill)),
        labelStyle: style(typo.label, typo.bodyFamily, primary),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: t.color.background.inverse,
        contentTextStyle: style(typo.body, typo.bodyFamily, t.color.content.onInverse),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radius.md)),
        behavior: SnackBarBehavior.floating,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: t.spacing.md),
        titleTextStyle: style(typo.body, typo.bodyFamily, primary),
        subtitleTextStyle: style(typo.caption, typo.bodyFamily, secondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(t.radius.md)),
      ),
    );
  }
}
