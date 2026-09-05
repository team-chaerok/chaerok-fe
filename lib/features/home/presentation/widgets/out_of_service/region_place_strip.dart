import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/place_category.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/place_image.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';

/// "OO에서 이런 장소를 만나보세요" 헤더 + 가로 스크롤 장소 카드 목록.
/// 헤더의 "전체보기"와 카드 탭 모두 채록길 탭 이동을 요청한다(부모가 처리).
class RegionPlaceStrip extends StatelessWidget {
  const RegionPlaceStrip({
    super.key,
    required this.region,
    required this.places,
    required this.onSeeAll,
  });

  final RegionCode region;
  final List<PlaceListResponse> places;
  final VoidCallback onSeeAll;

  static const int _maxCards = 10;
  static const double _cardWidth = 121; // Figma 근사. 토큰 없음.
  static const double _imageHeight = 81; // Figma 근사. 토큰 없음.

  @override
  Widget build(BuildContext context) {
    final visible = places.take(_maxCards).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${region.displayName}에서 이런 장소를 만나보세요',
                  style: ChaerokTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              InkWell(
                onTap: onSeeAll,
                child: Row(
                  children: [
                    Text(
                      '전체보기',
                      style: ChaerokTypography.caption.copyWith(
                        color: ChaerokColors.textDisabled,
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: ChaerokSpacing.sm,
                      color: ChaerokColors.textDisabled,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ChaerokSpacing.sm),
        SizedBox(
          height: 150, // 이미지 81 + 텍스트 2줄. Figma 근사, 토큰 없음.
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
            itemCount: visible.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: ChaerokSpacing.sm),
            itemBuilder: (context, index) => _PlaceCard(
              place: visible[index],
              mood: PlacePlaceholderMood
                  .values[index % PlacePlaceholderMood.values.length],
              onTap: onSeeAll,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.mood,
    required this.onTap,
  });

  final PlaceListResponse place;
  final PlacePlaceholderMood mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: RegionPlaceStrip._cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(ChaerokRadius.lg),
                topRight: Radius.circular(ChaerokRadius.lg),
              ),
              child: SizedBox(
                height: RegionPlaceStrip._imageHeight,
                width: double.infinity,
                child: PlaceImage(imageUrl: place.firstImageUrl, mood: mood),
              ),
            ),
            const SizedBox(height: ChaerokSpacing.xxs),
            Row(
              children: [
                const Icon(
                  Icons.place,
                  size: ChaerokSpacing.sm,
                  color: ChaerokColors.primaryDark,
                ),
                const SizedBox(width: 2), // 아이콘-텍스트 최소 간격. 토큰 없음.
                Expanded(
                  child: Text(
                    place.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ChaerokTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Text(
              PlaceExternalCategory.displayLabel(place.categoryDetail),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ChaerokTypography.caption.copyWith(
                color: ChaerokColors.textSecondary,
                fontSize: 10, // Figma 8px 근사, 가독성 위해 10. 토큰 없음.
              ),
            ),
          ],
        ),
      ),
    );
  }
}
