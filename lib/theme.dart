import 'package:flutter/material.dart';

/// A small 4pt-based spacing scale, mirroring how Apple's Human Interface
/// Guidelines describe layout spacing as a consistent, limited set of steps
/// rather than one-off values (HIG — Layout: "use a consistent set of
/// margins and spacing throughout your interface").
class AppSpacing {
  const AppSpacing._();

  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;
}

/// Success/positive-feedback colors, tuned separately for light and dark.
/// Material 3's [ColorScheme] has no "success" role of its own (only
/// error), so this fills that gap as a [ThemeExtension] — the supported
/// way to add custom-but-theme-aware colors that still respond correctly
/// to light/dark and interpolate during theme animations.
///
/// The dark-mode values are not just the light ones reused: HIG — Color
/// notes that colors need their own light/dark values because perceived
/// vibrancy and contrast differ against a dark background, so the dark
/// success tone is lifted in lightness rather than staying the same hex.
class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  final Color success;
  final Color onSuccess;
  final Color successContainer;
  final Color onSuccessContainer;

  const AppSemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
  });

  static const light = AppSemanticColors(
    success: Color(0xFF1E8E3E),
    onSuccess: Color(0xFFFFFFFF),
    successContainer: Color(0xFFDCF5E3),
    onSuccessContainer: Color(0xFF0B4D1E),
  );

  static const dark = AppSemanticColors(
    success: Color(0xFF4ADE80),
    onSuccess: Color(0xFF00390B),
    successContainer: Color(0xFF124023),
    onSuccessContainer: Color(0xFFAAF0C0),
  );

  @override
  AppSemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successContainer,
    Color? onSuccessContainer,
  }) {
    return AppSemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successContainer: successContainer ?? this.successContainer,
      onSuccessContainer: onSuccessContainer ?? this.onSuccessContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successContainer: Color.lerp(successContainer, other.successContainer, t)!,
      onSuccessContainer: Color.lerp(onSuccessContainer, other.onSuccessContainer, t)!,
    );
  }
}

/// Ergonomic access to the app's custom theme colors: `context.semanticColors`.
extension AppThemeContext on BuildContext {
  AppSemanticColors get semanticColors => Theme.of(this).extension<AppSemanticColors>()!;
}

class AppTheme {
  static const Color primaryColor = Color(0xFF0B5D8C);
  static const Color secondaryColor = Color(0xFF00897B);

  static ThemeData get lightTheme => _buildTheme(Brightness.light);

  static ThemeData get darkTheme => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: secondaryColor,
      brightness: brightness,
    );

    // A capsule/pill shape reads as the "prominent" iOS button style (HIG —
    // Buttons: filled, fully-rounded buttons for a screen's primary action).
    // Shared across filled and outlined buttons so a primary/secondary pair
    // (e.g. Previous/Next) doesn't mix a pill with a rounded rectangle.
    const pillShape = StadiumBorder();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surfaceContainerLowest,
      extensions: [isDark ? AppSemanticColors.dark : AppSemanticColors.light],
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xl),
          shape: pillShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.xl),
          shape: pillShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: pillShape),
      ),
      textTheme: const TextTheme(
        // Display and headline styles carry Apple's "optical sizing": HIG —
        // Typography notes tracking tightens as text gets larger, which is
        // why bigger styles get more negative letterSpacing here, not just
        // more weight.
        displayLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displayMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: -0.5),
        displaySmall: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.25),
        headlineLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.25),
        headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.25),
        headlineSmall: TextStyle(fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontWeight: FontWeight.w500),
      ),
    );
  }
}
