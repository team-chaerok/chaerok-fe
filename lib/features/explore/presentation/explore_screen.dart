import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/resolve_region_request.dart';
import 'package:chaerok/data/remote/places_api.dart';
import 'package:chaerok/data/remote/regions_api.dart';
import 'package:chaerok/features/explore/data/bookmark_store.dart';
import 'package:chaerok/features/explore/domain/explore_category_filter.dart';
import 'package:chaerok/features/explore/domain/explore_place.dart';
import 'package:chaerok/features/explore/presentation/widgets/explore_map_view.dart';
import 'package:chaerok/features/explore/presentation/widgets/film_roll_progress_view.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/usecase/resolve_film_roll_entry_use_case.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_developing_view.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_entry_flow.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/recommended_place_card.dart';
import 'package:chaerok/features/location/data/location_permission_service.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

const _serviceProvinceName = '충청남도';

enum _ExploreMode { loading, exploring, progress, developing }

/// 채록길 탭: 진행중인 필름롤 유무로 세 모드를 전환하는 단일 화면.
///
/// - 필름롤 없음 → **탐색 모드**: 지역/검색/카테고리 필터 + 지도 + 주변 장소
///   리스트에서 시작할 채록길을 고른다.
/// - 필름롤 진행중 → **진행 모드**([FilmRollProgressView]): 진행률/현상 조건/
///   스팟 인증/촬영으로 선택한 필름롤을 채워간다.
/// - 필름롤 현상 대기중 → **현상 대기 모드**([FilmRollDevelopingView]): 지역
///   이탈이 확정돼 현상 완료를 기다리는 동안 남은 시간을 보여준다.
///
/// 모드 재평가는 [ExploreScreenState.reevaluate]로 이뤄지며, 탭 재진입/카메라
/// 액션 종료 시 `MainTabScreen`이 `GlobalKey`로 호출한다. 앱이 포그라운드로
/// 복귀할 때도([didChangeAppLifecycleState]) 재평가해, 백그라운드에 있는 동안
/// 지역을 벗어난 경우 진행 모드가 최신 위치로 이탈을 감지할 수 있게 한다.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => ExploreScreenState();
}

class ExploreScreenState extends State<ExploreScreen>
    with WidgetsBindingObserver {
  static const _tag = 'ExploreScreen';
  static const double _mapHeight = 240;

  _ExploreMode _mode = _ExploreMode.loading;
  FilmRoll? _activeFilmRoll;
  bool _mapEnabled = false;

  // 탐색 모드 상태.
  RegionCode _selectedRegion = RegionCode.gongju;
  ExploreCategoryFilter _selectedFilter = ExploreCategoryFilter.all;
  bool _isLoading = true;
  bool _isEnteringFilmRoll = false;
  String? _errorMessage;
  int? _regionId;
  List<ExplorePlace> _regionPlaces = const [];
  List<ExplorePlace> _searchResults = const [];
  String _searchKeyword = '';
  Set<String> _bookmarkedKeys = const {};
  Position? _currentPosition;
  int _fetchRequestId = 0;
  int _searchRequestId = 0;
  Timer? _searchDebounce;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadCurrentPosition());
    unawaited(_loadBookmarks());
    unawaited(reevaluate());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mapEnabled = true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// 앱이 포그라운드로 복귀하면 모드를 재평가한다. 진행 모드에서 백그라운드에
  /// 머무는 동안 지역을 벗어났을 수 있으므로, 최신 위치로 이탈 감지가
  /// 이어지도록 한다(현상 완료 자동 감지는 이번 범위 밖).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(reevaluate());
    }
  }

  /// 진행중/현상대기중 필름롤 유무를 다시 확인해 모드를 갱신한다.
  Future<void> reevaluate() async {
    // 탭 재진입 시 위치를 다시 잡는다. 다른 탭(마이)에서 QA용 Mock 지점을
    // 바꾼 뒤 돌아온 경우에도 방문 게이트가 최신 좌표로 평가되고, 진행
    // 모드의 지역 이탈 감지도 최신 좌표를 받는다.
    unawaited(_loadCurrentPosition());
    final active = await FilmRollModule.instance.recoverLastActiveFilmRoll();
    if (!mounted) return;
    setState(() {
      _activeFilmRoll = active;
      _mode = switch (active?.status) {
        null => _ExploreMode.exploring,
        FilmRollStatus.developing => _ExploreMode.developing,
        _ => _ExploreMode.progress,
      };
    });
    if (active == null && _regionPlaces.isEmpty) {
      unawaited(_fetchPlaces());
    }
  }

  Future<void> _loadCurrentPosition() async {
    try {
      final position = await LocationPermissionService.getCurrentPosition();
      if (!mounted || position == null) return;
      setState(() => _currentPosition = position);
    } catch (e, st) {
      log('현재 위치 조회 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> _loadBookmarks() async {
    final keys = await BookmarkStore.instance.bookmarkedKeys();
    if (!mounted) return;
    setState(() => _bookmarkedKeys = keys);
  }

  Future<void> _onRegionSelected(RegionCode region) async {
    if (region == _selectedRegion) return;
    // 이전 지역의 지연 검색 콜백과 진행 중인 검색 응답을 무효화한다.
    _searchDebounce?.cancel();
    _searchRequestId++;
    _searchController.clear();
    setState(() {
      _selectedRegion = region;
      _searchKeyword = '';
      _searchResults = const [];
    });
    await _fetchPlaces();
  }

  Future<void> _fetchPlaces() async {
    final requestId = ++_fetchRequestId;
    final region = _selectedRegion;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final resolvedRegion = await RegionsApi.resolveRegion(
        ResolveRegionRequest(
          provinceName: _serviceProvinceName,
          cityCountyName: region.cityCountyName,
        ),
      );
      final places = await PlacesApi.getExternalPlaces(resolvedRegion.regionId);
      if (!mounted || requestId != _fetchRequestId) return;
      setState(() {
        _regionId = resolvedRegion.regionId;
        _regionPlaces = places
            .map(ExplorePlace.fromListResponse)
            .toList(growable: false);
        _isLoading = false;
      });
    } catch (e, st) {
      log('관광지 조회 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted || requestId != _fetchRequestId) return;
      setState(() {
        _errorMessage = apiErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(_search(value.trim()));
    });
  }

  Future<void> _search(String keyword) async {
    setState(() => _searchKeyword = keyword);
    if (keyword.isEmpty) {
      setState(() => _searchResults = const []);
      return;
    }
    final regionId = _regionId;
    if (regionId == null) return;

    final requestId = ++_searchRequestId;
    try {
      final results = await PlacesApi.searchPlaces(
        regionId: regionId,
        keyword: keyword,
      );
      if (!mounted || requestId != _searchRequestId) return;
      setState(() {
        _searchResults = results
            .map(ExplorePlace.fromSearchResponse)
            .toList(growable: false);
      });
    } catch (e, st) {
      log('장소 검색 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted || requestId != _searchRequestId) return;
      setState(() => _searchResults = const []);
    }
  }

  List<ExplorePlace> get _visiblePlaces {
    final source = _searchKeyword.isNotEmpty ? _searchResults : _regionPlaces;
    return source
        .where((place) => _selectedFilter.matches(place))
        .toList(growable: false);
  }

  String? _distanceLabel(ExplorePlace place) {
    final position = _currentPosition;
    if (position == null) return null;
    final meters = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      place.latitude,
      place.longitude,
    );
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  Future<void> _onToggleBookmark(ExplorePlace place) async {
    final nowBookmarked = await BookmarkStore.instance.toggle(
      BookmarkedPlace.fromExplorePlace(place),
    );
    if (!mounted) return;
    setState(() {
      _bookmarkedKeys = {
        for (final key in _bookmarkedKeys)
          if (key != place.identityKey) key,
        if (nowBookmarked) place.identityKey,
      };
    });
  }

  void _onShowPlaceDetail(ExplorePlace place) {
    unawaited(_showPlaceDetailSheet(place));
  }

  Future<void> _showPlaceDetailSheet(ExplorePlace place) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: ChaerokColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(ChaerokRadius.lg),
        ),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ChaerokSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(place.title, style: ChaerokTypography.titleMedium),
              const SizedBox(height: ChaerokSpacing.xs),
              Text(
                '${place.categoryDetailLabel}'
                '${_distanceLabel(place) != null ? ' · ${_distanceLabel(place)}' : ''}',
                style: ChaerokTypography.bodyMedium.copyWith(
                  color: ChaerokColors.textSecondary,
                ),
              ),
              const SizedBox(height: ChaerokSpacing.xs),
              Text(
                place.address,
                style: ChaerokTypography.caption.copyWith(
                  color: ChaerokColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 선택한 지역의 로컬 필름롤을 찾거나 새로 생성하고, 코스 미선택
  /// 상태면 코스 선택 화면까지 이어준 뒤 진행 모드로 전환한다.
  Future<void> _onEnterRegionTap() async {
    if (_isEnteringFilmRoll) return;
    final regionId = _regionId;
    if (regionId == null) return;

    setState(() => _isEnteringFilmRoll = true);
    try {
      final decision = await FilmRollModule.instance.resolveFilmRollEntry(
        _selectedRegion.cityCountyName,
        regionId: regionId,
      );
      if (!mounted) return;

      if (decision.action == FilmRollEntryAction.needsCourseSelection) {
        await pushCourseSelectionAndConfirm(
          context,
          filmRollId: decision.filmRoll.id,
          regionId: regionId,
        );
        if (!mounted) return;
      }
      await reevaluate();
    } on UnsupportedRegionException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아직 필름롤을 지원하지 않는 지역이에요.')));
    } catch (e, st) {
      log('필름롤 진입 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('필름롤을 불러오지 못했어요.')));
    } finally {
      if (mounted) setState(() => _isEnteringFilmRoll = false);
    }
  }

  RecommendedPlaceSummaryData _toSummaryData(ExplorePlace place, int index) {
    const moods = PlacePlaceholderMood.values;
    return RecommendedPlaceSummaryData(
      name: place.title,
      category: place.categoryDetailLabel,
      imageUrl: place.imageUrl,
      distance: _distanceLabel(place),
      placeholderMood: moods[index % moods.length],
    );
  }

  List<ExploreMapMarker> _buildExploringMarkers(List<ExplorePlace> places) {
    return [
      for (final (index, place) in places.indexed)
        ExploreMapMarker(
          id: place.identityKey,
          latitude: place.latitude,
          longitude: place.longitude,
          label: place.title,
          state: index == 0
              ? ExploreMarkerState.recommended
              : ExploreMarkerState.normal,
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: Text(
          _mode == _ExploreMode.progress || _mode == _ExploreMode.developing
              ? (_activeFilmRoll?.title ?? '채록길')
              : '채록길',
          style: ChaerokTypography.titleMedium,
        ),
      ),
      body: switch (_mode) {
        _ExploreMode.loading => const Center(child: ChaerokLoadingIndicator()),
        _ExploreMode.progress => FilmRollProgressView(
          key: ValueKey(_activeFilmRoll!.id),
          filmRoll: _activeFilmRoll!,
          currentPosition: _currentPosition,
          mapEnabled: _mapEnabled,
          onExited: () => unawaited(reevaluate()),
          onRequestPosition: _loadCurrentPosition,
          onPositionResolved: (position) {
            if (mounted) setState(() => _currentPosition = position);
          },
        ),
        _ExploreMode.developing => FilmRollDevelopingView(
          key: ValueKey(_activeFilmRoll!.id),
          filmRoll: _activeFilmRoll!,
        ),
        _ExploreMode.exploring => _buildExploring(),
      },
    );
  }

  Widget _buildExploring() {
    final places = _visiblePlaces;
    return Column(
      children: [
        SizedBox(
          height: _mapHeight,
          child: ExploreMapView(
            markers: _buildExploringMarkers(places),
            enabled: _mapEnabled,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ChaerokSpacing.md,
            ChaerokSpacing.sm,
            ChaerokSpacing.md,
            0,
          ),
          child: _buildRegionSelector(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ChaerokSpacing.md,
            ChaerokSpacing.xs,
            ChaerokSpacing.md,
            0,
          ),
          child: _buildSearchField(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ChaerokSpacing.md,
            vertical: ChaerokSpacing.xs,
          ),
          child: _buildCategoryFilter(),
        ),
        Expanded(child: _buildPlacesList(places)),
        _buildFooter(),
      ],
    );
  }

  Widget _buildRegionSelector() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: RegionCode.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: ChaerokSpacing.xs),
        itemBuilder: (context, index) {
          final region = RegionCode.values[index];
          final isSelected = region == _selectedRegion;
          return ChoiceChip(
            label: Text(region.displayName),
            selected: isSelected,
            onSelected: (_) => _onRegionSelected(region),
            selectedColor: ChaerokColors.primary,
            backgroundColor: ChaerokColors.sageLight,
            labelStyle: ChaerokTypography.bodyMedium.copyWith(
              color: isSelected
                  ? ChaerokColors.surface
                  : ChaerokColors.primaryDark,
            ),
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      textInputAction: TextInputAction.search,
      style: ChaerokTypography.bodyMedium,
      decoration: InputDecoration(
        isDense: true,
        hintText: '장소 검색',
        prefixIcon: const Icon(Icons.search, size: 20),
        filled: true,
        fillColor: ChaerokColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: ChaerokSpacing.sm),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ChaerokRadius.md),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ExploreCategoryFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: ChaerokSpacing.xs),
        itemBuilder: (context, index) {
          final filter = ExploreCategoryFilter.values[index];
          final isSelected = filter == _selectedFilter;
          return ChoiceChip(
            label: Text(filter.label),
            selected: isSelected,
            onSelected: (_) => setState(() => _selectedFilter = filter),
            selectedColor: ChaerokColors.primary,
            backgroundColor: ChaerokColors.sageLight,
            labelStyle: ChaerokTypography.caption.copyWith(
              color: isSelected
                  ? ChaerokColors.surface
                  : ChaerokColors.primaryDark,
            ),
            side: BorderSide.none,
          );
        },
      ),
    );
  }

  Widget _buildPlacesList(List<ExplorePlace> places) {
    if (_isLoading) {
      return const Center(child: ChaerokLoadingIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ChaerokSpacing.xxl,
              ),
              child: Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: ChaerokTypography.bodyMedium.copyWith(
                  color: ChaerokColors.error,
                ),
              ),
            ),
            const SizedBox(height: ChaerokSpacing.sm),
            TextButton(onPressed: _fetchPlaces, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (places.isEmpty) {
      return Center(
        child: Text(
          _searchKeyword.isNotEmpty ? '검색 결과가 없어요' : '이 지역의 관광지 정보가 없어요',
          style: ChaerokTypography.bodyMedium,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      itemCount: places.length,
      separatorBuilder: (_, _) => const SizedBox(height: ChaerokSpacing.sm),
      itemBuilder: (context, index) {
        final place = places[index];
        return Stack(
          children: [
            RecommendedPlaceCard(
              data: _toSummaryData(place, index),
              isFeatured: index == 0,
              onTap: () => _onShowPlaceDetail(place),
            ),
            Positioned(
              top: ChaerokSpacing.xs,
              right: ChaerokSpacing.xs,
              child: _BookmarkButton(
                isBookmarked: _bookmarkedKeys.contains(place.identityKey),
                onPressed: () => _onToggleBookmark(place),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      decoration: const BoxDecoration(
        color: ChaerokColors.surface,
        border: Border(top: BorderSide(color: ChaerokColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: ChaerokButton(
          text: '${_selectedRegion.displayName}에서 이 채록길 시작하기',
          isEnabled: _regionId != null && !_isLoading,
          isLoading: _isEnteringFilmRoll,
          onPressed: _onEnterRegionTap,
        ),
      ),
    );
  }
}

class _BookmarkButton extends StatelessWidget {
  const _BookmarkButton({required this.isBookmarked, required this.onPressed});

  final bool isBookmarked;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChaerokColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(ChaerokSpacing.xs),
          child: Icon(
            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            size: 20,
            color: isBookmarked
                ? ChaerokColors.primaryDark
                : ChaerokColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
