import 'package:chaerok/ui/home/models/home_preview_data.dart';
import 'package:chaerok/ui/home/widgets/film_roll_artwork.dart';
import 'package:chaerok/ui/preview_theme.dart';
import 'package:flutter/material.dart';

class ActiveFilmRollCard extends StatelessWidget {
  const ActiveFilmRollCard({super.key, required this.data});

  final FilmRollPreviewData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(
        UiPreviewSpacing.md,
        UiPreviewSpacing.sm,
        UiPreviewSpacing.sm,
        UiPreviewSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: UiPreviewColors.sageLight,
        border: Border.all(color: UiPreviewColors.sage.withValues(alpha: 0.26)),
        borderRadius: BorderRadius.circular(UiPreviewRadius.lg),
        boxShadow: UiPreviewShadows.card,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.name,
                  style: UiPreviewTypography.labelLarge.copyWith(
                    color: UiPreviewColors.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: UiPreviewSpacing.xs),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${data.capturedCount}',
                      style: UiPreviewTypography.progress.copyWith(
                        color: UiPreviewColors.primaryDark,
                        fontSize: 22,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: UiPreviewSpacing.xs,
                        bottom: 2,
                      ),
                      child: Text(
                        '/ ${data.totalCount}',
                        style: UiPreviewTypography.labelSmall,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UiPreviewSpacing.xs),
                SizedBox(
                  width: 126,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(UiPreviewRadius.full),
                    child: LinearProgressIndicator(
                      value: data.progress,
                      minHeight: 4,
                      backgroundColor: UiPreviewColors.surface,
                      valueColor: const AlwaysStoppedAnimation(
                        UiPreviewColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: UiPreviewSpacing.xxs),
                const Text('촬영 진행 중', style: UiPreviewTypography.labelSmall),
              ],
            ),
          ),
          const FilmRollArtwork(),
        ],
      ),
    );
  }
}
