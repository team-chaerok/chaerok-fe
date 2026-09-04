import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/course_response.dart';
import 'package:chaerok/data/models/resolve_region_request.dart';
import 'package:chaerok/data/remote/regions_api.dart';
import 'package:chaerok/features/explore/presentation/widgets/explore_map_view.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/region_departure.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/visit_category_progress.dart';
import 'package:chaerok/features/film_roll/domain/visit_verification.dart';
import 'package:chaerok/features/film_roll/presentation/controller/film_roll_controller.dart';
import 'package:chaerok/features/film_roll/presentation/page/course_selection_screen.dart';
import 'package:chaerok/features/film_roll/presentation/page/visit_capture_screen.dart';
import 'package:chaerok/features/film_roll/presentation/state/film_roll_state.dart';
import 'package:chaerok/features/location/data/kakao_local_api_service.dart';
import 'package:chaerok/features/location/data/location_permission_service.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

const _serviceProvinceName = '충청남도';

/// 진행 상태 기준 스팟 필터.
enum _ProgressFilter {
  all('전체'),
  unvisited('미방문'),
  verifiable('인증 가능'),
  visited('방문 완료'),
  photographed('촬영한 장소');

  const _ProgressFilter(this.label);

  final String label;
}

/// 채록길 탭의 진행 모드 본문.
///
/// 진행중 필름롤의 진행률·현상 조건·스팟 목록·방문 인증/촬영을 담당한다.
/// 로컬 진행 데이터는 `FilmRollController`를 재사용하고, 현상(완료) 조건은
/// 서버 필름롤이 있을 때만 `VisitsApi.getVisits`로 조회한다.
class FilmRollProgressView extends StatefulWidget {
  const FilmRollProgressView({
    super.key,
    required this.filmRoll,
    required this.currentPosition,
    required this.mapEnabled,
    required this.onRequestPosition,
    required this.onPositionResolved,
    required this.onExited,
  });

  final FilmRoll filmRoll;
  final Position? currentPosition;
  final bool mapEnabled;

  /// 지역 이탈이 확정(현상 예약 또는 조건 미충족 종료)돼 이 화면을 벗어나야
  /// 할 때 호출. 부모가 모드를 다시 판별한다(`ExploreScreen.reevaluate`).
  final VoidCallback onExited;

  /// 현재 위치를 다시 잡아야 할 때 호출(부모가 위치를 재조회).
  final Future<void> Function() onRequestPosition;

  /// 방문 인증 시점에 새로 조회한 좌표를 부모에 올려, 지도 마커·"인증 가능"
  /// 필터 등 다른 표시도 최신 좌표 기준으로 맞추게 한다.
  final ValueChanged<Position> onPositionResolved;

  @override
  State<FilmRollProgressView> createState() => _FilmRollProgressViewState();
}

class _FilmRollProgressViewState extends State<FilmRollProgressView> {
  static const _tag = 'FilmRollProgressView';
  static const double _mapHeight = 240;

  late final FilmRollController _controller;
  FilmRollState _state = const FilmRollState.initial();
  _ProgressFilter _filter = _ProgressFilter.all;
  bool _isResolvingRegion = false;
  bool _isVerifyingLocation = false;
  ExploreMapMarker? _focusMarker;

  // 지역 이탈 감지 상태. 다이얼로그는 세션(이 위젯 생존 기간) 중 지역을
  // 벗어난 첫 시점에 1번만 띄우고, 사용자가 "머무르기"를 선택하면 이후엔
  // 상단 배너로만 안내한다. 다시 지역 안으로 들어오면 판정을 리셋한다.
  bool _departureCheckInFlight = false;
  bool _exitDialogShown = false;
  bool _showDepartedBanner = false;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _controller = FilmRollController(
      filmRollId: widget.filmRoll.id,
      onStateChanged: (state) {
        if (!mounted) return;
        setState(() => _state = state);
      },
    );
    unawaited(_controller.load());
    unawaited(_checkRegionDeparture());
  }

  @override
  void didUpdateWidget(covariant FilmRollProgressView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPosition != oldWidget.currentPosition) {
      unawaited(_checkRegionDeparture());
    }
  }

  FilmRoll? get _filmRoll => _state.filmRoll ?? widget.filmRoll;

  int? get _serverFilmRollId => _filmRoll?.serverFilmRollId;

  Future<void> _onSelectCourseTap() async {
    final filmRoll = _filmRoll;
    if (filmRoll == null) return;

    var regionId = filmRoll.regionId;
    if (regionId == null) {
      setState(() => _isResolvingRegion = true);
      try {
        final region = await RegionsApi.resolveRegion(
          ResolveRegionRequest(
            provinceName: _serviceProvinceName,
            cityCountyName: filmRoll.regionName,
          ),
        );
        regionId = region.regionId;
      } catch (e, st) {
        log('지역 재조회 실패', name: _tag, error: e, stackTrace: st);
        if (!mounted) return;
        _showSnackBar(apiErrorMessage(e));
        return;
      } finally {
        if (mounted) setState(() => _isResolvingRegion = false);
      }
    }

    if (!mounted) return;
    final selected = await Navigator.of(context).push<CourseResponse>(
      MaterialPageRoute(
        builder: (_) => CourseSelectionScreen(regionId: regionId!),
      ),
    );
    if (selected == null || !mounted) return;

    final success = await _controller.selectCourse(selected);
    if (!mounted || success) return;
    final message = _controller.state.errorMessage;
    if (message != null) _showSnackBar(message);
  }

  Future<void> _onVisitTap(FilmRollPlace place) async {
    if (_isVerifyingLocation) return;

    if (place.isVisited) {
      _showSnackBar(
        const VisitGateResult(VisitGateStatus.alreadyVisited).message,
      );
      return;
    }

    // 방문 인증은 "지금 여기"를 증명해야 하므로, 부모가 미리 잡아둔 좌표 대신
    // 버튼을 누른 시점의 좌표를 새로 조회해 게이트를 평가한다.
    setState(() => _isVerifyingLocation = true);
    final Position? position;
    try {
      position = await LocationPermissionService.getCurrentPosition();
    } finally {
      if (mounted) setState(() => _isVerifyingLocation = false);
    }
    if (!mounted) return;
    if (position != null) widget.onPositionResolved(position);

    final gate = evaluateVisitGate(
      position: position,
      placeLatitude: place.latitude,
      placeLongitude: place.longitude,
      alreadyVisited: place.isVisited,
    );
    if (!gate.canVerify) {
      _showSnackBar(gate.message);
      if (gate.status == VisitGateStatus.noPosition ||
          gate.status == VisitGateStatus.inaccurate) {
        await widget.onRequestPosition();
      }
      return;
    }

    final filmRoll = _filmRoll;
    if (filmRoll == null) return;
    final captured = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VisitCaptureScreen(
          filmRollId: filmRoll.id,
          filmRollPlaceId: place.id,
        ),
      ),
    );
    if (captured != true || !mounted) return;
    await _controller.completeVisit(place.id);
  }

  /// 방문 인증과 별개로 필름 카메라만 여는 동선. 촬영/저장은 하되 방문 인증은
  /// 하지 않는다(인증은 거리 게이트를 통과한 "방문 인증하기"로만).
  Future<void> _onOpenCameraTap(FilmRollPlace place) async {
    final filmRoll = _filmRoll;
    if (filmRoll == null) return;
    final captured = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VisitCaptureScreen(
          filmRollId: filmRoll.id,
          filmRollPlaceId: place.id,
        ),
      ),
    );
    if (captured != true || !mounted) return;
    await _controller.load();
  }

  void _onBrowseNextSpotTap(FilmRollPlace nextPlace) {
    setState(() {
      _filter = _ProgressFilter.unvisited;
      _focusMarker = _markerFor(nextPlace, ExploreMarkerState.next);
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // ─────────────────────────────────────────────────────────────────────
  // 지역 이탈 감지 · 확정
  // ─────────────────────────────────────────────────────────────────────

  /// [widget.currentPosition]이 갱신될 때마다 신선한 좌표로 행정구역을 다시
  /// 조회해 필름롤 지역을 벗어났는지 판정한다. 세션 캐시(`LocationVerificationResult`)
  /// 는 이동을 반영하지 못하므로 쓰지 않는다.
  Future<void> _checkRegionDeparture() async {
    if (_departureCheckInFlight || _isExiting) return;
    final filmRoll = _filmRoll;
    final position = widget.currentPosition;
    if (filmRoll == null || position == null) return;

    _departureCheckInFlight = true;
    try {
      final administrativeRegion =
          await KakaoLocalApiService.resolveAdministrativeRegion(
            latitude: position.latitude,
            longitude: position.longitude,
          );
      if (!mounted) return;

      final departure = evaluateRegionDeparture(
        filmRollRegion: filmRoll.regionCode,
        currentCityCountyName: administrativeRegion?.cityCountyName,
        position: position,
      );

      switch (departure) {
        case RegionDepartureStatus.inside:
          _exitDialogShown = false;
          if (_showDepartedBanner) {
            setState(() => _showDepartedBanner = false);
          }
        case RegionDepartureStatus.unknown:
          // 위치/역지오코딩을 신뢰할 수 없다 — 조용히 무시하고 기존 상태 유지.
          break;
        case RegionDepartureStatus.departed:
          if (_exitDialogShown) {
            if (!_showDepartedBanner) {
              setState(() => _showDepartedBanner = true);
            }
          } else {
            _exitDialogShown = true;
            await _showExitConfirmDialog();
          }
      }
    } catch (e, st) {
      log('지역 이탈 판정 실패', name: _tag, error: e, stackTrace: st);
    } finally {
      _departureCheckInFlight = false;
    }
  }

  Future<void> _showExitConfirmDialog() async {
    if (!mounted) return;
    final isCompletable = _filmRoll?.isCompletable(_state.places) ?? false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('지역을 벗어났어요'),
        content: Text(
          isCompletable
              ? '현상을 시작하면 이 필름롤은 더 이상 촬영할 수 없어요.\n지금 현상을 시작할까요?'
              : '아직 현상 조건(서로 다른 유형 $requiredVisitCategoryCount곳 방문)을 채우지 '
                    '못했어요.\n지금 벗어나면 현상되지 않아요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('머무르기'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(isCompletable ? '현상 시작하기' : '그래도 벗어나기'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      if (mounted) setState(() => _showDepartedBanner = true);
      return;
    }
    await _startExit();
  }

  Future<void> _startExit() async {
    setState(() => _isExiting = true);
    try {
      final result = await _controller.exitFilmRoll();
      if (!mounted) return;
      if (result.isDeveloping) {
        widget.onExited();
        return;
      }
      await _showExpiredDialog();
      if (!mounted) return;
      widget.onExited();
    } on ExitNotSyncedException {
      if (!mounted) return;
      _showSnackBar('아직 서버와 동기화되지 않았어요. 잠시 후 다시 시도해 주세요.');
    } catch (e, st) {
      log('지역 이탈 확정 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      _showSnackBar('지역 이탈을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.');
    } finally {
      if (mounted) setState(() => _isExiting = false);
    }
  }

  Future<void> _showExpiredDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('필름롤이 종료됐어요'),
        content: const Text('현상 조건을 충족하지 못해 이 필름롤은 종료됐어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  FilmRollPlace? get _nextPlace {
    final places = [..._state.places]
      ..sort((a, b) => a.visitOrder.compareTo(b.visitOrder));
    for (final place in places) {
      if (!place.isVisited) return place;
    }
    return null;
  }

  bool _isVerifiable(FilmRollPlace place) {
    return evaluateVisitGate(
      position: widget.currentPosition,
      placeLatitude: place.latitude,
      placeLongitude: place.longitude,
      alreadyVisited: place.isVisited,
    ).canVerify;
  }

  ExploreMapMarker _markerFor(FilmRollPlace place, ExploreMarkerState state) {
    return ExploreMapMarker(
      id: place.id,
      latitude: place.latitude,
      longitude: place.longitude,
      label: place.name,
      state: state,
    );
  }

  List<ExploreMapMarker> _buildMarkers() {
    final nextId = _nextPlace?.id;
    return [
      for (final place in _state.places)
        _markerFor(
          place,
          place.isVisited
              ? ExploreMarkerState.visited
              : place.id == nextId
              ? ExploreMarkerState.next
              : _isVerifiable(place)
              ? ExploreMarkerState.verifiable
              : ExploreMarkerState.unvisited,
        ),
    ];
  }

  List<FilmRollPlace> _filteredPlaces() {
    return _state.places.where((place) {
      switch (_filter) {
        case _ProgressFilter.all:
          return true;
        case _ProgressFilter.unvisited:
          return !place.isVisited;
        case _ProgressFilter.verifiable:
          return !place.isVisited && _isVerifiable(place);
        case _ProgressFilter.visited:
          return place.isVisited;
        case _ProgressFilter.photographed:
          return place.photoCount > 0;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    switch (_state.status) {
      case FilmRollLoadStatus.loading:
        return const Center(child: ChaerokLoadingIndicator());
      case FilmRollLoadStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(ChaerokSpacing.xxl),
            child: Text(
              _state.errorMessage ?? '오류가 발생했습니다.',
              textAlign: TextAlign.center,
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.error,
              ),
            ),
          ),
        );
      case FilmRollLoadStatus.loaded:
        return _buildLoaded();
    }
  }

  Widget _buildLoaded() {
    final filmRoll = _filmRoll!;
    final hasCourse = filmRoll.selectedCourseId != null;

    return Column(
      children: [
        SizedBox(
          height: _mapHeight,
          child: ExploreMapView(
            markers: _buildMarkers(),
            focus: _focusMarker,
            enabled: widget.mapEnabled,
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(ChaerokSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_showDepartedBanner) ...[
                  _buildDepartedBanner(),
                  const SizedBox(height: ChaerokSpacing.md),
                ],
                _buildProgressCard(filmRoll),
                const SizedBox(height: ChaerokSpacing.md),
                if (!hasCourse)
                  ChaerokButton(
                    text: '추천 코스 선택하기',
                    isLoading: _isResolvingRegion,
                    onPressed: _onSelectCourseTap,
                  )
                else
                  ..._buildCourseSection(filmRoll),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepartedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      decoration: BoxDecoration(
        color: ChaerokColors.sageLight,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '지역을 벗어났어요',
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.primaryDark,
              ),
            ),
          ),
          TextButton(
            onPressed: _isExiting ? null : _showExitConfirmDialog,
            child: const Text('현상 시작하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(FilmRoll filmRoll) {
    final visitedCategoryCount =
        filmRoll.visitedCategoryCount ??
        countDistinctVisitedCategories(_state.places);
    final requiredCategoryCount =
        filmRoll.requiredCategoryCount ?? requiredVisitCategoryCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChaerokSpacing.lg),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
        border: Border.all(color: ChaerokColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${filmRoll.title} 진행 중', style: ChaerokTypography.bodyMedium),
          const SizedBox(height: ChaerokSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(ChaerokRadius.full),
            child: LinearProgressIndicator(
              value: requiredCategoryCount == 0
                  ? 0
                  : visitedCategoryCount / requiredCategoryCount,
              minHeight: 8,
              backgroundColor: ChaerokColors.primaryLight,
              color: ChaerokColors.primary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(
            _developConditionLabel(
              filmRoll,
              visitedCategoryCount,
              requiredCategoryCount,
            ),
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(
            '방문 ${filmRoll.visitedPlaceCount} / ${filmRoll.totalPlaceCount} 곳',
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          if (_state.visitsLoadFailed) ...[
            const SizedBox(height: ChaerokSpacing.xxs),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '현상 조건을 불러오지 못했어요',
                    style: ChaerokTypography.caption.copyWith(
                      color: ChaerokColors.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _state.isLoadingVisits
                      ? null
                      : () => unawaited(_controller.loadVisits()),
                  child: Text(_state.isLoadingVisits ? '불러오는 중…' : '다시 시도'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 현상 조건 표시 문구. 서버 값([FilmRoll.visitRequirementMet])이 있으면 그
  /// 충족 여부를 우선 반영하고, 아직 조회 전이면 동기화/로딩 상태를 덧붙인다.
  String _developConditionLabel(
    FilmRoll filmRoll,
    int visitedCategoryCount,
    int requiredCategoryCount,
  ) {
    final base = '서로 다른 관광 유형 $visitedCategoryCount/$requiredCategoryCount';
    final requirementMet = filmRoll.visitRequirementMet;
    if (requirementMet != null) {
      return requirementMet ? '$base · 현상 조건을 충족했어요' : base;
    }
    if (_serverFilmRollId == null) {
      return '$base · 서버 동기화가 완료되면 정확한 조건을 확인할 수 있어요';
    }
    if (_state.isLoadingVisits) {
      return '$base · 현상 조건을 확인하는 중이에요';
    }
    return base;
  }

  List<Widget> _buildCourseSection(FilmRoll filmRoll) {
    final nextPlace = _nextPlace;
    final filtered = _filteredPlaces();

    return [
      if (nextPlace != null) ...[
        _buildNextSpotCard(nextPlace),
        const SizedBox(height: ChaerokSpacing.md),
      ],
      _buildProgressFilterRow(),
      const SizedBox(height: ChaerokSpacing.sm),
      if (filtered.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: ChaerokSpacing.lg),
          child: Text(
            '해당하는 장소가 없어요',
            textAlign: TextAlign.center,
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
        )
      else
        ...filtered.map(_buildPlaceTile),
      const SizedBox(height: ChaerokSpacing.md),
      ChaerokButton(
        text: '지역을 벗어나 현상하기',
        isEnabled: filmRoll.isCompletable(_state.places),
        isLoading: _isExiting,
        onPressed: _isExiting ? null : _showExitConfirmDialog,
      ),
    ];
  }

  Widget _buildNextSpotCard(FilmRollPlace place) {
    final gate = evaluateVisitGate(
      position: widget.currentPosition,
      placeLatitude: place.latitude,
      placeLongitude: place.longitude,
      alreadyVisited: place.isVisited,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChaerokSpacing.lg),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
        border: Border.all(color: ChaerokColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('다음 장소', style: ChaerokTypography.caption),
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(place.name, style: ChaerokTypography.bodyLarge),
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(
            place.address,
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.xs),
          Text(
            gate.message,
            style: ChaerokTypography.caption.copyWith(
              color: gate.canVerify
                  ? ChaerokColors.primaryDark
                  : ChaerokColors.textSecondary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.sm),
          ChaerokButton(
            text: '방문 인증하기',
            isLoading: _isVerifyingLocation,
            onPressed: () => _onVisitTap(place),
          ),
          const SizedBox(height: ChaerokSpacing.xs),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _onOpenCameraTap(place),
                  child: const Text('필름 카메라 열기'),
                ),
              ),
              const SizedBox(width: ChaerokSpacing.xs),
              Expanded(
                child: TextButton(
                  onPressed: () => _onBrowseNextSpotTap(place),
                  child: const Text('다음 코스 둘러보기'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressFilterRow() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _ProgressFilter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: ChaerokSpacing.xs),
        itemBuilder: (context, index) {
          final filter = _ProgressFilter.values[index];
          final isSelected = filter == _filter;
          return ChoiceChip(
            label: Text(filter.label),
            selected: isSelected,
            onSelected: (_) => setState(() => _filter = filter),
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

  Widget _buildPlaceTile(FilmRollPlace place) {
    return Container(
      margin: const EdgeInsets.only(bottom: ChaerokSpacing.sm),
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
        border: Border.all(color: ChaerokColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name, style: ChaerokTypography.bodyLarge),
                const SizedBox(height: ChaerokSpacing.xxs),
                Text(
                  _placeStatusLabel(place),
                  style: ChaerokTypography.caption.copyWith(
                    color: ChaerokColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: ChaerokSpacing.sm),
          if (place.isVisited)
            const Icon(Icons.check_circle, color: ChaerokColors.primary)
          else
            TextButton(
              onPressed: _isVerifyingLocation ? null : () => _onVisitTap(place),
              child: const Text('방문 인증'),
            ),
        ],
      ),
    );
  }

  String _placeStatusLabel(FilmRollPlace place) {
    if (place.isVisited) {
      return place.photoCount > 0 ? '방문 완료 · 사진 ${place.photoCount}장' : '방문 완료';
    }
    return _isVerifiable(place) ? '현재 위치에서 인증 가능' : '미방문';
  }
}
