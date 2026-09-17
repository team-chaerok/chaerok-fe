import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/place_category.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_photo.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/visit_category_progress.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/page/visit_capture_screen.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/place_detail_sheet.dart';
import 'package:chaerok/features/home/presentation/widgets/place_image.dart';
import 'package:flutter/material.dart';

const _tag = 'RegionPhotoGallery';

/// 카테고리 칩 표시 순서. 관광/식당/카페·디저트 3그룹만 다룬다([unknown] 제외).
const List<PlaceCategoryGroup> _categoryChips = [
  PlaceCategoryGroup.tourism,
  PlaceCategoryGroup.food,
  PlaceCategoryGroup.cafeDessert,
];

const Map<PlaceCategoryGroup, String> _categoryLabels = {
  PlaceCategoryGroup.tourism: '관광지',
  PlaceCategoryGroup.food: '식당',
  PlaceCategoryGroup.cafeDessert: '카페',
};

/// "현재여행지역" 카드의 필름롤 사진 갤러리. 필름스트립은 관광지→식당→카페
/// 순으로 코스에 담긴 장소를 한 칸씩 보여준다 — 인증(촬영) 완료한 장소는 그
/// 사진을, 아직 안 간 장소는 빈 칸을 보여주고 탭하면 그 장소를 인증하는
/// 카메라 화면으로 이어진다. 위쪽 큰 사진은 그중 고른(또는 기본값인 관광지의
/// 가장 최근) 사진을 보여준다. 카테고리 태그는 버튼이 아니라 각 칸 중앙 위에
/// 개별로 뜨며, 그 칸이 지금 큰 사진으로 보여주는 사진이면 초록색으로 켜진다.
class RegionPhotoGallery extends StatefulWidget {
  const RegionPhotoGallery({
    super.key,
    required this.filmRollId,
    required this.photos,
    required this.places,
    required this.onVisitCompleted,
  });

  /// 인증 카메라([VisitCaptureScreen])를 열 때 필요한 이 필름롤의 id.
  final String filmRollId;

  /// 이 필름롤에서 촬영된 전체 사진(최대 [FilmRoll.maxExposureCount]장).
  final List<FilmRollPhoto> photos;

  /// 코스에 담긴 장소 목록. 필름스트립 칸 하나하나가 이 장소 하나하나와 대응한다.
  final List<FilmRollPlace> places;

  /// 미방문 장소를 카메라로 인증하고 돌아오면 호출한다 — 부모가 최신 방문/
  /// 사진 상태를 다시 읽어와야 이 위젯도 갱신된 [photos]/[places]를 받는다.
  final Future<void> Function() onVisitCompleted;

  @override
  State<RegionPhotoGallery> createState() => _RegionPhotoGalleryState();
}

class _RegionPhotoGalleryState extends State<RegionPhotoGallery> {
  /// 아직 사진을 하나도 고르지 않았을 때 큰 사진·태그가 기본으로 가리키는
  /// 카테고리.
  static const _defaultCategory = PlaceCategoryGroup.tourism;

  /// 큰 사진이 지금 가리키는 [_placesByCategoryOrder] 안의 인덱스. 필름스트립
  /// 탭·큰 사진 좌우 스와이프 둘 다 이 값을 갱신하는 단일 소스다.
  late int _heroIndex;
  late final PageController _heroController;

  @override
  void initState() {
    super.initState();
    _heroIndex = _initialHeroIndex();
    _heroController = PageController(initialPage: _heroIndex);
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  /// 코스에 담긴 장소가 없으면 0(빈 상태), 있으면 기본 카테고리(관광지)에서
  /// 아직 안 간 장소를 우선하고(방문 순서대로) 없으면 그 카테고리의 첫 장소를
  /// 가리키는 인덱스.
  int _initialHeroIndex() {
    final orderedPlaces = _placesByCategoryOrder;
    if (orderedPlaces.isEmpty) return 0;
    final defaultPlace = _placeFor(_defaultCategory);
    if (defaultPlace == null) return 0;
    final index = orderedPlaces.indexWhere((p) => p.id == defaultPlace.id);
    return index < 0 ? 0 : index;
  }

  /// 필름스트립에 보여줄 코스 장소 전체 — 관광지→식당→카페 순으로 묶고,
  /// 묶음 안에서는 코스 방문 순서(visitOrder)대로 정렬한다. 칸 하나하나가
  /// 사진이 아니라 장소 하나하나에 대응한다.
  List<FilmRollPlace> get _placesByCategoryOrder {
    final byCategory = <PlaceCategoryGroup, List<FilmRollPlace>>{};
    for (final place in widget.places) {
      final category = resolvePlaceCategoryGroup(place.category);
      (byCategory[category] ??= []).add(place);
    }
    final result = <FilmRollPlace>[];
    for (final category in _categoryChips) {
      final matches = (byCategory[category] ?? const <FilmRollPlace>[]).toList()
        ..sort((a, b) => a.visitOrder.compareTo(b.visitOrder));
      result.addAll(matches);
    }
    return result;
  }

  /// 장소 하나의 대표 사진(여러 장 찍었다면 가장 최근 것). 아직 안 찍었으면 null.
  FilmRollPhoto? _photoForPlace(FilmRollPlace place) {
    return _mostRecentOf(
      widget.photos
          .where((photo) => photo.filmRollPlaceId == place.id)
          .toList(),
    );
  }

  FilmRollPhoto? _mostRecentOf(List<FilmRollPhoto> photos) {
    if (photos.isEmpty) return null;
    return photos.reduce((a, b) => a.takenAt.isAfter(b.takenAt) ? a : b);
  }

  /// 아직 사진이 없을 때 큰 사진 자리에 보여줄, 이미 코스에 넣어둔 장소.
  /// 아직 안 가본 장소를 우선하고(방문 순서대로), 카테고리에 담긴 장소가
  /// 없으면 null(그때는 빈 placeholder로 폴백).
  FilmRollPlace? _placeFor(PlaceCategoryGroup category) {
    final matches =
        widget.places
            .where(
              (place) => resolvePlaceCategoryGroup(place.category) == category,
            )
            .toList()
          ..sort((a, b) => a.visitOrder.compareTo(b.visitOrder));
    if (matches.isEmpty) return null;
    return matches.firstWhere(
      (place) => !place.isVisited,
      orElse: () => matches.first,
    );
  }

  /// 큰 사진을 [place]가 있는 페이지로 이동시킨다(필름스트립 태그·이미 인증된
  /// 사진 타일 탭이 공유하는 동작). 코스에 없는 장소면 아무것도 하지 않는다.
  void _jumpHeroTo(FilmRollPlace place) {
    final index = _placesByCategoryOrder.indexWhere((p) => p.id == place.id);
    if (index < 0) return;
    setState(() => _heroIndex = index);
    if (_heroController.hasClients) {
      _heroController.jumpToPage(index);
    }
  }

  /// 필름스트립 칸을 탭했을 때: 이미 인증(촬영)한 장소면 그 사진을 큰 사진
  /// 자리로 선택하고, 아직 안 간 장소면 카메라를 열어 바로 인증하게 한다.
  /// 위치(GPS)는 확인하지 않는다 — 카메라 화면 자체가 "이 장소를 인증
  /// 중"이라는 안내를 보여준다.
  Future<void> _onPlaceTileTap(
    FilmRollPlace place,
    FilmRollPhoto? photo,
  ) async {
    if (photo != null) {
      _jumpHeroTo(place);
      return;
    }

    final captured = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VisitCaptureScreen(
          filmRollId: widget.filmRollId,
          filmRollPlaceId: place.id,
        ),
      ),
    );
    if (captured != true || !mounted) return;

    try {
      await FilmRollModule.instance.completeVisit(place.id);
    } catch (e, st) {
      log('방문 완료 처리 실패', name: _tag, error: e, stackTrace: st);
    }
    await widget.onVisitCompleted();
  }

  /// 큰 사진을 탭했을 때 그 칸이 가리키는 장소의 상세 정보를 바텀시트로
  /// 보여준다. 인증 여부와 무관하게 열리며, 촬영한 사진이 있으면 그 사진들을
  /// 함께 보여준다([PlaceDetailSheet] 참고).
  Future<void> _showPlaceDetailSheet(FilmRollPlace place) {
    final placePhotos = widget.photos
        .where((photo) => photo.filmRollPlaceId == place.id)
        .toList();
    return showPlaceDetailSheet(
      context,
      place: PlaceDetailSheetPlace.fromFilmRollPlace(place),
      photos: placePhotos,
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderedPlaces = _placesByCategoryOrder;
    final safeIndex = orderedPlaces.isEmpty
        ? 0
        : _heroIndex.clamp(0, orderedPlaces.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHero(orderedPlaces, safeIndex),
        const SizedBox(height: ChaerokSpacing.sm),
        _FilmStrip(
          places: orderedPlaces,
          photoForPlace: _photoForPlace,
          selectedIndex: safeIndex,
          onTap: _onPlaceTileTap,
          onTagTap: _jumpHeroTo,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ChaerokSpacing.md,
            vertical: ChaerokSpacing.xs,
          ),
          child: Row(
            children: [
              Text(
                '${widget.photos.length} / ${FilmRoll.maxExposureCount}',
                style: ChaerokTypography.bodyLarge,
              ),
              const SizedBox(width: ChaerokSpacing.xs),
              const Icon(
                Icons.info_outline,
                size: 14,
                color: ChaerokColors.textSecondary,
              ),
              const SizedBox(width: ChaerokSpacing.xxs),
              Text(
                '지역 내 최대 ${FilmRoll.maxExposureCount}장',
                style: ChaerokTypography.caption.copyWith(
                  color: ChaerokColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 필름 느낌을 내는 위아래 검은 띠 두께.
  static const double _heroFilmEdgeHeight = 10;

  /// 사진 영역 세로 크기(검은 띠 제외, 순수 사진).
  static const double _heroPhotoHeight = 294;

  /// 큰 사진 — 코스 장소 순서(관광지→식당→카페, 각 묶음 안에서는 방문 순서)
  /// 그대로 좌우로 스와이프된다. 인증(촬영)한 장소는 그 사진을, 아직 안 간
  /// 장소는 "가 볼 장소" 미리보기를 보여준다.
  Widget _buildHero(List<FilmRollPlace> places, int index) {
    final pageCount = places.isEmpty ? 1 : places.length;
    final currentPlace = places.isEmpty ? null : places[index];
    final currentPhoto = currentPlace == null
        ? null
        : _photoForPlace(currentPlace);
    final previewPlace = currentPhoto == null ? currentPlace : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const ColoredBox(
            color: Colors.black,
            child: SizedBox(
              width: double.infinity,
              height: _heroFilmEdgeHeight,
            ),
          ),
          SizedBox(
            height: _heroPhotoHeight,
            child: PageView.builder(
              controller: _heroController,
              itemCount: pageCount,
              onPageChanged: (i) => setState(() => _heroIndex = i),
              itemBuilder: (context, i) {
                if (places.isEmpty) {
                  return const ColoredBox(color: ChaerokColors.surface);
                }
                final place = places[i];
                return GestureDetector(
                  onTap: () => _showPlaceDetailSheet(place),
                  child: _heroSlide(context, _photoForPlace(place), place),
                );
              },
            ),
          ),
          const ColoredBox(
            color: Colors.black,
            child: SizedBox(
              width: double.infinity,
              height: _heroFilmEdgeHeight,
            ),
          ),
          if (previewPlace != null) ...[
            const SizedBox(height: ChaerokSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ChaerokSpacing.md,
              ),
              child: Text(
                '가 볼 장소 · ${previewPlace.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ChaerokTypography.bodyMedium.copyWith(
                  color: ChaerokColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _heroSlide(
    BuildContext context,
    FilmRollPhoto? photo,
    FilmRollPlace previewPlace,
  ) {
    if (photo != null) {
      // 카메라 원본 해상도를 그대로 디코딩하면, 스와이프로 지나간 페이지도
      // PageView가 keep-alive로 살려둔 채 여러 장이 한꺼번에 메모리에
      // 올라가 디코딩 실패(→ errorBuilder 회색 슬롯)로 이어질 수 있다.
      // 실제 표시 높이로 다운샘플링해 디코딩 메모리를 크게 줄인다.
      final cacheHeight =
          (_heroPhotoHeight * MediaQuery.of(context).devicePixelRatio).round();
      return Image.file(
        File(photo.originalPath),
        fit: BoxFit.cover,
        width: double.infinity,
        cacheHeight: cacheHeight,
        // 앱 재설치 등으로 원본 파일이 사라졌으면 회색 슬롯으로 폴백한다.
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: ChaerokColors.surface),
      );
    }
    return PlaceImage(
      imageUrl: previewPlace.imageUrl,
      mood: PlacePlaceholderMood.forest,
    );
  }
}

/// 필름스트립 각 칸 위에 뜨는 카테고리 태그. 그 칸이 지금 큰 사진으로 보여주는
/// 사진(선택된 상태)이면 초록색으로 켜진다 — 사진 테두리 대신 이 태그 색이
/// 선택 표시를 대신한다.
class _CategoryTag extends StatelessWidget {
  const _CategoryTag({required this.label, required this.selected});

  final String label;
  final bool selected;

  static const double _height = 20;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _height,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ChaerokSpacing.xs,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: selected ? ChaerokColors.primary : ChaerokColors.surface,
            borderRadius: BorderRadius.circular(ChaerokRadius.sm),
          ),
          child: Text(
            label,
            style: ChaerokTypography.caption.copyWith(
              color: selected ? Colors.white : ChaerokColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 필름스트립 — 칸 하나하나가 코스 장소 하나하나에 대응한다. 인증(촬영)
/// 완료한 장소는 그 사진을, 아직 안 간 장소는 빈 프레임을 보여준다. 검은
/// 필름 띠 위아래에 스프라켓 구멍을 두르는 틀은 내용과 무관하게 항상
/// 유지한다(Figma node 37:1828 "빈 필름" 모양을 그대로 따른다). 카테고리
/// 태그는 이 검은 틀 밖, 각 칸 중앙 바로 위에 별도 줄로 떠 있고(선택된 칸은
/// 초록색), 필름스트립을 옆으로 넘기면 같이 따라 움직인다.
class _FilmStrip extends StatefulWidget {
  const _FilmStrip({
    required this.places,
    required this.photoForPlace,
    required this.selectedIndex,
    required this.onTap,
    required this.onTagTap,
  });

  final List<FilmRollPlace> places;
  final FilmRollPhoto? Function(FilmRollPlace place) photoForPlace;

  /// 지금 큰 사진이 가리키는 [places] 안의 인덱스 — 그 칸의 카테고리 태그만
  /// 초록색으로 켠다.
  final int selectedIndex;
  final void Function(FilmRollPlace place, FilmRollPhoto? photo) onTap;

  /// 카테고리 태그를 탭했을 때 — 방문 여부와 무관하게 큰 사진만 그 장소로
  /// 스와이프한다(사진 타일 탭과 달리 카메라로 이어지지 않는다).
  final void Function(FilmRollPlace place) onTagTap;

  @override
  State<_FilmStrip> createState() => _FilmStripState();
}

class _FilmStripState extends State<_FilmStrip> {
  static const double _itemWidth = 118;
  static const double _itemHeight = 88;
  static const double _itemGap = ChaerokSpacing.sm;
  static const double _itemRadius = 2;
  static const double _edgeHeight = 4;
  static const double _tagGap = ChaerokSpacing.xxs;

  final _tagScrollController = ScrollController();
  final _photoScrollController = ScrollController();
  bool _isSyncingScroll = false;

  @override
  void initState() {
    super.initState();
    _tagScrollController.addListener(
      () => _syncScroll(_tagScrollController, _photoScrollController),
    );
    _photoScrollController.addListener(
      () => _syncScroll(_photoScrollController, _tagScrollController),
    );
  }

  /// 태그 줄과 사진 줄이 같은 칸 너비/간격을 쓰므로 스크롤 오프셋을 그대로
  /// 맞춰도 나란히 정렬된다. 한쪽이 다른 쪽을 갱신하다가 다시 리스너를
  /// 트리거해 무한루프에 빠지지 않도록 플래그로 막는다.
  void _syncScroll(ScrollController from, ScrollController to) {
    if (_isSyncingScroll || !from.hasClients || !to.hasClients) return;
    final target = from.offset.clamp(
      to.position.minScrollExtent,
      to.position.maxScrollExtent,
    );
    if (target == to.offset) return;
    _isSyncingScroll = true;
    to.jumpTo(target);
    _isSyncingScroll = false;
  }

  @override
  void dispose() {
    _tagScrollController.dispose();
    _photoScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: _CategoryTag._height, child: _buildTags()),
        const SizedBox(height: _tagGap),
        ColoredBox(
          key: const ValueKey('filmStripFrame'),
          color: ChaerokColors.cameraBlack,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: _edgeHeight),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _FilmSprocketRow(),
                const SizedBox(height: ChaerokSpacing.xxs),
                SizedBox(height: _itemHeight, child: _buildPhotos()),
                const SizedBox(height: ChaerokSpacing.xxs),
                const _FilmSprocketRow(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    if (widget.places.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      controller: _tagScrollController,
      padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.xs),
      scrollDirection: Axis.horizontal,
      itemCount: widget.places.length,
      separatorBuilder: (_, _) => const SizedBox(width: _itemGap),
      itemBuilder: (context, index) {
        final place = widget.places[index];
        final isSelected = index == widget.selectedIndex;
        final category = resolvePlaceCategoryGroup(place.category);
        return SizedBox(
          width: _itemWidth,
          child: GestureDetector(
            onTap: () => widget.onTagTap(place),
            child: _CategoryTag(
              label: _categoryLabels[category] ?? '',
              selected: isSelected,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotos() {
    if (widget.places.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      controller: _photoScrollController,
      padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.xs),
      scrollDirection: Axis.horizontal,
      itemCount: widget.places.length,
      separatorBuilder: (_, _) => const SizedBox(width: _itemGap),
      itemBuilder: (context, index) {
        final place = widget.places[index];
        final photo = widget.photoForPlace(place);
        return GestureDetector(
          onTap: () => widget.onTap(place, photo),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_itemRadius),
            child: SizedBox(
              width: _itemWidth,
              height: _itemHeight,
              child: photo != null
                  ? Image.file(
                      File(photo.thumbnailPath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: ChaerokColors.textDisabled),
                    )
                  // 아직 인증(촬영) 전인 빈 프레임. 탭하면 그 장소를 인증하는
                  // 카메라가 열린다.
                  : const ColoredBox(color: ChaerokColors.border),
            ),
          ),
        );
      },
    );
  }
}

/// 필름 가장자리의 스프라켓 구멍 한 줄. 가용 너비에 맞춰 개수를 계산해
/// 고르게 채운다.
class _FilmSprocketRow extends StatelessWidget {
  const _FilmSprocketRow();

  static const double _holeWidth = 8;
  static const double _holeHeight = 4;
  static const double _pitch = 20;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final holeCount = (constraints.maxWidth / _pitch).floor();
        return SizedBox(
          height: _holeHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < holeCount; i++)
                const SizedBox(
                  width: _holeWidth,
                  height: _holeHeight,
                  child: ColoredBox(color: ChaerokColors.background),
                ),
            ],
          ),
        );
      },
    );
  }
}
