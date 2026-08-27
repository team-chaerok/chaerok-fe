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
        borderRadius: BorderRadius.circular(ChaerokRadius.lg),
        boxShadow: ChaerokShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        data.regionName,
                        style: ChaerokTypography.displayLarge.copyWith(
                          fontFamily: ChaerokTypography.jeongnimsajiFontFamily,
                          color: const Color(0xFF565F4A),
                        ),
                      ),

                      Text(
                        '에서 기록 중',
                        style: ChaerokTypography.bodyMedium.copyWith(
                          color: ChaerokColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              Row(
                children: [
                  Text(data.weatherLabel, style: ChaerokTypography.bodyMedium),
                  Container(
                    color: ChaerokColors.border,
                    width: 1,
                    height: 16,
                    margin: const EdgeInsets.symmetric(
                      horizontal: ChaerokSpacing.xxs,
                    ),
                  ),

                  Text(
                    '${data.temperature.round()}°',
                    style: ChaerokTypography.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: ChaerokSpacing.md),
          Text(
            '오늘도 천천히 기록해보세요.',
            style: ChaerokTypography.caption.copyWith(
              color: const Color(0xFF7F8775),
            ),
          ),
        ],
      ),
    );
  }
}
