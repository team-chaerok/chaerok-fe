import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_shadows.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:flutter/material.dart';

class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.data});

  final WeatherSummaryData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        border: Border.all(color: ChaerokColors.border),
        borderRadius: BorderRadius.circular(ChaerokRadius.lg),
        boxShadow: ChaerokShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.regionName,
                  style: ChaerokTypography.labelLarge.copyWith(
                    color: ChaerokColors.textSecondary,
                  ),
                ),
                const SizedBox(height: ChaerokSpacing.xxs),
                Text(
                  data.weatherLabel,
                  style: ChaerokTypography.headingMedium.copyWith(
                    color: ChaerokColors.primaryDark,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${data.temperature.round()}°',
            style: ChaerokTypography.titleLarge.copyWith(
              color: ChaerokColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}
