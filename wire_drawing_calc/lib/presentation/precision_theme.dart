import 'package:flutter/material.dart';

/// Tokens from the approved A / Precision Glass mockup.
abstract final class PrecisionTokens {
  static const gap = 12.0;
  static const padding = 16.0;
  static const radius = 22.0;
  static const fieldRadius = 12.0;
  static const touchTarget = 48.0;
  static const focusWidth = 2.0;
  static const blurSigma = 14.0;
  static const maxBlurRegions = 2;
  static const motion = Duration(milliseconds: 160);
  static const numbers = [FontFeature.tabularFigures()];
}

class PrecisionPalette {
  const PrecisionPalette(this.dark);
  final bool dark;
  static PrecisionPalette of(BuildContext context) =>
      PrecisionPalette(Theme.of(context).brightness == Brightness.dark);
  Color get background => Color(dark ? 0xff11131d : 0xfff4f3f9);
  Color get surface => Color(dark ? 0xff202330 : 0xffffffff);
  Color get soft => Color(dark ? 0xff2c293e : 0xfff2eef9);
  Color get ink => Color(dark ? 0xfff3f1fa : 0xff212235);
  Color get muted => Color(dark ? 0xffc2bbd1 : 0xff5a596f);
  Color get accent => Color(dark ? 0xffc3a9ff : 0xff6530b9);
  Color get onAccent => Color(dark ? 0xff21123d : 0xffffffff);
  // Input boundaries must remain discernible against opaque surfaces (>=3:1).
  Color get line => Color(dark ? 0xff8d859c : 0xff82778f);
  Color get glass => Color(dark ? 0xe0272637 : 0xc7ffffff);
  Color get aura => Color(dark ? 0xff51406f : 0xffd8c6f3);
  Color get error => Color(dark ? 0xffffafbd : 0xffa3203f);
  Color get errorBackground => Color(dark ? 0xff402432 : 0xfffff0f2);
}

ThemeData precisionTheme(Brightness brightness) {
  final p = PrecisionPalette(brightness == Brightness.dark);
  final scheme = ColorScheme.fromSeed(
    seedColor: p.accent,
    brightness: brightness,
  ).copyWith(
    primary: p.accent,
    onPrimary: p.onAccent,
    surface: p.surface,
    onSurface: p.ink,
    onSurfaceVariant: p.muted,
    outline: p.line,
    error: p.error,
    errorContainer: p.errorBackground,
  );
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(PrecisionTokens.fieldRadius),
        borderSide: BorderSide(color: color, width: width),
      );
  final base = ThemeData(useMaterial3: true, colorScheme: scheme);
  return base.copyWith(
    scaffoldBackgroundColor: p.background,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {TargetPlatform.android: _PrecisionTransitions()},
    ),
    // Use Android's complete system font family. The bundled Inter face has
    // only weight 800 and cannot represent the approved body typography.
    textTheme: base.textTheme.apply(bodyColor: p.ink, displayColor: p.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.background,
      contentPadding: const EdgeInsets.all(14),
      border: border(p.line),
      enabledBorder: border(p.line),
      disabledBorder: border(p.line),
      focusedBorder: border(p.accent, PrecisionTokens.focusWidth),
      errorBorder: border(p.error),
      focusedErrorBorder: border(p.error, PrecisionTokens.focusWidth),
      errorMaxLines: 4,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: p.onAccent,
        backgroundColor: p.accent,
        elevation: 0,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: p.ink,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        side: BorderSide(color: p.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: p.ink,
      ),
    ),
  );
}

class _PrecisionTransitions extends PageTransitionsBuilder {
  const _PrecisionTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return FadeTransition(opacity: animation, child: child);
  }
}
