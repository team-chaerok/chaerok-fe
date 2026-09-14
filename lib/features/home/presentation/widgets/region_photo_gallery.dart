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
import 'package:flutter/material.dart';

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

/// "현재여행지역" 카드의 필름롤 사진 갤러리. 위쪽 큰 사진은 필름스트립에서
/// 고른(또는 활성 카테고리의 가장 최근) 사진을 보여주고, 카테고리 칩으로
/// 필름스트립을 관광지/식당/카페 단위로 필터링한다.
class RegionPhotoGallery extends StatefulWidget {
  const RegionPhotoGallery({
    super.key,
    required this.photos,
    required this.places,
  });

  /// 이 필름롤에서 촬영된 전체 사진(최대 [FilmRoll.maxExposureCount]장).
  final List<FilmRollPhoto> photos;

  /// 사진의 [FilmRollPhoto.filmRollPlaceId] → 카테고리를 알아내기 위한 장소 목록.
  final List<FilmRollPlace> places;

  @override
  State<RegionPhotoGallery> createState() => _RegionPhotoGalleryState();
}

class _RegionPhotoGalleryState extends State<RegionPhotoGallery> {
  PlaceCategoryGroup _activeCategory = PlaceCategoryGroup.tourism;
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

  void _onCategoryTap(PlaceCategoryGroup category) {
    if (category == _activeCategory) return;
    setState(() {
      _activeCategory = category;
      _selectedPhotoId = null;
    });
  }

  void _onThumbnailTap(FilmRollPhoto photo) {
    setState(() => _selectedPhotoId = photo.id);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _photosFor(_activeCategory);
    // 명시적으로 고른 사진이 없으면 활성 카테고리의 최근 사진, 그마저 없으면
    // 전체 중 최근 사진으로 폴백한다.
    final fallback = _mostRecentOf(filtered) ?? _mostRecentOf(widget.photos);
    final selected = _findById(_selectedPhotoId) ?? fallback;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _HeroPhoto(photo: selected)),
        const SizedBox(height: ChaerokSpacing.sm),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
          child: Row(
            children: [
              for (final category in _categoryChips) ...[
                _CategoryChip(
                  label: _categoryLabels[category]!,
                  selected: category == _activeCategory,
                  onTap: () => _onCategoryTap(category),
                ),
                const SizedBox(width: ChaerokSpacing.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: ChaerokSpacing.sm),
        _FilmStrip(
          photos: filtered,
          selectedId: selected?.id,
          onTap: _onThumbnailTap,
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
  const _HeroPhoto({required this.photo});

  final FilmRollPhoto? photo;

  @override
  Widget build(BuildContext context) {
    final current = photo;
    if (current == null) {
      return const ColoredBox(color: ChaerokColors.surface);
    }
    return Image.file(
      File(current.originalPath),
      fit: BoxFit.cover,
      width: double.infinity,
      // 앱 재설치 등으로 원본 파일이 사라졌으면 회색 슬롯으로 폴백한다.
      errorBuilder: (context, error, stackTrace) =>
          const ColoredBox(color: ChaerokColors.surface),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ChaerokRadius.sm),
      child: Container(
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
      ),
    );
  }
}

class _FilmStrip extends StatelessWidget {
  const _FilmStrip({
    required this.photos,
    required this.selectedId,
    required this.onTap,
  });

  final List<FilmRollPhoto> photos;
  final String? selectedId;
  final ValueChanged<FilmRollPhoto> onTap;

  static const double _itemWidth = 105;
  static const double _itemHeight = 64;
  static const double _itemGap = 14;
  static const double _itemRadius = 2;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) {
      return const SizedBox(
        height: _itemHeight,
        child: Center(
          child: Text('이 카테고리에는 아직 사진이 없어요', style: ChaerokTypography.caption),
        ),
      );
    }
    return SizedBox(
      height: _itemHeight,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: _itemGap),
        itemBuilder: (context, index) {
          final photo = photos[index];
          final isSelected = photo.id == selectedId;
          return GestureDetector(
            onTap: () => onTap(photo),
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
                child: Image.file(
                  File(photo.thumbnailPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: ChaerokColors.textDisabled),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
