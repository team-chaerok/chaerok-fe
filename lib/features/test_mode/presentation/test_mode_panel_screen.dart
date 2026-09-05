import 'dart:async';

import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/core/location/mock_location_gate.dart';
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
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:flutter/material.dart';

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
  const TestModePanelScreen({super.key});

  @override
  State<TestModePanelScreen> createState() => _TestModePanelScreenState();
}

class _TestModePanelScreenState extends State<TestModePanelScreen> {
  bool _busy = false;
  FilmRoll? _activeFilmRoll;
  List<FilmRollPlace> _places = const [];
  bool _isForceOutOfServiceArea = false;

  @override
  void initState() {
    super.initState();
    TestModeSession.instance.addListener(_onSessionChanged);
    unawaited(_reload());
  }

  @override
  void dispose() {
    TestModeSession.instance.removeListener(_onSessionChanged);
    super.dispose();
  }

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
    final forceOutOfService = await AppPreferences.instance
        .isDebugOutOfServiceArea();
    if (!mounted) return;
    setState(() {
      _activeFilmRoll = active;
      _places = places;
      _isForceOutOfServiceArea = forceOutOfService;
    });
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      LocationVerificationResult.sessionCache = null;
      LocationVerificationResult.outOfServiceSessionCache = false;
      await AppPreferences.instance.setMockLocationEnabled(false);
      await AppPreferences.instance.setDebugOutOfServiceArea(false);
    }, done: '테스트 상태를 초기화했어요');
  }

  Future<void> _onForceOutOfServiceChanged(bool enabled) async {
    setState(() => _isForceOutOfServiceArea = enabled);
    await AppPreferences.instance.setDebugOutOfServiceArea(enabled);
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
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text(
          'Test Mode (QA)',
          style: ChaerokTypography.titleMedium,
        ),
      ),
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
        ],
      ),
    );
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
          const SizedBox(height: ChaerokSpacing.sm),
          TextButton(
            onPressed: _onOpenDbViewer,
            child: const Text('로컬 DB 확인하기'),
          ),
        ],
      ),
    );
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
