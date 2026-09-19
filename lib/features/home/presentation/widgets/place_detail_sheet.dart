import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/place_category.dart';
import 'package:chaerok/data/models/place_detail_response.dart';
import 'package:chaerok/data/remote/places_api.dart';
import 'package:chaerok/features/explore/data/bookmark_store.dart';
import 'package:chaerok/features/explore/domain/explore_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_photo.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/visit_category_progress.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/place_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const _tag = 'PlaceDetailSheet';

/// 카테고리 그룹 한글 라벨(해시태그·추천 문구 생성에 쓴다).
const Map<PlaceCategoryGroup, String> _groupLabels = {
  PlaceCategoryGroup.tourism: '관광지',
  PlaceCategoryGroup.food: '식당',
  PlaceCategoryGroup.cafeDessert: '카페·디저트',
};

/// 소분류 한글 라벨. TourAPI/Kakao가 응답에 그대로 주는 값이 아니라, 이 앱이
/// 분류 코드([PlaceCategoryDetail])만으로 직접 만들어 붙이는 표시용 문구다.
const Map<PlaceCategoryDetail, String> _detailLabels = {
  PlaceCategoryDetail.heritage: '문화유산',
  PlaceCategoryDetail.museum: '박물관',
  PlaceCategoryDetail.walk: '산책로',
  PlaceCategoryDetail.market: '전통시장',
  PlaceCategoryDetail.souvenirShop: '기념품',
  PlaceCategoryDetail.nature: '자연명소',
  PlaceCategoryDetail.experience: '체험',
  PlaceCategoryDetail.restaurant: '맛집',
  PlaceCategoryDetail.localFood: '향토음식',
  PlaceCategoryDetail.snackMeal: '분식',
  PlaceCategoryDetail.cafe: '카페',
  PlaceCategoryDetail.bakery: '베이커리',
  PlaceCategoryDetail.dessert: '디저트',
  PlaceCategoryDetail.teaHouse: '찻집',
  PlaceCategoryDetail.snack: '간식',
};

/// 카테고리 그룹별 "이런 분께 추천해요" 문구. TourAPI/Kakao 응답에 없는
/// 값이라 그룹 단위로 간단히 생성한다.
const Map<PlaceCategoryGroup, String> _recommendationByGroup = {
  PlaceCategoryGroup.tourism: '역사와 전통을 좋아하는 분, 사진 남기기 좋아하는 분',
  PlaceCategoryGroup.food: '든든한 한 끼와 그 지역만의 맛을 찾는 분',
  PlaceCategoryGroup.cafeDessert: '여유로운 티타임과 달콤한 디저트를 즐기고 싶은 분',
  PlaceCategoryGroup.unknown: '이 지역을 더 알아가고 싶은 분',
};

/// 큰 사진(또는 필름스트립 칸, 채록길 탐색 카드)을 탭했을 때 여는 장소 상세
/// 바텀시트. [PlaceDetailSheetPlace]의 팩토리로 어느 화면의 장소 모델이든
/// 같은 시트를 띄울 수 있다.
Future<void> showPlaceDetailSheet(
  BuildContext context, {
  required PlaceDetailSheetPlace place,
  List<FilmRollPhoto> photos = const [],
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ChaerokColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(ChaerokRadius.lg),
      ),
    ),
    builder: (_) => PlaceDetailSheet(place: place, photos: photos),
  );
}

/// [PlaceDetailSheet]가 화면(필름롤 코스/채록길 탐색)에 무관하게 필요로 하는
/// 필드만 모은 값 객체. 각 화면의 원본 장소 모델([FilmRollPlace]/[ExplorePlace])이
/// 서로 다른 필드 구성을 가져 하나로 합치는 대신, 표시에 필요한 값만 이
/// 어댑터로 변환해 시트를 재사용한다.
class PlaceDetailSheetPlace {
  const PlaceDetailSheetPlace({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.categoryGroup,
    required this.categoryDetail,
    required this.identityKey,
    required this.bookmarkCategoryGroupWire,
    required this.bookmarkSource,
    this.imageUrl,
    this.serverPlaceId,
    this.externalPlaceId,
  });

  factory PlaceDetailSheetPlace.fromFilmRollPlace(FilmRollPlace place) {
    final categoryGroup = resolvePlaceCategoryGroup(place.category);
    return PlaceDetailSheetPlace(
      name: place.name,
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
      categoryGroup: categoryGroup,
      categoryDetail: PlaceCategoryDetail.fromWire(place.category),
      // 필름롤 장소는 탐색 모드처럼 원본 source(TOUR_API/KAKAO 등)를 보관하지
      // 않는다 — 북마크의 canBuildCourse(커스텀 코스 생성용)는 이 경로에서
      // 쓰지 않으므로 빈 문자열로 둔다.
      bookmarkSource: '',
      bookmarkCategoryGroupWire: categoryGroup.wireValue,
      identityKey: place.serverPlaceId != null
          ? 'place:${place.serverPlaceId}'
          : place.externalPlaceId != null
          ? 'filmroll-external:${place.externalPlaceId}'
          : 'filmroll-title:${place.name}:${place.address}',
      imageUrl: place.imageUrl,
      serverPlaceId: place.serverPlaceId,
      externalPlaceId: place.externalPlaceId,
    );
  }

  factory PlaceDetailSheetPlace.fromExplorePlace(ExplorePlace place) {
    return PlaceDetailSheetPlace(
      name: place.title,
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
      categoryGroup: place.categoryGroup,
      categoryDetail: place.categoryDetail,
      // 탐색 모드는 기존 북마크(BookmarkStore)와 정확히 같은 identityKey/source를
      // 써야 "코스 만들기" 등 기존 흐름과 어긋나지 않는다.
      identityKey: place.identityKey,
      bookmarkSource: place.source,
      bookmarkCategoryGroupWire: place.categoryGroupWire,
      imageUrl: place.imageUrl,
      serverPlaceId: place.serverId,
      externalPlaceId: place.externalPlaceId,
    );
  }

  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final PlaceCategoryGroup categoryGroup;
  final PlaceCategoryDetail categoryDetail;
  final String identityKey;
  final String bookmarkCategoryGroupWire;
  final String bookmarkSource;
  final String? imageUrl;
  final int? serverPlaceId;
  final String? externalPlaceId;
}

/// 코스 장소 하나의 상세 정보 — 인증한 사진(있으면), 이름·카테고리·주소,
/// 서버에 연결된 장소면 상세 조회로 받아오는 개요/운영시간/전화, 그리고
/// 저장(북마크)·길찾기·지도보기 액션을 보여준다.
class PlaceDetailSheet extends StatefulWidget {
  const PlaceDetailSheet({
    super.key,
    required this.place,
    this.photos = const [],
  });

  final PlaceDetailSheetPlace place;

  /// 이 장소에서 촬영된 사진(있으면 대표 사진 대신 촬영 순서대로 보여준다).
  /// 채록길 탐색처럼 필름롤과 무관한 장소는 빈 목록을 넘긴다.
  final List<FilmRollPhoto> photos;

  @override
  State<PlaceDetailSheet> createState() => _PlaceDetailSheetState();
}

class _PlaceDetailSheetState extends State<PlaceDetailSheet> {
  late final List<FilmRollPhoto> _sortedPhotos;
  late final PageController _photoController;
  int _photoIndex = 0;

  bool _isBookmarked = false;
  bool _isTogglingBookmark = false;

  PlaceDetailResponse? _detail;
  bool _isLoadingDetail = false;

  @override
  void initState() {
    super.initState();
    _sortedPhotos = [...widget.photos]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    _photoController = PageController();
    unawaited(_loadBookmarkState());
    unawaited(_loadDetail());
  }

  @override
  void dispose() {
    _photoController.dispose();
    super.dispose();
  }

  String get _identityKey => widget.place.identityKey;

  Future<void> _loadBookmarkState() async {
    final bookmarked = await BookmarkStore.instance.isBookmarked(_identityKey);
    if (!mounted) return;
    setState(() => _isBookmarked = bookmarked);
  }

  Future<void> _loadDetail() async {
    final serverPlaceId = widget.place.serverPlaceId;
    if (serverPlaceId == null) return;
    setState(() => _isLoadingDetail = true);
    try {
      final detail = await PlacesApi.getPlaceDetail(serverPlaceId);
      if (!mounted) return;
      setState(() => _detail = detail);
    } catch (e, st) {
      log('장소 상세 조회 실패', name: _tag, error: e, stackTrace: st);
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _toggleBookmark() async {
    if (_isTogglingBookmark) return;
    setState(() => _isTogglingBookmark = true);
    final place = widget.place;
    final bookmarked = BookmarkedPlace(
      identityKey: _identityKey,
      title: place.name,
      categoryLabel:
          _detailLabels[place.categoryDetail] ??
          _groupLabels[place.categoryGroup] ??
          place.bookmarkCategoryGroupWire,
      categoryGroupWire: place.bookmarkCategoryGroupWire,
      source: place.bookmarkSource,
      latitude: place.latitude,
      longitude: place.longitude,
      serverId: place.serverPlaceId,
      externalPlaceId: place.externalPlaceId,
      imageUrl: place.imageUrl,
    );
    try {
      final result = await BookmarkStore.instance.toggle(bookmarked);
      if (!mounted) return;
      setState(() => _isBookmarked = result);
    } finally {
      if (mounted) setState(() => _isTogglingBookmark = false);
    }
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        log('외부 링크 열기 실패(launchUrl=false)', name: _tag);
      }
    } catch (e, st) {
      log('외부 링크 열기 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  void _openMapView() {
    final place = widget.place;
    final query = Uri.encodeComponent(place.name);
    unawaited(
      _openExternalUrl(
        'https://map.kakao.com/link/map/$query,${place.latitude},${place.longitude}',
      ),
    );
  }

  void _openDirections() {
    final place = widget.place;
    final query = Uri.encodeComponent(place.name);
    unawaited(
      _openExternalUrl(
        'https://map.kakao.com/link/to/$query,${place.latitude},${place.longitude}',
      ),
    );
  }

  void _callPhone(String phone) {
    unawaited(_openExternalUrl('tel:$phone'));
  }

  void _openFullGallery() {
    if (_sortedPhotos.isEmpty) return;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _PlacePhotoGalleryScreen(
            photos: _sortedPhotos,
            initialIndex: _photoIndex,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final categoryGroup = place.categoryGroup;
    final detailLabel = _detailLabels[place.categoryDetail];
    final groupLabel = _groupLabels[categoryGroup];
    final tags = <String>{
      if (groupLabel != null) groupLabel,
      if (detailLabel != null) detailLabel,
    }.toList();
    final recommendation =
        _recommendationByGroup[categoryGroup] ??
        _recommendationByGroup[PlaceCategoryGroup.unknown]!;
    final overview = _detail?.overview;
    final openingHours = _detail?.openingHours;
    final phone = _detail?.phone;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      vertical: ChaerokSpacing.sm,
                    ),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ChaerokColors.border,
                      borderRadius: BorderRadius.circular(ChaerokRadius.full),
                    ),
                  ),
                ),
                _buildPhotoArea(place),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    ChaerokSpacing.lg,
                    ChaerokSpacing.md,
                    ChaerokSpacing.lg,
                    ChaerokSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              place.name,
                              style: ChaerokTypography.titleLarge,
                            ),
                          ),
                          IconButton(
                            onPressed: _isTogglingBookmark
                                ? null
                                : _toggleBookmark,
                            icon: Icon(
                              _isBookmarked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: _isBookmarked
                                  ? ChaerokColors.error
                                  : ChaerokColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: ChaerokSpacing.xs),
                        Wrap(
                          spacing: ChaerokSpacing.xs,
                          runSpacing: ChaerokSpacing.xs,
                          children: tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: ChaerokSpacing.sm,
                                    vertical: ChaerokSpacing.xxs,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ChaerokColors.sageLight,
                                    borderRadius: BorderRadius.circular(
                                      ChaerokRadius.full,
                                    ),
                                  ),
                                  child: Text(
                                    '#$tag',
                                    style: ChaerokTypography.caption.copyWith(
                                      color: ChaerokColors.primaryDark,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: ChaerokSpacing.md),
                      const Divider(height: 1, color: ChaerokColors.border),
                      const SizedBox(height: ChaerokSpacing.md),
                      _buildInfoRow(
                        icon: Icons.location_on_outlined,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                place.address,
                                style: ChaerokTypography.bodyMedium,
                              ),
                            ),
                            GestureDetector(
                              onTap: _openMapView,
                              child: Text(
                                '지도에서 보기 >',
                                style: ChaerokTypography.caption.copyWith(
                                  color: ChaerokColors.primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (openingHours != null) ...[
                        const SizedBox(height: ChaerokSpacing.xs),
                        _buildInfoRow(
                          icon: Icons.access_time,
                          child: Text(
                            openingHours,
                            style: ChaerokTypography.bodyMedium,
                          ),
                        ),
                      ],
                      if (phone != null) ...[
                        const SizedBox(height: ChaerokSpacing.xs),
                        _buildInfoRow(
                          icon: Icons.call_outlined,
                          child: GestureDetector(
                            onTap: () => _callPhone(phone),
                            child: Text(
                              phone,
                              style: ChaerokTypography.bodyMedium.copyWith(
                                color: ChaerokColors.primaryDark,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (overview != null && overview.isNotEmpty) ...[
                        const SizedBox(height: ChaerokSpacing.md),
                        Text(
                          overview,
                          style: ChaerokTypography.bodyMedium.copyWith(
                            color: ChaerokColors.textSecondary,
                          ),
                        ),
                      ] else if (_isLoadingDetail) ...[
                        const SizedBox(height: ChaerokSpacing.md),
                        const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ChaerokColors.primary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: ChaerokSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(ChaerokSpacing.md),
                        decoration: BoxDecoration(
                          color: ChaerokColors.primaryLight,
                          borderRadius: BorderRadius.circular(ChaerokRadius.lg),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.eco_outlined,
                              color: ChaerokColors.primaryDark,
                            ),
                            const SizedBox(width: ChaerokSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '이런 분께 추천해요!',
                                    style: ChaerokTypography.bodyMedium
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: ChaerokSpacing.xxs),
                                  Text(
                                    recommendation,
                                    style: ChaerokTypography.caption.copyWith(
                                      color: ChaerokColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: ChaerokSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isTogglingBookmark
                                  ? null
                                  : _toggleBookmark,
                              icon: Icon(
                                _isBookmarked
                                    ? Icons.bookmark
                                    : Icons.bookmark_border,
                              ),
                              label: const Text('저장하기'),
                            ),
                          ),
                          const SizedBox(width: ChaerokSpacing.sm),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _openDirections,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ChaerokColors.primaryDark,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.near_me_outlined),
                              label: const Text('길찾기'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: ChaerokColors.textSecondary),
        const SizedBox(width: ChaerokSpacing.xs),
        Expanded(child: child),
      ],
    );
  }

  static const double _photoHeight = 220;

  Widget _buildPhotoArea(PlaceDetailSheetPlace place) {
    final hasLocalPhotos = _sortedPhotos.isNotEmpty;
    return SizedBox(
      height: _photoHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.zero,
            child: hasLocalPhotos
                ? PageView.builder(
                    controller: _photoController,
                    itemCount: _sortedPhotos.length,
                    onPageChanged: (i) => setState(() => _photoIndex = i),
                    itemBuilder: (context, i) => Image.file(
                      File(_sortedPhotos[i].originalPath),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: ChaerokColors.surface),
                    ),
                  )
                : PlaceImage(
                    imageUrl: place.imageUrl ?? _detail?.firstImageUrl,
                    mood: moodForCategory(place.categoryGroup),
                  ),
          ),
          if (hasLocalPhotos && _sortedPhotos.length > 1)
            Positioned(
              top: ChaerokSpacing.sm,
              right: ChaerokSpacing.sm,
              child: _PillBadge(
                label: '${_photoIndex + 1} / ${_sortedPhotos.length}',
              ),
            ),
          if (hasLocalPhotos)
            Positioned(
              bottom: ChaerokSpacing.sm,
              right: ChaerokSpacing.sm,
              child: GestureDetector(
                onTap: _openFullGallery,
                child: const _PillBadge(
                  icon: Icons.photo_library_outlined,
                  label: '전체 사진 보기',
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ChaerokSpacing.sm,
        vertical: ChaerokSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(ChaerokRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: ChaerokSpacing.xxs),
          ],
          Text(
            label,
            style: ChaerokTypography.caption.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// "전체 사진 보기"로 열리는 전체화면 사진 갤러리.
class _PlacePhotoGalleryScreen extends StatefulWidget {
  const _PlacePhotoGalleryScreen({
    required this.photos,
    required this.initialIndex,
  });

  final List<FilmRollPhoto> photos;
  final int initialIndex;

  @override
  State<_PlacePhotoGalleryScreen> createState() =>
      _PlacePhotoGalleryScreenState();
}

class _PlacePhotoGalleryScreenState extends State<_PlacePhotoGalleryScreen> {
  late int _index = widget.initialIndex;
  late final _controller = PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => Center(
                child: Image.file(
                  File(widget.photos[i].originalPath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: ChaerokSpacing.sm,
              left: ChaerokSpacing.xs,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              top: ChaerokSpacing.md,
              right: ChaerokSpacing.md,
              child: _PillBadge(
                label: '${_index + 1} / ${widget.photos.length}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
