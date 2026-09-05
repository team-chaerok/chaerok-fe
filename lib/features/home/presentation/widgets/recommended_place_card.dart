import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_shadows.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/place_image.dart';
import 'package:flutter/material.dart';

class RecommendedPlaceCard extends StatelessWidget {
  const RecommendedPlaceCard({
    super.key,
    required this.data,
    required this.onTap,
    this.isFeatured = false,
  });

  final RecommendedPlaceSummaryData data;
  final VoidCallback onTap;
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChaerokColors.surface,
      borderRadius: BorderRadius.circular(ChaerokRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ChaerokRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xFFFAF9F6),
            border: Border.all(color: const Color.fromRGBO(226, 228, 221, 1)),
            borderRadius: BorderRadius.circular(ChaerokRadius.lg),
            boxShadow: isFeatured ? ChaerokShadows.card : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ChaerokRadius.lg),
            child: isFeatured ? _buildFeatured() : _buildCompact(),
          ),
        ),
      ),
    );
  }

  /// 카드가 큰 형태로 표시되는 경우, 즉 추천 장소를 강조하는 경우.
  Widget _buildFeatured() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            AspectRatio(
              aspectRatio: 2,
              child: PlaceImage(
                imageUrl: data.imageUrl,
                mood: data.placeholderMood,
              ),
            ),
            if (data.isRecorded) const _RecordedBadge(),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ChaerokSpacing.sm,
            ChaerokSpacing.xs,
            ChaerokSpacing.sm,
            ChaerokSpacing.sm,
          ),
          child: _PlaceInformation(data: data),
        ),
      ],
    );
  }

  /// 카드가 작은 형태로 표시되는 경우, 즉 추천 장소를 강조하지 않는 경우.
  Widget _buildCompact() {
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          Stack(
            children: [
              SizedBox(
                width: 91,
                height: 68,
                child: PlaceImage(
                  imageUrl: data.imageUrl,
                  mood: data.placeholderMood,
                ),
              ),
              if (data.isRecorded) const _RecordedBadge(),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ChaerokSpacing.sm,
                vertical: ChaerokSpacing.xs,
              ),
              child: _PlaceInformation(data: data),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: ChaerokSpacing.sm),
            child: Icon(
              Icons.chevron_right_rounded,
              color: ChaerokColors.textSecondary,
              size: ChaerokSpacing.lg,
            ),
          ),
        ],
      ),
    );
  }
}

/// 현재 진행중 필름롤에서 이미 채록(방문)을 완료한 장소임을 알리는 뱃지.
class _RecordedBadge extends StatelessWidget {
  const _RecordedBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: ChaerokSpacing.xxs,
      left: ChaerokSpacing.xxs,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: ChaerokColors.primaryDark,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_rounded,
          color: ChaerokColors.surface,
          size: ChaerokSpacing.sm,
        ),
      ),
    );
  }
}

class _PlaceInformation extends StatelessWidget {
  const _PlaceInformation({required this.data});

  final RecommendedPlaceSummaryData data;

  @override
  Widget build(BuildContext context) {
    final distance = data.distance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ChaerokTypography.bodyLarge,
        ),
        const SizedBox(height: ChaerokSpacing.xxs),
        Row(
          children: [
            Flexible(
              child: Text(
                data.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ChaerokTypography.caption.copyWith(
                  color: ChaerokColors.textSecondary,
                ),
              ),
            ),
            if (distance != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: ChaerokSpacing.xs),
                child: SizedBox(
                  width: 2,
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ChaerokColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Text(
                distance,
                style: ChaerokTypography.caption.copyWith(
                  color: ChaerokColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
