import 'package:flutter/material.dart';

import 'chaerok_colors.dart';
import 'chaerok_typography.dart';

class ChaerokTheme {
  const ChaerokTheme._();

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ChaerokColors.primary,
      primary: ChaerokColors.primary,
      surface: ChaerokColors.surface,
      error: ChaerokColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ChaerokColors.background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: ChaerokColors.background,
        foregroundColor: ChaerokColors.textPrimary,
        elevation: 0,
      ),
      textTheme: TextTheme(
        titleLarge: ChaerokTypography.titleLarge.copyWith(
          color: ChaerokColors.textPrimary,
        ),
        titleMedium: ChaerokTypography.titleMedium.copyWith(
          color: ChaerokColors.textPrimary,
        ),
        bodyLarge: ChaerokTypography.bodyLarge.copyWith(
          color: ChaerokColors.textPrimary,
        ),
        bodyMedium: ChaerokTypography.bodyMedium.copyWith(
          color: ChaerokColors.textPrimary,
        ),
        labelLarge: ChaerokTypography.bodyMedium.copyWith(
          color: ChaerokColors.textPrimary,
        ),
      ),
    );
  }
}
