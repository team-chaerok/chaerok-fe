import 'dart:io';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_shadows.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:flutter/material.dart';

const double _photoItemWidth = 105;
const double _photoItemHeight = 64;
const double _photoItemGap = 14;
const double _photoItemRadius = 2;

class ActiveFilmRollCard extends StatelessWidget {
  const ActiveFilmRollCard({super.key, required this.data});

  final FilmRollSummaryData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: ChaerokSpacing.xl,
            bottom: ChaerokSpacing.md,
          ),
          child: Row(
            children: [
              Text(data.name, style: ChaerokTypography.titleMedium),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      left: ChaerokSpacing.xs,
                      bottom: 2,
                    ),
                    child: Text(
                      '${data.capturedCount} / ${data.totalCount}',
                      style: ChaerokTypography.bodyLarge,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 20,
              color: const Color(0xFF21301F),
              // 눈금 개수는 totalCount가 아니라 가로 폭에 맞춰 채운다.
              // 첫 눈금은 왼쪽 간격 10부터, 이후 눈금끼리 간격 20.
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const tickWidth = 10.0;
                  const tickHeight = 8.0;
                  const gap = 20.0;
                  const leadingGap = 10.0;
                  final tickCount =
                      ((constraints.maxWidth + gap - leadingGap) /
                              (tickWidth + gap))
                          .floor()
                          .clamp(0, 1 << 20);
                  return Row(
                    children: [
                      for (var i = 0; i < tickCount; i++) ...[
                        SizedBox(width: i == 0 ? leadingGap : gap),
                        Container(
                          width: tickWidth,
                          height: tickHeight,
                          decoration: const BoxDecoration(
                            color: ChaerokColors.textDisabled,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF21301F),
                boxShadow: ChaerokShadows.card,
              ),
              // 인증(채록)한 사진이 있으면 사진 Row를, 없으면 회색 placeholder를 노출한다.
              child: data.photoThumbnailPaths.isNotEmpty
                  ? _CapturedPhotoRow(thumbnailPaths: data.photoThumbnailPaths)
                  : const _CapturedPhotoPlaceholderRow(),
            ),
            Container(
              height: 20,

              // 눈금 개수는 totalCount가 아니라 가로 폭에 맞춰 채운다.
              // 첫 눈금은 왼쪽 간격 10부터, 이후 눈금끼리 간격 20.
              decoration: BoxDecoration(
                boxShadow: ChaerokShadows.card,
                color: const Color(0xFF21301F),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const tickWidth = 10.0;
                  const tickHeight = 8.0;
                  const gap = 20.0;
                  const leadingGap = 10.0;
                  final tickCount =
                      ((constraints.maxWidth + gap - leadingGap) /
                              (tickWidth + gap))
                          .floor()
                          .clamp(0, 1 << 20);
                  return Row(
                    children: [
                      for (var i = 0; i < tickCount; i++) ...[
                        SizedBox(width: i == 0 ? leadingGap : gap),
                        Container(
                          width: tickWidth,
                          height: tickHeight,
                          decoration: const BoxDecoration(
                            color: ChaerokColors.textDisabled,
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _CapturedPhotoRow extends StatelessWidget {
  const _CapturedPhotoRow({required this.thumbnailPaths});

  final List<String> thumbnailPaths;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _photoItemHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: thumbnailPaths.length,
        separatorBuilder: (_, _) => const SizedBox(width: _photoItemGap),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(_photoItemRadius),
            child: Image.file(
              File(thumbnailPaths[index]),
              width: _photoItemWidth,
              height: _photoItemHeight,
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}

/// 인증한 사진이 아직 없을 때 노출하는 회색 placeholder 슬롯 Row.
class _CapturedPhotoPlaceholderRow extends StatelessWidget {
  const _CapturedPhotoPlaceholderRow();

  static const int _slotCount = 3;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _photoItemHeight,
      child: Row(
        children: [
          for (var i = 0; i < _slotCount; i++) ...[
            if (i > 0) const SizedBox(width: _photoItemGap),
            Container(
              width: _photoItemWidth,
              height: _photoItemHeight,
              decoration: BoxDecoration(
                color: ChaerokColors.textDisabled,
                borderRadius: BorderRadius.circular(_photoItemRadius),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
