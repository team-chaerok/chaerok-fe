import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/recommended_course_banner.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_carousel.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_place_strip.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/region/region_guide.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';

enum RegionLoadStatus { loading, ready, error }

/// 선택 지역 상세 패널. 상태에 따라 로딩/에러/빈값/본문을 그린다.
class RegionDetailPanel extends StatelessWidget {
  const RegionDetailPanel({
    super.key,
    required this.region,
    required this.status,
    required this.places,
    required this.onRetry,
    required this.onExploreRegionRequested,
  });

  final RegionCode region;
  final RegionLoadStatus status;
  final List<PlaceListResponse> places;
  final VoidCallback onRetry;
  final ValueChanged<RegionCode> onExploreRegionRequested;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case RegionLoadStatus.loading:
        return const Center(child: ChaerokLoadingIndicator());
      case RegionLoadStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '장소 정보를 불러오지 못했어요',
                style: ChaerokTypography.bodyMedium.copyWith(
                  color: ChaerokColors.textSecondary,
                ),
              ),
              const SizedBox(height: ChaerokSpacing.sm),
              TextButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ),
        );
      case RegionLoadStatus.ready:
        if (places.isEmpty) {
          return const Center(
            child: Text(
              '이 지역의 장소 정보가 없어요',
              style: ChaerokTypography.bodyMedium,
            ),
          );
        }
        return _Body(
          region: region,
          places: places,
          onExploreRegionRequested: onExploreRegionRequested,
        );
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.region,
    required this.places,
    required this.onExploreRegionRequested,
  });

  final RegionCode region;
  final List<PlaceListResponse> places;
  final ValueChanged<RegionCode> onExploreRegionRequested;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: ChaerokSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
            child: _RegionIntro(region: region),
          ),
          const SizedBox(height: ChaerokSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
            child: _HashtagRow(tags: region.guide.hashtags),
          ),
          const SizedBox(height: ChaerokSpacing.lg),
          RegionCarousel(places: places),
          const SizedBox(height: ChaerokSpacing.lg),
          RecommendedCourseBanner(
            region: region,
            onTap: () => onExploreRegionRequested(region),
          ),
          const SizedBox(height: ChaerokSpacing.xl),
          RegionPlaceStrip(
            region: region,
            places: places,
            onSeeAll: () => onExploreRegionRequested(region),
          ),
        ],
      ),
    );
  }
}

class _RegionIntro extends StatelessWidget {
  const _RegionIntro({required this.region});

  final RegionCode region;

  @override
  Widget build(BuildContext context) {
    final guide = region.guide;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          guide.romanized,
          style: ChaerokTypography.caption.copyWith(
            color: ChaerokColors.primaryDark,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: ChaerokSpacing.xxs),
        Text(
          region.displayName,
          style: const TextStyle(
            fontFamily: ChaerokTypography.jeongnimsajiFontFamily,
            fontWeight: FontWeight.w600, // pubspec Jeongnimsaji-L
            fontSize: 36, // Figma 36px 타이틀. 토큰 없음.
            color: ChaerokColors.primaryDark,
          ),
        ),
        const SizedBox(height: ChaerokSpacing.xxs),
        Text(
          guide.tagline,
          style: ChaerokTypography.bodyMedium.copyWith(
            color: ChaerokColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _HashtagRow extends StatelessWidget {
  const _HashtagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ChaerokSpacing.xs,
      runSpacing: ChaerokSpacing.xs,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ChaerokSpacing.xs,
              vertical: ChaerokSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: ChaerokColors.sageLight,
              borderRadius: BorderRadius.circular(ChaerokRadius.lg),
            ),
            child: Text(
              '# $tag',
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.primaryDark,
              ),
            ),
          ),
      ],
    );
  }
}
