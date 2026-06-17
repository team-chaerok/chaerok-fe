import 'package:flutter/material.dart';

import 'chaerok_colors.dart';

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
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: ChaerokColors.textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: ChaerokColors.textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: ChaerokColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: ChaerokColors.textSecondary,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: ChaerokColors.textPrimary,
        ),
      ),
    );
  }
}