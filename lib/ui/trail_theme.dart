import 'package:material_ui/material_ui.dart';

const trailCoffee = Color(0xFF492C25);
const trailCream = Color(0xFFFFF0D5);
const trailCut = BorderRadius.only(
  topLeft: Radius.circular(4),
  topRight: Radius.circular(22),
  bottomLeft: Radius.circular(14),
  bottomRight: Radius.circular(4),
);

ThemeData trailTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = ColorScheme.fromSeed(
    brightness: brightness,
    seedColor: const Color(0xFFAD502D),
    secondary: dark ? const Color(0xFFAFC9FA) : const Color(0xFF345788),
    tertiary: dark ? const Color(0xFFA8C591) : const Color(0xFF36592F),
    surface: dark ? const Color(0xFF251E1A) : const Color(0xFFFFF8ED),
  );
  final theme = ThemeData(useMaterial3: true, colorScheme: colors);
  final shape = RoundedRectangleBorder(borderRadius: trailCut);
  return theme.copyWith(
    textTheme: theme.textTheme.copyWith(
      displaySmall:
          theme.textTheme.displaySmall?.copyWith(fontFamily: 'Fredoka'),
      headlineMedium:
          theme.textTheme.headlineMedium?.copyWith(fontFamily: 'Fredoka'),
      headlineSmall:
          theme.textTheme.headlineSmall?.copyWith(fontFamily: 'Fredoka'),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(
        fontFamily: 'Fredoka',
        color: colors.onSurface,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
            shape: shape, minimumSize: const Size(48, 48))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            shape: shape, minimumSize: const Size(48, 48))),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      shape: shape,
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerLow,
      border: const OutlineInputBorder(borderRadius: trailCut),
    ),
    dividerTheme: DividerThemeData(color: colors.outlineVariant),
    dialogTheme: DialogThemeData(shape: shape),
  );
}
