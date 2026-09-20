import 'package:flutter/material.dart';

/// Every colour used by the app lives here so the palette can be re-skinned
/// in one place.
class AppColors {
  const AppColors._();

  static const Color background = Color(0xFFF1F4EE);
  static const Color surface = Colors.white;

  /// Board tiles -----------------------------------------------------------
  static const Color tileUncalled = Color(0xFFA3DA7D);
  static const Color tileUncalledText = Color(0xFF1B2412);
  static const Color tileCalled = Color(0xFFE23B3B);
  static const Color tileCalledText = Colors.white;
  static const Color tileQueued = Color(0xFFFFC53D);
  static const Color tileQueuedBorder = Color(0xFFF09C00);
  static const Color tileQueuedReady = Color(0xFFFF9F1C);
  static const Color tileQueuedReadyBorder = Color(0xFFD9660A);
  static const Color tileLatestBorder = Color(0xFF101010);

  /// Controls --------------------------------------------------------------
  static const Color accent = Color(0xFF2E7D32);
  static const Color button = Color(0xFFA9E28C);
  static const Color buttonDisabled = Color(0xFFD4DCD0);
  static const Color ink = Color(0xFF1B2412);
  static const Color inkMuted = Color(0xFF66705D);
  static const Color chipSurface = Colors.white;
  static const Color currentNumberFill = Color(0xFFC4E7A6);
}

/// Shared metrics (spacing / radii) used across the widgets.
class AppMetrics {
  const AppMetrics._();

  static const double boardGap = 8;
  static const double tileRadius = 14;
  static const double panelGap = 10;
  static const double panelRadius = 12;
  static const int boardColumns = 10;
  static const int boardRows = 9;
}

ThemeData buildTambolaTheme() {
  final ThemeData base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.accent,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    splashFactory: InkSparkle.splashFactory,
  );
}
