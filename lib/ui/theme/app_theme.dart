import 'package:material_ui/material_ui.dart';

/// Tokens de diseño tomados del Figma (crema, óxido, verde bosque y azul).
abstract final class Tk {
  static const bg = Color(0xFFFFF8ED);
  static const card = Color(0xFFF4E6D5);
  static const line = Color(0xFFCAB9A9);
  static const ink = Color(0xFF492C25);
  static const inkSoft = Color(0xFF635349);
  static const rust = Color(0xFF964528);
  static const rustDeep = Color(0xFF782E13);
  static const flame = Color(0xFFD26025);
  static const green = Color(0xFF36592F);
  static const blue = Color(0xFF345788);
  static const blush = Color(0xFFFFCBBA);

  static const radius = 12.0;
  static const pad = 20.0;

  /// Títulos: Fredoka.
  static TextStyle display(double size, {Color color = ink}) =>
      TextStyle(fontFamily: 'Fredoka', fontSize: size, color: color, height: 1.2);

  /// Texto: Work Sans.
  static TextStyle body(double size, {FontWeight w = FontWeight.w400, Color color = inkSoft, double? height}) =>
      TextStyle(fontFamily: 'WorkSans', fontSize: size, fontWeight: w, color: color, height: height);

  /// Etiqueta de sección (pequeña, en negrita).
  static TextStyle label({Color color = rust}) => body(12, w: FontWeight.w600, color: color);
}

ThemeData appTheme() {
  final scheme = ColorScheme.fromSeed(seedColor: Tk.rust, surface: Tk.bg).copyWith(
    primary: Tk.rust,
    onPrimary: Colors.white,
    secondary: Tk.blue,
    tertiary: Tk.green,
    surface: Tk.bg,
    onSurface: Tk.ink,
    surfaceContainerLow: Tk.card,
    outlineVariant: Tk.line,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Tk.radius));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'WorkSans',
    scaffoldBackgroundColor: Tk.bg,
    dividerTheme: const DividerThemeData(color: Tk.line, thickness: 1, space: 1),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Tk.rustDeep,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(52),
        shape: shape,
        textStyle: Tk.body(16, w: FontWeight.w600, color: Colors.white),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Tk.rust,
        side: const BorderSide(color: Tk.line),
        minimumSize: const Size.fromHeight(48),
        shape: shape,
        textStyle: Tk.body(14, w: FontWeight.w600, color: Tk.rust),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: Tk.rust, textStyle: Tk.body(14, w: FontWeight.w600, color: Tk.rust)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Tk.card,
      hintStyle: Tk.body(14, color: Tk.inkSoft.withValues(alpha: 0.7)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(Tk.radius), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Tk.radius), borderSide: const BorderSide(color: Tk.rust, width: 1.5)),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: Tk.rust,
      inactiveTrackColor: Tk.card,
      thumbColor: Tk.rust,
      trackHeight: 8,
      overlayShape: SliderComponentShape.noOverlay,
    ),
    dialogTheme: DialogThemeData(backgroundColor: Tk.bg, shape: shape),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Tk.ink,
      behavior: SnackBarBehavior.floating,
      shape: shape,
      contentTextStyle: Tk.body(14, color: Colors.white),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: Tk.rust),
  );
}
