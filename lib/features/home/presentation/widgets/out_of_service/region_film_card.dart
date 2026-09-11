import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/folder_card_shape.dart';
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

/// 스크롤되는 본문(크림 영역) 상단 좌우 모서리 반경.
const BorderRadius _bodyTopRadius = BorderRadius.vertical(
  top: Radius.circular(ChaerokRadius.lg),
);

/// 필름롤 스택의 폴더 탭 카드 한 장([FolderCardClipper]로 클리핑).
/// [opened]면 탭 아래 본문 영역에 [RegionDetailBody]를, 아니면 지역 사진을
/// 오른쪽 위에 깐다. 탭(왼쪽 위)에는 "{지역} 필름롤" 라벨만 얹는다.
/// 탭 여부에 따른 터치 처리는 부모([RegionFilmDeck])가 카드 전체를 감싼다.
class RegionFilmCard extends StatelessWidget {
  const RegionFilmCard({
    super.key,
    required this.region,
    required this.status,
    required this.places,
    required this.onRetry,
    required this.onExploreRegionRequested,
    this.opened = true,
  });

  final RegionCode region;
  final RegionLoadStatus status;
  final List<PlaceListResponse> places;
  final VoidCallback onRetry;
  final ValueChanged<RegionCode> onExploreRegionRequested;

  /// 스택 맨 앞(열린) 카드인지. false면 본문 대신 지역 사진만 얹는다.
  final bool opened;

  /// 겹친 카드 오른쪽 위 지역 사진 자리 크기. 폴더 탭이 튀어나오는 높이
  /// ([FolderCardClipper.cardTop]) 아래, 즉 본문 영역에 둔다. 토큰 없음.
  static const double _photoWidth = 150;
  static const double _photoHeight = 80;

  /// 지역 사진 자리 위젯의 key(테스트/추후 교체용).
  static const Key photoSlotKey = Key('regionFilmPhotoSlot');

  /// 탭 라벨 위치. 토큰 없음.
  static const double _labelTop = 6;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: const FolderCardShadowPainter(),
      foregroundPainter: const FolderCardInnerShadowPainter(),
      child: ClipPath(
        clipper: const FolderCardClipper(),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: region.filmTabColor),
            if (opened)
              Positioned(
                top: FolderCardClipper.cardTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: ColoredBox(
                  color: ChaerokColors.primaryLight,
                  child: RegionDetailBody(
                    region: region,
                    status: status,
                    places: places,
                    onRetry: onRetry,
                    onExploreRegionRequested: onExploreRegionRequested,
                  ),
                ),
              )
            else
              // 에셋(assets/images/regions/{region}.webp)이 아직 없으면
              // RegionFilmPhoto가 지역색 블록으로 폴백한다.
              Positioned(
                top: FolderCardClipper.cardTop,
                right: 0,
                width: _photoWidth,
                height: _photoHeight,
                child: RegionFilmPhoto(key: photoSlotKey, region: region),
              ),
            Positioned(
              left: ChaerokSpacing.md,
              top: _labelTop,
              child: Text(
                region.filmStripLabel,
                style: TextStyle(
                  fontFamily: ChaerokTypography.jeongnimsajiFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 16, // Figma 근사. 토큰 없음.
                  // 예산은 탭 배경이 밝은 크림색이라 흰 라벨이 안 읽혀
                  // 어두운 올리브로 고정한다. 나머지는 어두운 탭 위 흰색.
                  color: region == RegionCode.yesan
                      ? const Color(0xFF45523D)
                      : (opened ? Colors.white : Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 열린 필름롤 카드의 본문. [status]에 따라 로딩/에러/빈값/상세를 그린다.
/// 프레임·탭 없이 본문만 담당하므로 다른 컨테이너 안에서도 재사용할 수 있다.
class RegionDetailBody extends StatelessWidget {
  const RegionDetailBody({
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
    return DecoratedBox(
      // 배경(오버스크롤로 당겼을 때 드러나는 색) = 폴더 카드 색. 여긴 라운드 없음.
      decoration: BoxDecoration(color: region.filmTabColor),
      child: _content(),
    );
  }

  /// 로딩/에러/빈값 상태를 감싸는 크림 표면. 스크롤되는 본문과 똑같이 상단
  /// 좌우 모서리만 [_bodyTopRadius]로 둥글게.
  Widget _surface({required Widget child}) => DecoratedBox(
    decoration: const BoxDecoration(
      color: ChaerokColors.primaryLight,
      borderRadius: _bodyTopRadius,
    ),
    child: Center(child: child),
  );

  Widget _content() {
    switch (status) {
      case RegionLoadStatus.loading:
        return _surface(child: const ChaerokLoadingIndicator());
      case RegionLoadStatus.error:
        return _surface(
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
          return _surface(
            child: const Text(
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
      // 크림 바탕은 스크롤 내용과 함께 움직인다. 아래로 당기면 그 뒤의
      // 지역 색이 드러난다(RegionDetailBody 참고). 상단 좌우만 라운드.
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: ChaerokColors.primaryLight,
          borderRadius: _bodyTopRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: ChaerokSpacing.xxl),
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
        const SizedBox(height: ChaerokSpacing.lg),
        Text(
          guide.romanized,
          style: ChaerokTypography.caption.copyWith(
            color: ChaerokColors.primaryDark,
            letterSpacing: 2,
          ),
        ),
        Text(
          region.displayName,
          style: const TextStyle(
            fontFamily: ChaerokTypography.jeongnimsajiFontFamily,
            fontWeight: FontWeight.w500, // pubspec Jeongnimsaji-L
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
