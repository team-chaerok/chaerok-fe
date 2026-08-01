import 'package:flutter/material.dart';

class UiPreviewColors {
  const UiPreviewColors._();

  static const Color primary = Color(0xFF465043);
  static const Color primaryDark = Color(0xFF324D3E);
  static const Color sage = Color(0xFFA7BBA2);
  static const Color sageLight = Color(0xFFE8EFE7);
  static const Color skyBlue = Color(0xFFDCE6EE);
  static const Color background = Color(0xFFF7F8F6);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1D2420);
  static const Color textSecondary = Color(0xFF68716B);
  static const Color border = Color(0xFFE4E8E4);
  static const Color cameraBlack = Color(0xFF111513);
  static const Color categoryHover = Color(0xFFDDE5DC);
}

class UiPreviewSpacing {
  const UiPreviewSpacing._();

  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 40;
}

class UiPreviewRadius {
  const UiPreviewRadius._();

  static const double sm = 12;
  static const double md = 18;
  static const double lg = 22;
  static const double xl = 28;
  static const double full = 999;
}

class UiPreviewShadows {
  const UiPreviewShadows._();

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x0A111513), blurRadius: 14, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(color: Color(0x1A324D3E), blurRadius: 18, offset: Offset(0, 7)),
  ];
}

class UiPreviewTypography {
  const UiPreviewTypography._();

  static const String jeongnimsajiFontFamily = 'Jeongnimsaji';

  // Font families are assigned only at explicit call sites. Base styles keep
  // the system-font fallback so functional UI does not inherit display fonts.
  static const TextStyle displayLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w400,
    height: 1.25,
    letterSpacing: -0.4,
    color: UiPreviewColors.textPrimary,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w400,
    height: 1.3,
    letterSpacing: -0.2,
    color: UiPreviewColors.textPrimary,
  );

  // Functional styles are reserved for Pretendard.
  // They currently use the same system-font fallback as the display styles.
  static const TextStyle headingLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.3,
    color: UiPreviewColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
    color: UiPreviewColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: -0.1,
    color: UiPreviewColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: UiPreviewColors.textSecondary,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: UiPreviewColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: UiPreviewColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.1,
  );

  static const TextStyle progress = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

class UiPreviewTheme {
  const UiPreviewTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: UiPreviewColors.primary,
      brightness: Brightness.light,
      primary: UiPreviewColors.primary,
      surface: UiPreviewColors.surface,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: UiPreviewColors.background,
      splashColor: UiPreviewColors.surface.withValues(alpha: 0.12),
      highlightColor: UiPreviewColors.surface.withValues(alpha: 0.08),
      textTheme: const TextTheme(
        headlineLarge: UiPreviewTypography.headingLarge,
        headlineMedium: UiPreviewTypography.headingMedium,
        bodyLarge: UiPreviewTypography.bodyLarge,
        bodyMedium: UiPreviewTypography.bodyMedium,
        labelLarge: UiPreviewTypography.labelLarge,
        labelSmall: UiPreviewTypography.labelSmall,
      ),
    );
  }
}
