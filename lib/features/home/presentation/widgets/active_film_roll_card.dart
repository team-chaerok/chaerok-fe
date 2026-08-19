import 'dart:io';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_shadows.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/film_roll_artwork.dart';
import 'package:flutter/material.dart';

class ActiveFilmRollCard extends StatelessWidget {
  const ActiveFilmRollCard({super.key, required this.data});

  final FilmRollSummaryData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        ChaerokSpacing.md,
        ChaerokSpacing.sm,
        ChaerokSpacing.sm,
        ChaerokSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: ChaerokColors.sageLight,
        border: Border.all(
          color: ChaerokColors.primary.withValues(alpha: 0.26),
        ),
        borderRadius: BorderRadius.circular(ChaerokRadius.lg),
        boxShadow: ChaerokShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 96,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data.name,
                        style: ChaerokTypography.labelLarge.copyWith(
                          color: ChaerokColors.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: ChaerokSpacing.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${data.capturedCount}',
                            style: ChaerokTypography.progress.copyWith(
                              color: ChaerokColors.primaryDark,
                              fontSize: 22,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: ChaerokSpacing.xs,
                              bottom: 2,
                            ),
                            child: Text(
                              '/ ${data.totalCount}',
                              style: ChaerokTypography.labelSmall.copyWith(
                                color: ChaerokColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: ChaerokSpacing.xs),
                      SizedBox(
                        width: 126,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            ChaerokRadius.full,
                          ),
                          child: LinearProgressIndicator(
                            value: data.progress,
                            minHeight: 4,
                            backgroundColor: ChaerokColors.surface,
                            valueColor: const AlwaysStoppedAnimation(
                              ChaerokColors.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: ChaerokSpacing.xxs),
                      Text(
                        '촬영 진행 중',
                        style: ChaerokTypography.labelSmall.copyWith(
                          color: ChaerokColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const FilmRollArtwork(),
              ],
            ),
          ),
          if (data.photoThumbnailPaths.isNotEmpty) ...[
            const SizedBox(height: ChaerokSpacing.sm),
            _PhotoCarousel(thumbnailPaths: data.photoThumbnailPaths),
          ],
        ],
      ),
    );
  }
}

class _PhotoCarousel extends StatelessWidget {
  const _PhotoCarousel({required this.thumbnailPaths});

  final List<String> thumbnailPaths;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: thumbnailPaths.length,
        separatorBuilder: (_, _) => const SizedBox(width: ChaerokSpacing.xs),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(ChaerokRadius.sm),
            child: Image.file(
              File(thumbnailPaths[index]),
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}
