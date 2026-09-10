import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/film_card_frame.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/film_tab.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/recommended_course_banner.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_carousel.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_palette.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_photo.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_load_status.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_place_strip.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/region/region_guide.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';

/// 필름롤 스택의 카드 한 장. 상단 탭 + 지역 상세 본문을 필름 프레임
/// ([FilmCardFrame]) 안에 담는다. 본문은 카드 내부에서 스크롤되며,
/// [status]에 따라 로딩/에러/빈값/본문을 그린다.
///
/// [opened]가 맨 앞(열린) 카드 여부다. 겹쳐서 가려지는 카드는 [opened]를
/// false로 줘 탭만 그리고, 그 탭을 누르면 [onTabTap]으로 전환을 요청한다.
class RegionFilmCard extends StatelessWidget {
  const RegionFilmCard({
    super.key,
    required this.region,
    required this.status,
    required this.places,
    required this.onRetry,
    required this.onExploreRegionRequested,
    this.opened = true,
    this.onTabTap,
  });

  final RegionCode region;
  final RegionLoadStatus status;
  final List<PlaceListResponse> places;
  final VoidCallback onRetry;
  final ValueChanged<RegionCode> onExploreRegionRequested;

  /// 스택 맨 앞(열린) 카드인지. 탭 강조·펼침 아이콘·그림자에 반영되고,
  /// false면 본문 없이 탭만 그린다(뒤에서 가려지는 카드).
  final bool opened;

  /// 겹친 탭을 눌렀을 때. 열린 카드는 null.
  final VoidCallback? onTabTap;

  /// 겹친 카드 본문 오른쪽 위에 깔리는 지역 사진 스트립 크기. 폴더 탭이
  /// 튀어나오는 높이([FilmTab.tabHeight]) 아래, 즉 본문 영역에 놓아 폴더
  /// 클리핑에 잘리지 않게 한다. 열린 카드에는 없다. 토큰 없음.
  static const double _photoStripWidth = 88;
  static const double _photoStripHeight = 148;

  @override
  Widget build(BuildContext context) {
    return FilmCardFrame(
      elevated: opened,
      folderTop: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FilmTab(
                label: region.filmStripLabel,
                opened: opened,
                color: region.filmTabColor,
                onTap: onTabTap,
              ),
              Expanded(child: opened ? _content() : const SizedBox.shrink()),
            ],
          ),
          // 열린 카드는 본문이 꽉 차므로 사진 스트립을 두지 않는다. 겹쳐서
          // 탭 + 사진 슬라이스만 보이는 카드에서만 본문 오른쪽 위에 깐다.
          if (!opened)
            Positioned(
              top: FilmTab.tabHeight,
              right: 0,
              width: _photoStripWidth,
              height: _photoStripHeight,
              child: IgnorePointer(child: RegionFilmPhoto(region: region)),
            ),
        ],
      ),
    );
  }

  Widget _content() {
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
    return ColoredBox(
      // 지역 색을 본문 바탕에 아주 옅게 깐다. 인트로 텍스트가 어두운색이라
      // alpha는 낮게 유지한다(진하게 하려면 이 값을 올린다).
      color: region.filmTabColor.withValues(alpha: 0.08),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: ChaerokSpacing.xxl),
        child: Container(
          decoration: BoxDecoration(color: region.filmTabColor),
          child: Container(
            decoration: const BoxDecoration(
              color: ChaerokColors.background,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(ChaerokRadius.lg),
                topRight: Radius.circular(ChaerokRadius.lg),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChaerokSpacing.md,
                  ),
                  child: _RegionIntro(region: region),
                ),
                const SizedBox(height: ChaerokSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChaerokSpacing.md,
                  ),
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
          ),
        ),
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
