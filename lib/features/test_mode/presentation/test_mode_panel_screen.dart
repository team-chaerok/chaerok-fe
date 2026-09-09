import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/core/location/mock_location_gate.dart';
import 'package:chaerok/core/location/mock_location_spots.dart';
import 'package:chaerok/core/test_mode/test_mode_session.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/place_category.dart';
import 'package:chaerok/data/models/resolve_region_request.dart';
import 'package:chaerok/data/remote/places_api.dart';
import 'package:chaerok/data/remote/regions_api.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/visit_category_progress.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/page/visit_capture_screen.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/widgets/chaerok_appbar.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:flutter/material.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

const _serviceProvinceName = '충청남도';
const _gongjuCityCountyName = '공주시';

/// Test Mode(비공개 테스트용) 시나리오 패널.
///
/// 원거리 테스터가 실제 GPS 이동 없이 채록의 핵심 파이프라인
/// (공주 진입 → 촬영 → 유형별 방문 인증 → 공주 이탈 → 현상)을 순서대로 밟게 한다.
/// 위치 판정만 테스트용으로 강제하고, 사진 업로드·FilmRoll·Visit·현상은 실제
/// 백엔드 API를 그대로 사용한다. 진입점은 마이 탭에서
/// `AppFlavor.isTestMode || kDebugMode || isTester` 일 때만 노출된다.
class TestModePanelScreen extends StatefulWidget {
  const TestModePanelScreen({
    super.key,
    @visibleForTesting this.debugDisableMapPicker = false,
  });

  /// 위젯 테스트에서 네이티브 카카오맵 플랫폼 뷰를 띄우지 않기 위한 훅.
  /// true면 [_buildMockMapPicker]가 지도 대신 placeholder를 렌더하고, 지도 탭은
  /// [TestModePanelScreenState.debugPickMockLocation]으로 시뮬레이션한다.
  @visibleForTesting
  final bool debugDisableMapPicker;

  @override
  State<TestModePanelScreen> createState() => TestModePanelScreenState();
}

class TestModePanelScreenState extends State<TestModePanelScreen> {
  bool _busy = false;
  FilmRoll? _activeFilmRoll;
  List<FilmRollPlace> _places = const [];
  bool _isForceOutOfServiceArea = false;

  // mock 위치 설정(지역/지점 테이블 또는 임의 좌표). `AppPreferences`에서 읽어와
  // 상태 카드 표시와 선택 UI에 쓴다.
  bool _isMockLocationEnabled = false;
  // 지점 선택 ↔ 임의 좌표 UI 모드. 최초 로드 때만 저장된 값으로 맞추고, 이후엔
  // 사용자의 모드 칩 선택을 따른다(지도에서 아직 "적용"하지 않아 저장 플래그가
  // 꺼져 있어도 지도 선택 UI는 유지돼야 하므로).
  bool _mockUseCustom = false;
  bool _mockModeInitialized = false;
  RegionCode _mockRegion = RegionCode.gongju;
  int _mockSpotIndex = 0;
  // `AppPreferences`에 저장된(=적용된) 임의 좌표.
  double? _mockCustomLatitude;
  double? _mockCustomLongitude;
  // 지도에서 찍었지만 아직 "이 위치로 적용"을 누르지 않은 좌표.
  double? _pickedLatitude;
  double? _pickedLongitude;
  KakaoMapController? _pickerMapController;
  Poi? _pickerPin;
  // 겹쳐 실행되는 _syncPickerPin 중 최신 호출만 반영하기 위한 세대 카운터.
  int _pinSyncGeneration = 0;

  @override
  void initState() {
    super.initState();
    TestModeSession.instance.addListener(_onSessionChanged);
    unawaited(_reload());
  }

  @override
  void dispose() {
    TestModeSession.instance.removeListener(_onSessionChanged);
    // 진행 중인 _syncPickerPin이 해제 후 지도를 건드리지 않도록 세대를 올린다.
    _pinSyncGeneration++;
    super.dispose();
  }

  /// 위젯 테스트에서 지도 탭(`onMapClick`)을 대신 호출하기 위한 훅.
  @visibleForTesting
  void debugPickMockLocation(double latitude, double longitude) =>
      _onMockMapPicked(latitude, longitude);

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _reload() async {
    final active = await FilmRollModule.instance.recoverLastActiveFilmRoll();
    final places = active == null
        ? const <FilmRollPlace>[]
        : await FilmRollModule.instance.filmRollPlaceRepository.findByFilmRoll(
            active.id,
          );
    final preferences = AppPreferences.instance;
    final forceOutOfService = await preferences.isDebugOutOfServiceArea();
    final mockEnabled = await preferences.isMockLocationEnabled();
    final mockRegionName = await preferences.getMockRegionCodeName();
    final mockSpotIndex = await preferences.getMockSpotIndex();
    final mockUseCustom = await preferences.isMockCustomLocation();
    final mockCustomLat = await preferences.getMockCustomLatitude();
    final mockCustomLng = await preferences.getMockCustomLongitude();
    if (!mounted) return;
    setState(() {
      _activeFilmRoll = active;
      _places = places;
      _isForceOutOfServiceArea = forceOutOfService;
      _isMockLocationEnabled = mockEnabled;
      if (!_mockModeInitialized) {
        _mockUseCustom = mockUseCustom;
        _mockModeInitialized = true;
      }
      _mockRegion = RegionCode.values.firstWhere(
        (value) => value.name == mockRegionName,
        orElse: () => RegionCode.gongju,
      );
      final spots =
          mockLocationSpots[_mockRegion] ?? const <MockLocationSpot>[];
      _mockSpotIndex = spots.isEmpty
          ? 0
          : mockSpotIndex.clamp(0, spots.length - 1);
      _mockCustomLatitude = mockCustomLat;
      _mockCustomLongitude = mockCustomLng;
      // 저장된 좌표가 있으면 지도 핀의 초기값으로 쓴다(재진입 시 마지막 선택
      // 위치를 그대로 보여주기 위함). 아직 찍은 값이 없을 때만 채운다.
      _pickedLatitude ??= mockCustomLat;
      _pickedLongitude ??= mockCustomLng;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    // QA 패널은 짧은 간격으로 여러 번 조작되므로, 대기열에 쌓지 않고 직전
    // 스낵바를 교체한다.
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// 공통 실행 래퍼: 중복 실행 방지 + 완료/실패 안내 + 상태 재조회.
  Future<void> _run(
    Future<void> Function() action, {
    required String done,
  }) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      _snack(done);
    } catch (e) {
      _snack('실패: ${apiErrorMessage(e)}');
    } finally {
      if (mounted) setState(() => _busy = false);
      await _reload();
    }
  }

  // ─────────────────────────────────────────────────────────────────────
  // 시나리오 버튼
  // ─────────────────────────────────────────────────────────────────────

  Future<void> _onEnterGongju() {
    return _run(() async {
      TestModeSession.instance.enterGongju();
      LocationVerificationResult.sessionCache = null;
      LocationVerificationResult.outOfServiceSessionCache = false;

      final region = await RegionsApi.resolveRegion(
        const ResolveRegionRequest(
          provinceName: _serviceProvinceName,
          cityCountyName: _gongjuCityCountyName,
        ),
      );
      final places = await PlacesApi.getExternalPlaces(region.regionId);
      final position = await MockLocationGate.currentMockPosition();
      LocationVerificationResult.sessionCache = LocationVerificationResult(
        position: position,
        region: region,
        places: places,
      );
      await FilmRollModule.instance.resolveFilmRollEntry(
        _gongjuCityCountyName,
        regionId: region.regionId,
      );
    }, done: '공주 진입 완료 — 채록길 탭에서 코스를 선택하고 진행하세요');
  }

  Future<void> _onVerify(PlaceCategoryGroup group) async {
    final active = _activeFilmRoll;
    if (active == null) {
      _snack('먼저 "공주 진입"을 실행하세요');
      return;
    }
    final place = _firstUnvisitedOf(group);
    if (place == null) {
      _snack('${_groupLabel(group)} 미방문 장소가 코스에 없어요 (코스 선택 여부 확인)');
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      // 실제 장소 좌표를 주입해 거리/정확도 게이트를 실제 그대로 통과시킨다.
      TestModeSession.instance.injectPlace(
        latitude: place.latitude,
        longitude: place.longitude,
      );
      final captured = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => VisitCaptureScreen(
            filmRollId: place.filmRollId,
            filmRollPlaceId: place.id,
          ),
        ),
      );
      if (captured == true) {
        await FilmRollModule.instance.completeVisit(place.id);
        await FilmRollModule.instance.filmRollSyncService.syncFilmRoll(
          active.id,
        );
        _snack('${_groupLabel(group)} 인증 완료');
      }
    } catch (e) {
      _snack('인증 실패: ${apiErrorMessage(e)}');
    } finally {
      TestModeSession.instance.clearInjection();
      if (mounted) setState(() => _busy = false);
      await _reload();
    }
  }

  void _onExitGongju() {
    if (_activeFilmRoll == null) {
      _snack('진행 중인 필름롤이 없어요');
      return;
    }
    TestModeSession.instance.exitGongju();
    _snack('공주 이탈 설정됨 — 채록길 탭에서 현상 시작 안내가 표시됩니다');
  }

  Future<void> _onReset() {
    return _run(() async {
      TestModeSession.instance.reset();
      _markLocationDirtyForQa();
      final preferences = AppPreferences.instance;
      await preferences.setMockLocationEnabled(false);
      await preferences.setDebugOutOfServiceArea(false);
      await preferences.setMockCustomLocation(enabled: false);
      await preferences.setMockRegionCodeName(null);
      await preferences.setMockSpotIndex(0);
      // 진행 중인 _syncPickerPin이 방금 지운 핀을 되살리지 않도록 세대를 올린다.
      _pinSyncGeneration++;
      await _pickerPin?.remove();
      _pickerPin = null;
      if (mounted) {
        setState(() {
          _mockUseCustom = false;
          _pickedLatitude = null;
          _pickedLongitude = null;
        });
      }
    }, done: '테스트 상태를 초기화했어요');
  }

  Future<void> _onForceOutOfServiceChanged(bool enabled) async {
    setState(() => _isForceOutOfServiceArea = enabled);
    await AppPreferences.instance.setDebugOutOfServiceArea(enabled);
    _markLocationDirtyForQa();
    _snack('홈 탭으로 돌아가면 반영돼요');
  }

  /// 위치 인증 세션 캐시를 비우고, 홈 대시보드가 다음 표시에서 자동 네비게이션
  /// 없이 위치를 다시 판정하도록 플래그를 세운다.
  void _markLocationDirtyForQa() {
    LocationVerificationResult.sessionCache = null;
    LocationVerificationResult.outOfServiceSessionCache = false;
    LocationVerificationResult.qaLocationDirty = true;
  }

  Future<void> _onMockModeChanged(bool useCustom) {
    return _run(() async {
      if (!useCustom) {
        await AppPreferences.instance.setMockCustomLocation(enabled: false);
        _markLocationDirtyForQa();
      }
      setState(() => _mockUseCustom = useCustom);
    }, done: useCustom ? '지도를 눌러 위치를 선택하세요' : '지점 선택 모드로 전환했어요');
  }

  Future<void> _onMockRegionSelected(RegionCode region) {
    return _run(() async {
      final preferences = AppPreferences.instance;
      await preferences.setMockRegionCodeName(region.name);
      await preferences.setMockSpotIndex(0);
      await preferences.setMockCustomLocation(enabled: false);
      await preferences.setMockLocationEnabled(true);
      _markLocationDirtyForQa();
    }, done: '${region.displayName} 지점으로 설정했어요 — 홈에서 확인하세요');
  }

  Future<void> _onMockSpotSelected(int index) {
    return _run(() async {
      final preferences = AppPreferences.instance;
      await preferences.setMockSpotIndex(index);
      await preferences.setMockCustomLocation(enabled: false);
      await preferences.setMockLocationEnabled(true);
      _markLocationDirtyForQa();
    }, done: '지점을 변경했어요 — 홈에서 확인하세요');
  }

  /// 지도판을 탭하면(`onMapClick`) 그 좌표를 "찍은 위치"로 잡아 핀을 옮긴다.
  /// 아직 저장은 하지 않는다 — "이 위치로 적용"을 눌러야 반영된다.
  void _onMockMapPicked(double latitude, double longitude) {
    setState(() {
      _pickedLatitude = latitude;
      _pickedLongitude = longitude;
    });
    unawaited(_syncPickerPin());
  }

  Future<void> _onPickerMapReady(KakaoMapController controller) async {
    _pickerMapController = controller;
    await _syncPickerPin();
  }

  /// 지도 컨트롤러가 준비돼 있고 찍은 좌표가 있으면 핀을 다시 그린다.
  ///
  /// `_onMockMapPicked`가 `unawaited`로 호출하므로 빠른 연속 탭에서 여러 동기화가
  /// 겹칠 수 있다. 세대([_pinSyncGeneration])를 비교해 매 await 이후 최신 호출만
  /// 살아남게 하고, 뒤늦게 추가된 오래된 POI는 즉시 제거한다. `dispose`에서
  /// 세대를 올려 위젯 해제 후 결과가 반영되지 않도록 한다.
  Future<void> _syncPickerPin() async {
    final controller = _pickerMapController;
    final latitude = _pickedLatitude;
    final longitude = _pickedLongitude;
    if (controller == null || latitude == null || longitude == null) return;

    final generation = ++_pinSyncGeneration;
    try {
      await _pickerPin?.remove();
      _pickerPin = null;
      final icon = await KImage.fromWidget(
        const _MockPickPin(),
        const Size(28, 28),
      );
      if (!mounted || generation != _pinSyncGeneration) return;

      final poi = await controller.labelLayer.addPoi(
        LatLng(latitude, longitude),
        style: PoiStyle(icon: icon),
      );
      if (!mounted || generation != _pinSyncGeneration) {
        await poi.remove();
        return;
      }
      _pickerPin = poi;

      await controller.moveCamera(
        CameraUpdate.newCenterPosition(LatLng(latitude, longitude)),
      );
    } catch (e, st) {
      log('mock 위치 핀 갱신 실패', name: 'TestModePanel', error: e, stackTrace: st);
    }
  }

  Future<void> _onApplyPickedMockLocation() {
    final latitude = _pickedLatitude;
    final longitude = _pickedLongitude;
    if (latitude == null || longitude == null) return Future.value();
    return _run(() async {
      final preferences = AppPreferences.instance;
      await preferences.setMockCustomLocation(
        enabled: true,
        latitude: latitude,
        longitude: longitude,
      );
      await preferences.setMockLocationEnabled(true);
      _markLocationDirtyForQa();
    }, done: '지도에서 선택한 위치를 적용했어요 — 홈에서 확인하세요');
  }

  Future<void> _onOpenDbViewer() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DriftDbViewer(AppDatabase.instance)),
    );
  }

  // ─────────────────────────────────────────────────────────────────────

  FilmRollPlace? _firstUnvisitedOf(PlaceCategoryGroup group) {
    final sorted = [..._places]
      ..sort((a, b) => a.visitOrder.compareTo(b.visitOrder));
    for (final place in sorted) {
      if (!place.isVisited &&
          resolvePlaceCategoryGroup(place.category) == group) {
        return place;
      }
    }
    return null;
  }

  Set<PlaceCategoryGroup> get _visitedGroups {
    return {
      for (final place in _places)
        if (place.isVisited) resolvePlaceCategoryGroup(place.category),
    }..remove(PlaceCategoryGroup.unknown);
  }

  String _groupLabel(PlaceCategoryGroup group) => switch (group) {
    PlaceCategoryGroup.tourism => '관광지 (TOURISM)',
    PlaceCategoryGroup.food => '음식점 (FOOD)',
    PlaceCategoryGroup.cafeDessert => '카페·디저트 (CAFE_DESSERT)',
    PlaceCategoryGroup.unknown => '기타',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: const ChaerokAppbar(title: 'Test Mode (QA)'),
      body: AbsorbPointer(
        absorbing: _busy,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ChaerokSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProgressCard(),
              const SizedBox(height: ChaerokSpacing.md),
              _buildScenarioCard(),
              const SizedBox(height: ChaerokSpacing.md),
              _buildToolsCard(),
              if (_busy) ...[
                const SizedBox(height: ChaerokSpacing.md),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    final session = TestModeSession.instance;
    final visited = _visitedGroups;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('진행 상태', style: ChaerokTypography.bodyMedium),
          const SizedBox(height: ChaerokSpacing.xs),
          _statusRow('공주 진입', session.gongjuEntered),
          _statusRow(
            '관광지 (TOURISM)',
            visited.contains(PlaceCategoryGroup.tourism),
          ),
          _statusRow('음식점 (FOOD)', visited.contains(PlaceCategoryGroup.food)),
          _statusRow(
            '카페·디저트 (CAFE_DESSERT)',
            visited.contains(PlaceCategoryGroup.cafeDessert),
          ),
          _statusRow('공주 이탈', session.gongjuExited),
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(
            _activeFilmRoll == null
                ? '진행 중인 필름롤 없음'
                : '필름롤: ${_activeFilmRoll!.title} · 장소 ${_places.length}곳',
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(
            '현재 mock 위치: ${_mockLocationStatusText()}',
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 상태 카드에 노출할 "지금 적용 중인" mock 위치 요약.
  String _mockLocationStatusText() {
    final session = TestModeSession.instance;
    if (session.gongjuEntered || session.gongjuExited) {
      return '공주 진입 시나리오 적용 중 (아래 선택 무시)';
    }
    if (!_isMockLocationEnabled) {
      return '꺼짐 (실제 GPS)';
    }
    if (_mockUseCustom &&
        _mockCustomLatitude != null &&
        _mockCustomLongitude != null) {
      return '임의 좌표 ${_mockCustomLatitude!.toStringAsFixed(4)}, '
          '${_mockCustomLongitude!.toStringAsFixed(4)}';
    }
    final spots = mockLocationSpots[_mockRegion] ?? const <MockLocationSpot>[];
    if (_mockSpotIndex >= 0 && _mockSpotIndex < spots.length) {
      return '${_mockRegion.displayName} · ${spots[_mockSpotIndex].label}';
    }
    return _mockRegion.displayName;
  }

  Widget _statusRow(String label, bool done) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: ChaerokSpacing.xxs),
      child: Row(
        children: [
          Icon(
            done ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: done ? ChaerokColors.primary : ChaerokColors.border,
          ),
          const SizedBox(width: ChaerokSpacing.xs),
          Text(label, style: ChaerokTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildScenarioCard() {
    final hasFilmRoll = _activeFilmRoll != null;
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('시나리오', style: ChaerokTypography.bodyMedium),
          const SizedBox(height: ChaerokSpacing.sm),
          ChaerokButton(text: '1. 공주 진입', onPressed: _onEnterGongju),
          const SizedBox(height: ChaerokSpacing.xs),
          ChaerokButton(
            text: '2. 관광지 인증 (TOURISM)',
            isEnabled: hasFilmRoll,
            onPressed: () => _onVerify(PlaceCategoryGroup.tourism),
          ),
          const SizedBox(height: ChaerokSpacing.xs),
          ChaerokButton(
            text: '3. 음식점 인증 (FOOD)',
            isEnabled: hasFilmRoll,
            onPressed: () => _onVerify(PlaceCategoryGroup.food),
          ),
          const SizedBox(height: ChaerokSpacing.xs),
          ChaerokButton(
            text: '4. 카페 인증 (CAFE_DESSERT)',
            isEnabled: hasFilmRoll,
            onPressed: () => _onVerify(PlaceCategoryGroup.cafeDessert),
          ),
          const SizedBox(height: ChaerokSpacing.xs),
          ChaerokButton(
            text: '5. 공주 이탈',
            isEnabled: hasFilmRoll,
            backgroundColor: ChaerokColors.primaryDark,
            onPressed: _onExitGongju,
          ),
          const SizedBox(height: ChaerokSpacing.xs),
          OutlinedButton(onPressed: _onReset, child: const Text('테스트 상태 초기화')),
        ],
      ),
    );
  }

  Widget _buildToolsCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('QA 도구', style: ChaerokTypography.bodyMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              '충남 외 지역 홈 강제',
              style: ChaerokTypography.bodyMedium,
            ),
            subtitle: const Text(
              '실제 위치와 무관하게 위치 인증이 서비스 지역 외로 판정돼 '
              '지역별 둘러보기 홈을 확인할 수 있어요.',
              style: ChaerokTypography.caption,
            ),
            value: _isForceOutOfServiceArea,
            onChanged: _onForceOutOfServiceChanged,
          ),
          const Divider(height: ChaerokSpacing.lg),
          _buildMockLocationControls(),
          const SizedBox(height: ChaerokSpacing.sm),
          TextButton(
            onPressed: _onOpenDbViewer,
            child: const Text('로컬 DB 확인하기'),
          ),
        ],
      ),
    );
  }

  /// mock 위치 선택 UI. "지점 선택"(지역·지점 칩) ↔ "임의 좌표"(위/경도 입력)
  /// 모드를 오가며, 무엇이든 고르면 mock 위치가 자동으로 켜진다.
  Widget _buildMockLocationControls() {
    final spots = mockLocationSpots[_mockRegion] ?? const <MockLocationSpot>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('mock 위치', style: ChaerokTypography.bodyMedium),
        const SizedBox(height: ChaerokSpacing.xxs),
        const Text(
          '지점을 고르거나 지도에서 위치를 선택하면 mock 위치가 자동으로 켜져요. '
          '"공주 진입" 시나리오 실행 중에는 무시돼요.',
          style: ChaerokTypography.caption,
        ),
        const SizedBox(height: ChaerokSpacing.xs),
        Wrap(
          spacing: ChaerokSpacing.xs,
          children: [
            ChoiceChip(
              label: const Text('지점 선택'),
              selected: !_mockUseCustom,
              onSelected: (_) => _onMockModeChanged(false),
            ),
            ChoiceChip(
              label: const Text('지도에서 선택'),
              selected: _mockUseCustom,
              onSelected: (_) => _onMockModeChanged(true),
            ),
          ],
        ),
        const SizedBox(height: ChaerokSpacing.xs),
        if (_mockUseCustom)
          _buildMockMapPicker()
        else ...[
          Wrap(
            spacing: ChaerokSpacing.xs,
            children: [
              for (final region in RegionCode.values)
                ChoiceChip(
                  label: Text(region.displayName),
                  selected: region == _mockRegion,
                  onSelected: (_) => _onMockRegionSelected(region),
                ),
            ],
          ),
          const SizedBox(height: ChaerokSpacing.xs),
          Wrap(
            spacing: ChaerokSpacing.xs,
            children: [
              for (final (index, spot) in spots.indexed)
                ChoiceChip(
                  label: Text(spot.label),
                  selected: index == _mockSpotIndex,
                  onSelected: (_) => _onMockSpotSelected(index),
                ),
            ],
          ),
        ],
      ],
    );
  }

  /// 지도판을 탭해 mock 위치를 찍는 UI. 위젯 테스트에서는 네이티브 플랫폼 뷰를
  /// 띄우지 않도록 [TestModePanelScreen.debugDisableMapPicker]로 지도만 placeholder
  /// 로 대체하고, 탭은 [debugPickMockLocation]으로 시뮬레이션한다.
  Widget _buildMockMapPicker() {
    final hasPick = _pickedLatitude != null && _pickedLongitude != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          '지도를 눌러 위치를 선택하고 "이 위치로 적용"을 누르세요.',
          style: ChaerokTypography.caption,
        ),
        const SizedBox(height: ChaerokSpacing.xs),
        ClipRRect(
          borderRadius: BorderRadius.circular(ChaerokRadius.sm),
          child: SizedBox(
            height: 220,
            child: widget.debugDisableMapPicker
                ? const ColoredBox(color: ChaerokColors.sageLight)
                : KakaoMap(
                    option: KakaoMapOption(
                      position: _pickerInitialPosition(),
                      zoomLevel: 13,
                    ),
                    onMapReady: (controller) =>
                        unawaited(_onPickerMapReady(controller)),
                    onMapClick: (_, position) =>
                        _onMockMapPicked(position.latitude, position.longitude),
                  ),
          ),
        ),
        const SizedBox(height: ChaerokSpacing.xs),
        Text(
          hasPick
              ? '선택한 위치: ${_pickedLatitude!.toStringAsFixed(5)}, '
                    '${_pickedLongitude!.toStringAsFixed(5)}'
              : '선택한 위치 없음',
          style: ChaerokTypography.caption.copyWith(
            color: ChaerokColors.textSecondary,
          ),
        ),
        const SizedBox(height: ChaerokSpacing.xs),
        OutlinedButton(
          onPressed: hasPick ? _onApplyPickedMockLocation : null,
          child: const Text('이 위치로 적용'),
        ),
      ],
    );
  }

  /// 지도 초기 카메라 위치. 이미 찍은 좌표 → 선택된 지역/지점 → 공주 순.
  LatLng _pickerInitialPosition() {
    final latitude = _pickedLatitude;
    final longitude = _pickedLongitude;
    if (latitude != null && longitude != null) {
      return LatLng(latitude, longitude);
    }
    final spots = mockLocationSpots[_mockRegion] ?? const <MockLocationSpot>[];
    final anchor = spots.isEmpty
        ? mockLocationSpots[RegionCode.gongju]!.first
        : spots[_mockSpotIndex.clamp(0, spots.length - 1)];
    return LatLng(anchor.latitude, anchor.longitude);
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChaerokSpacing.lg),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
        border: Border.all(color: ChaerokColors.border),
      ),
      child: child,
    );
  }
}

/// 지도에서 찍은 mock 위치를 가리키는 핀 아이콘([KImage.fromWidget]용).
class _MockPickPin extends StatelessWidget {
  const _MockPickPin();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ChaerokColors.primaryDark,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.place, color: Colors.white, size: 16),
    );
  }
}
