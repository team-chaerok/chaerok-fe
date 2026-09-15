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
/// 가장 최근) 사진을 보여준다. 카테고리 태그는 버튼이 아니라, 지금 보여주는
/// 사진의 카테고리에 맞춰 켜지는 표시등이다.
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

  String? _selectedPhotoId;

  Map<String, PlaceCategoryGroup> get _categoryByPlaceId => {
    for (final place in widget.places)
      place.id: resolvePlaceCategoryGroup(place.category),
  };

  List<FilmRollPhoto> _photosFor(PlaceCategoryGroup category) {
    final categoryByPlaceId = _categoryByPlaceId;
    final matched = widget.photos
        .where((photo) => categoryByPlaceId[photo.filmRollPlaceId] == category)
        .toList();
    matched.sort((a, b) => a.sequence.compareTo(b.sequence));
    return matched;
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

  FilmRollPhoto? _findById(String? id) {
    if (id == null) return null;
    for (final photo in widget.photos) {
      if (photo.id == id) return photo;
    }
    return null;
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

  /// 필름스트립 칸을 탭했을 때: 이미 인증(촬영)한 장소면 그 사진을 큰 사진
  /// 자리로 선택하고, 아직 안 간 장소면 카메라를 열어 바로 인증하게 한다.
  /// 위치(GPS)는 확인하지 않는다 — 카메라 화면 자체가 "이 장소를 인증
  /// 중"이라는 안내를 보여준다.
  Future<void> _onPlaceTileTap(
    FilmRollPlace place,
    FilmRollPhoto? photo,
  ) async {
    if (photo != null) {
      setState(() => _selectedPhotoId = photo.id);
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

  @override
  Widget build(BuildContext context) {
    // 명시적으로 고른 사진이 없으면 기본 카테고리(관광지)의 최근 사진으로
    // 폴백한다. 찍은 사진이 하나도 없으면(아래) 코스에 담긴 장소 미리보기를
    // 대신 보여준다(완전히 빈 화면 대신 "여기로 가볼까요" 느낌).
    final selected =
        _findById(_selectedPhotoId) ??
        _mostRecentOf(_photosFor(_defaultCategory));
    final previewPlace = selected == null ? _placeFor(_defaultCategory) : null;
    // 태그는 버튼이 아니라 지금 보여주는 사진의 카테고리를 가리키는 표시등 —
    // 고른 사진이 없으면 기본 카테고리가 켜진다.
    final displayCategory = selected == null
        ? _defaultCategory
        : _categoryByPlaceId[selected.filmRollPlaceId] ?? _defaultCategory;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroPhoto(photo: selected, previewPlace: previewPlace),
        const SizedBox(height: ChaerokSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
          child: Row(
            children: [
              for (final category in _categoryChips) ...[
                _CategoryChip(
                  label: _categoryLabels[category]!,
                  selected: category == displayCategory,
                ),
                const SizedBox(width: ChaerokSpacing.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: ChaerokSpacing.sm),
        _FilmStrip(
          places: _placesByCategoryOrder,
          photoForPlace: _photoForPlace,
          selectedPhotoId: selected?.id,
          onTap: _onPlaceTileTap,
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
}

class _HeroPhoto extends StatelessWidget {
  const _HeroPhoto({required this.photo, this.previewPlace});

  final FilmRollPhoto? photo;

  /// [photo]가 없을 때(아직 고른 사진이 없고 기본 카테고리에 찍은 사진도
  /// 없음) 대신 보여줄, 이미 코스에 담긴 장소. 내가 찍은 사진이 아님을
  /// 라벨로 구분한다.
  final FilmRollPlace? previewPlace;

  /// 필름 느낌을 내는 위아래 검은 띠 두께.
  static const double _filmEdgeHeight = 10;

  /// 사진 영역 세로 크기(검은 띠 제외, 순수 사진).
  static const double _photoHeight = 294;

  @override
  Widget build(BuildContext context) {
    final place = photo == null ? previewPlace : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const ColoredBox(
            color: Colors.black,
            child: SizedBox(width: double.infinity, height: _filmEdgeHeight),
          ),
          SizedBox(height: _photoHeight, child: _photo(context)),
          const ColoredBox(
            color: Colors.black,
            child: SizedBox(width: double.infinity, height: _filmEdgeHeight),
          ),
          if (place != null) ...[
            const SizedBox(height: ChaerokSpacing.xs),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ChaerokSpacing.md,
              ),
              child: Text(
                '가 볼 장소 · ${place.name}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ChaerokTypography.caption.copyWith(
                  color: ChaerokColors.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _photo(BuildContext context) {
    final current = photo;
    if (current != null) {
      return Image.file(
        File(current.originalPath),
        fit: BoxFit.cover,
        width: double.infinity,
        // 앱 재설치 등으로 원본 파일이 사라졌으면 회색 슬롯으로 폴백한다.
        errorBuilder: (context, error, stackTrace) =>
            const ColoredBox(color: ChaerokColors.surface),
      );
    }

    final place = previewPlace;
    if (place == null) {
      return const ColoredBox(color: ChaerokColors.surface);
    }
    return PlaceImage(
      imageUrl: place.imageUrl,
      mood: PlacePlaceholderMood.forest,
    );
  }
}

/// 관광지/식당/카페 태그 — 버튼이 아니라, 지금 큰 사진으로 보여주는 카테고리를
/// 가리키는 표시등이다(눌러도 아무 동작 없음).
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ChaerokSpacing.sm,
        vertical: ChaerokSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: selected ? ChaerokColors.primary : ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.sm),
        border: Border.all(
          color: selected ? ChaerokColors.primary : ChaerokColors.border,
        ),
      ),
      child: Text(
        label,
        style: ChaerokTypography.bodyMedium.copyWith(
          color: selected ? Colors.white : ChaerokColors.textSecondary,
        ),
      ),
    );
  }
}

/// 필름스트립 — 칸 하나하나가 코스 장소 하나하나에 대응한다. 인증(촬영)
/// 완료한 장소는 그 사진을, 아직 안 간 장소는 빈 프레임을 보여준다. 검은
/// 필름 띠 위아래에 스프라켓 구멍을 두르는 틀은 내용과 무관하게 항상
/// 유지한다(Figma node 37:1828 "빈 필름" 모양을 그대로 따른다).
class _FilmStrip extends StatelessWidget {
  const _FilmStrip({
    required this.places,
    required this.photoForPlace,
    required this.selectedPhotoId,
    required this.onTap,
  });

  final List<FilmRollPlace> places;
  final FilmRollPhoto? Function(FilmRollPlace place) photoForPlace;
  final String? selectedPhotoId;
  final void Function(FilmRollPlace place, FilmRollPhoto? photo) onTap;

  static const double _itemWidth = 118;
  static const double _itemHeight = 88;
  static const double _itemGap = ChaerokSpacing.sm;
  static const double _itemRadius = 2;
  static const double _edgeHeight = 4;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      key: const ValueKey('filmStripFrame'),
      color: ChaerokColors.cameraBlack,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _edgeHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _FilmSprocketRow(),
            const SizedBox(height: ChaerokSpacing.xxs),
            SizedBox(height: _itemHeight, child: _buildFrames()),
            const SizedBox(height: ChaerokSpacing.xxs),
            const _FilmSprocketRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildFrames() {
    if (places.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.xs),
      scrollDirection: Axis.horizontal,
      itemCount: places.length,
      separatorBuilder: (_, _) => const SizedBox(width: _itemGap),
      itemBuilder: (context, index) {
        final place = places[index];
        final photo = photoForPlace(place);
        final isSelected = photo != null && photo.id == selectedPhotoId;
        return GestureDetector(
          onTap: () => onTap(place, photo),
          child: Container(
            width: _itemWidth,
            height: _itemHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_itemRadius),
              border: isSelected
                  ? Border.all(color: ChaerokColors.primaryDark, width: 2)
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_itemRadius),
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
