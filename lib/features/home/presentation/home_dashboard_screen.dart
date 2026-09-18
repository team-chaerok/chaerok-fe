import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/place_category.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/data/models/user_response.dart';
import 'package:chaerok/data/remote/users_api.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_photo.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/usecase/resolve_film_roll_entry_use_case.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_developing_view.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_entry_flow.dart';
import 'package:chaerok/features/home/data/weather_api_service.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/models/home_card_tab.dart';
import 'package:chaerok/features/home/presentation/nearby_place_recorder.dart';
import 'package:chaerok/features/home/presentation/widgets/folder_deck/folder_card.dart';
import 'package:chaerok/features/home/presentation/widgets/folder_deck/folder_card_deck.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_palette.dart';
import 'package:chaerok/features/home/presentation/widgets/recommended_place_card.dart';
import 'package:chaerok/features/home/presentation/widgets/region_photo_gallery.dart';
import 'package:chaerok/features/home/presentation/widgets/weather_card.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/features/location/data/location_verification_runner.dart';
import 'package:chaerok/features/location/presentation/location_verification_screen.dart';
import 'package:chaerok/features/settings/presentation/my_screen.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// 홈 탭: 현재 지역, 진행중 필름롤 진행률을 요약해 다음 행동(재개/시작)으로
/// 이끄는 상태 요약 대시보드. `home_screen.dart`(구 홈 화면)의 사용자 조회 ·
/// 위치 인증 게이트 · 필름롤 진입/재개 로직을 이식했다.
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({
    super.key,
    this.onExploreRegionRequested,
    @visibleForTesting this.debugRunLocationVerification,
  });

  /// 충남 외 지역 홈에서 "OO 추천 채록길"/"전체보기" 탭 시, 채록길 탭으로
  /// 전환하며 해당 지역을 선택하도록 MainTabScreen에 위임한다.
  final ValueChanged<RegionCode>? onExploreRegionRequested;

  /// 테스트에서 실제 위치 인증 절차([LocationVerificationRunner]) 대신 결과를
  /// 주입하기 위한 훅.
  @visibleForTesting
  final Future<LocationVerificationOutcome> Function()?
  debugRunLocationVerification;

  @override
  State<HomeDashboardScreen> createState() => HomeDashboardScreenState();
}

class HomeDashboardScreenState extends State<HomeDashboardScreen>
    with WidgetsBindingObserver {
  static const _tag = 'HomeDashboardScreen';

  UserResponse? _user;
  LocationVerificationResult? _locationResult;
  bool _isOutOfService = false;
  FilmRoll? _recoveredFilmRoll;
  bool _isEnteringFilmRoll = false;

  // 위치 인증 성공 직후 자동으로 지역 진입 → 코스 선택까지 이어주는 동안,
  // 같은 화면의 수동 "필름롤 시작하기" 버튼이 동시에 눌려 내비게이션이
  // 중복 push되는 것을 막기 위한 플래그.
  bool _isAutoConnectingFilmRoll = false;

  // 진행중 필름롤은 있지만 코스를 아직 선택하지 않은 상태에서, 갤러리 대신
  // 뜨는 "코스를 선택해주세요" 카드의 버튼이 연타되지 않도록 막는 플래그.
  bool _isSelectingCourseFromGallery = false;

  // 탭 재진입·카메라 종료·앱 포그라운드 복귀로 [refresh]가 겹쳐 불릴 때,
  // 진행 중인 조회에 나중 요청을 합류시키기 위한 상태. 나중 요청을 그냥
  // 버리면 먼저 시작된 조회가 stale 값을 읽은 경우(예: 카메라에서 방문
  // 완료 처리 전에 lifecycle resumed로 조회가 먼저 시작된 경우) 대시보드가
  // 최신 상태를 반영하지 못하므로, 대기 플래그를 세워 한 번 더 조회한다.
  bool _isRefreshing = false;
  bool _refreshQueued = false;

  WeatherSummaryData? _weather;
  List<FilmRollPhoto> _filmRollPhotos = const [];
  List<FilmRollPlace> _filmRollPlaces = const [];
  List<RecommendedPlaceSummaryData> _nearbyPlaces = const [];

  // 재개/시작 버튼이 연타되는 등 _loadNearbyPlaces/_loadFilmRollPhotos가 겹쳐
  // 호출될 때, 먼저 시작한 요청이 나중에 끝나며 최신 상태를 stale 데이터로
  // 덮어쓰지 않도록 각각 요청 토큰으로 최신 호출만 반영한다.
  int _nearbyPlacesRequestToken = 0;
  int _filmRollPhotosRequestToken = 0;
  // QA 위치를 연속으로 바꾸면 이전 _fetchWeather 응답이 새 응답보다 늦게 도착해
  // 최신 날씨를 덮어쓸 수 있으므로, _loadNearbyPlaces와 동일하게 토큰으로 막는다.
  int _weatherRequestToken = 0;

  /// 충남 홈 폴더 카드 덱 순서. 맨 뒤 원소가 "열린" 카드이고, 나머지는 위에
  /// 탭만 겹친다. 기본으로 현재여행지역 탭이 열려 있다.
  List<HomeCardTab> _deckOrder = const [
    HomeCardTab.filmArchive,
    HomeCardTab.myPage,
    HomeCardTab.region,
  ];

  /// 겹친 탭 탭 → 그 탭과 현재 열린 탭의 덱 슬롯을 스위치한다.
  /// 나머지 탭의 위치는 유지된다(OutOfServiceHomeView._onOpenRegion과 동일 패턴).
  void _onOpenTab(HomeCardTab tab) {
    if (tab == _deckOrder.last) return;
    setState(() => _deckOrder = FolderCardDeck.swapToFront(_deckOrder, tab));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_fetchUserInfo());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_ensureLocationVerified());
    });
    unawaited(refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// 앱이 포그라운드로 복귀하면 홈 대시보드를 재조회한다. 다른 탭·다른 앱에
  /// 머무는 동안 진행중 필름롤이 바뀌었을 수 있으므로 `ExploreScreenState`와
  /// 대칭으로 동작한다.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(refresh());
    }
  }

  /// 홈 대시보드가 [IndexedStack]으로 상시 유지되므로, 탭 재진입 · 카메라 액션
  /// 종료 · route pop 복귀 · 앱 포그라운드 복귀 시 `MainTabScreen` 또는
  /// 라이프사이클 콜백이 이 훅으로 진행중 필름롤 · 진행률 · 최근 사진 · 가까운
  /// 채록 장소를 재조회하게 한다. `ExploreScreenState.reevaluate`와 대칭이다.
  ///
  /// 사용자 정보 · 위치 인증 · 날씨는 재조회하지 않는다. 위치 인증을 다시
  /// 태우면 캐시 히트 시 [_autoConnectFilmRollEntry]가 코스 선택/필름롤 화면으로
  /// 자동 네비게이션하므로, 단순 탭 전환에서 절대 재실행하지 않는다.
  ///
  /// 조회가 진행 중일 때 다시 호출되면 요청을 버리지 않고 대기시켰다가,
  /// 현재 조회가 끝난 뒤 한 번 더 조회해 최신 상태를 반영한다.
  Future<void> refresh() async {
    if (_isRefreshing) {
      _refreshQueued = true;
      return;
    }
    _isRefreshing = true;
    try {
      do {
        _refreshQueued = false;

        // Test Mode(QA) 패널에서 "충남 외 지역 홈 강제" 토글이나 mock 위치를
        // 바꾸면 세션 캐시가 비워지고 이 플래그가 선다. 홈으로 돌아온 지금
        // 자동 네비게이션 없이 위치만 다시 판정해 정상 홈 ↔ 충남 외 지역 홈을
        // 전환한다. 재판정이 성공한 뒤에만 플래그를 내려, 도중에 예외가 나면
        // 다음 refresh에서 다시 시도한다. 활성 refresh 중 QA 변경이 들어와도
        // 큐 반복에서 이 검사를 다시 거치므로 놓치지 않는다.
        if (LocationVerificationResult.qaLocationDirty) {
          await _reevaluateLocationForQa();
          LocationVerificationResult.qaLocationDirty = false;
        }

        await _loadRecoveredFilmRoll();
      } while (_refreshQueued && mounted);
    } finally {
      _isRefreshing = false;
      _refreshQueued = false;
    }
  }

  /// QA 패널에서 위치 관련 설정을 바꾼 뒤 홈 복귀 시 호출된다. 위치 인증만 다시
  /// 수행하고 그 결과를 홈 표시 상태에만 반영한다 — [_autoConnectFilmRollEntry]
  /// (코스 선택/필름롤 화면 자동 push)는 실행하지 않는다.
  Future<void> _reevaluateLocationForQa() async {
    final outcome = await _runLocationVerification();
    if (!mounted) return;
    _applyLocationOutcome(outcome, autoConnect: false);
  }

  Future<void> _fetchUserInfo() async {
    try {
      final user = await UsersApi.getMyInformation();
      if (!mounted) return;
      setState(() => _user = user);
    } catch (e, st) {
      log('내 정보 조회 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  /// 위치 인증(권한 확인 → 좌표 획득 → 지역 판별 → 관광지 조회)이 이번 세션에
  /// 아직 완료되지 않았다면 화면 전환 없이 조용히 수행한다.
  ///
  /// 회원가입 직후 경로([SignupNavigation.toMainViaLocationVerification])는
  /// MainTabScreen 진입 전에 이미 sessionCache를 채우므로 아래 캐시 분기로 빠지고,
  /// 위치 인증 화면은 그 경로에서만 노출된다. 기존 회원이 앱을 재실행하면
  /// sessionCache가 비어 있으므로 러너로 조용히 확인하고, 권한 미허용·조회 실패
  /// 등 안내가 필요한 경우에만 위치 인증 화면(에러 스텝)으로 폴백한다.
  Future<void> _ensureLocationVerified() async {
    final cached = LocationVerificationResult.sessionCache;
    if (cached != null) {
      setState(() => _locationResult = cached);
      unawaited(_onLocationVerified(cached));
      return;
    }
    if (LocationVerificationResult.outOfServiceSessionCache) {
      setState(() => _isOutOfService = true);
      return;
    }

    final outcome = await _runLocationVerification();
    if (!mounted) return;

    if (outcome is! LocationVerificationFailed) {
      _applyLocationOutcome(outcome);
      return;
    }

    // 권한 미허용·좌표/지역/관광지 조회 실패 → 온보딩(idle) 뷰 없이 해당 안내
    // 스텝을 바로 띄우는 위치 인증 화면으로 폴백한다.
    final fallback = await Navigator.of(context)
        .push<LocationVerificationOutcome>(
          MaterialPageRoute(
            builder: (_) => LocationVerificationScreen(initialFailure: outcome),
          ),
        );
    if (!mounted) return;
    _applyLocationOutcome(fallback);
  }

  Future<LocationVerificationOutcome> _runLocationVerification() {
    final override = widget.debugRunLocationVerification;
    return override != null ? override() : LocationVerificationRunner.run();
  }

  /// 조용한 확인 또는 폴백 화면에서 돌아온 결과를 홈 상태에 반영한다.
  ///
  /// [autoConnect]가 false면(QA 재판정 경로) 위치 결과에 의존하는 날씨/근처
  /// 장소만 갱신하고, 코스 선택/필름롤 화면으로 자동 진입하지 않는다.
  void _applyLocationOutcome(
    LocationVerificationOutcome? outcome, {
    bool autoConnect = true,
  }) {
    switch (outcome) {
      case LocationVerified(:final result):
        setState(() {
          _locationResult = result;
          _isOutOfService = false;
        });
        if (autoConnect) {
          unawaited(_onLocationVerified(result));
        } else {
          unawaited(_fetchWeather(result));
          unawaited(_loadNearbyPlaces(result));
        }
      case LocationOutOfService():
        setState(() {
          _isOutOfService = true;
          _locationResult = null;
        });
      case LocationVerificationFailed():
      case null:
        // 폴백 화면을 "지역별로 둘러보기" CTA 대신 AppBar/시스템 뒤로가기로
        // 빠져나오면 outcome은 null이다. 이때도 게이트가 "서비스 지역 외" 카드를
        // 렌더하며 outOfServiceSessionCache를 세팅했을 수 있으므로, 캐시를 다시
        // 읽어 빈 대시보드에 갇히지 않고 충남 외 지역 홈으로 복구한다.
        if (LocationVerificationResult.outOfServiceSessionCache) {
          setState(() => _isOutOfService = true);
        }
    }
  }

  /// 위치 인증 결과가 확정된 뒤, 이 결과에 의존하는 날씨/근처 채록 장소
  /// 섹션을 채우고, 진행중 필름롤이 없으면 코스 선택까지 자동으로 이어준다.
  Future<void> _onLocationVerified(LocationVerificationResult result) async {
    await Future.wait([
      _fetchWeather(result),
      _loadNearbyPlaces(result),
      _autoConnectFilmRollEntry(result),
    ]);
  }

  /// 서비스 지역 확인 직후, 활성 필름롤이 없으면 해당 지역으로 자동 진입해
  /// 코스 선택 화면까지 이어준다(`ResolveFilmRollEntryUseCase`). 이미 진행중/
  /// 현상 대기중이면 화면을 더 push하지 않고 그대로 둔다 — 진행 상태는 홈
  /// 자체(사진 갤러리)가, 방문 인증/현상은 채록길 탭이 보여준다.
  Future<void> _autoConnectFilmRollEntry(
    LocationVerificationResult result,
  ) async {
    setState(() => _isAutoConnectingFilmRoll = true);
    try {
      final decision = await FilmRollModule.instance.resolveFilmRollEntry(
        result.region.cityCountyName,
        regionId: result.region.regionId,
      );
      if (!mounted) return;

      if (decision.action == FilmRollEntryAction.needsCourseSelection) {
        await pushCourseSelectionAndConfirm(
          context,
          filmRollId: decision.filmRoll.id,
          regionId: result.region.regionId,
        );
        if (!mounted) return;
      }
      // 홈 화면 자체가 진행중 필름롤을 사진 갤러리(RegionPhotoGallery)로 보여주므로,
      // 채록길 탭(FilmRollProgressView)과 역할이 겹치는 FilmRollScreen은 더 이상
      // push하지 않는다. finally의 refresh()가 방금 반영된 코스/장소를 읽어온다.
    } on UnsupportedRegionException {
      // 서비스 미지원 지역 — 자동 진입 없이 기존 "필름롤 시작하기" 카드로 폴백.
    } catch (e, st) {
      log('필름롤 자동 진입 실패', name: _tag, error: e, stackTrace: st);
    } finally {
      if (mounted) setState(() => _isAutoConnectingFilmRoll = false);
      if (mounted) await refresh();
    }
  }

  Future<void> _fetchWeather(LocationVerificationResult result) async {
    final requestToken = ++_weatherRequestToken;
    try {
      final weather = await WeatherApiService.getCurrentWeather(
        latitude: result.position.latitude,
        longitude: result.position.longitude,
      );
      if (!mounted || weather == null || requestToken != _weatherRequestToken) {
        return;
      }
      setState(() {
        _weather = WeatherSummaryData(
          regionName: result.region.cityCountyName,
          temperature: weather.temperature,
          weatherLabel: weather.weatherLabel,
        );
      });
    } catch (e, st) {
      log('날씨 조회 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  /// 위치 인증 흐름에서 이미 조회된 근처 장소([LocationVerificationResult.places])를
  /// 재사용해 채록길 탭의 별도 API 호출 없이 "가까운 채록 장소" 섹션을 채운다.
  /// 각 장소가 현재 진행중 필름롤에서 이미 채록되었는지 여부도 함께 계산한다.
  Future<void> _loadNearbyPlaces(LocationVerificationResult result) async {
    final requestToken = ++_nearbyPlacesRequestToken;
    List<FilmRollPlace> filmRollPlaces = const [];
    final filmRollId = _recoveredFilmRoll?.id;
    if (filmRollId != null) {
      try {
        filmRollPlaces = await FilmRollModule.instance.filmRollPlaceRepository
            .findByFilmRoll(filmRollId);
      } catch (e, st) {
        log('필름롤 장소 조회 실패', name: _tag, error: e, stackTrace: st);
      }
    }

    if (!mounted || requestToken != _nearbyPlacesRequestToken) return;
    setState(() {
      _filmRollPlaces = filmRollPlaces;
      _nearbyPlaces = [
        for (final (index, place) in result.places.indexed)
          _toNearbySummary(place, index, result.position, filmRollPlaces),
      ];
    });
  }

  RecommendedPlaceSummaryData _toNearbySummary(
    PlaceListResponse place,
    int index,
    Position currentPosition,
    List<FilmRollPlace> filmRollPlaces,
  ) {
    const moods = PlacePlaceholderMood.values;
    final meters = Geolocator.distanceBetween(
      currentPosition.latitude,
      currentPosition.longitude,
      place.latitude,
      place.longitude,
    );
    final distance = meters < 1000
        ? '${meters.round()}m'
        : '${(meters / 1000).toStringAsFixed(1)}km';

    return RecommendedPlaceSummaryData(
      name: place.title,
      category: PlaceExternalCategory.displayLabel(place.categoryDetail),
      imageUrl: place.firstImageUrl,
      distance: distance,
      placeholderMood: moods[index % moods.length],
      isRecorded: NearbyPlaceRecorder.isRecorded(place, filmRollPlaces),
    );
  }

  /// 앱 재시작 시 진행중이던 필름롤이 있다면 복구해 사진 갤러리로 노출한다.
  /// 복구 결과에 따라 필름롤 사진 목록과(위치 인증이 끝났다면) 근처 채록 장소의
  /// 채록 여부 뱃지도 함께 갱신한다.
  Future<void> _loadRecoveredFilmRoll() async {
    try {
      final recovered = await FilmRollModule.instance
          .recoverLastActiveFilmRoll();
      if (!mounted) return;
      setState(() {
        _recoveredFilmRoll = recovered;
        if (recovered == null) {
          _filmRollPhotos = const [];
          // 이전에 시작된 사진 조회가 아직 끝나지 않았다면, 그 결과가 뒤늦게
          // 도착해 방금 비운 상태를 다시 덮어쓰지 않도록 토큰을 무효화한다.
          _filmRollPhotosRequestToken++;
        }
      });

      if (recovered != null) {
        unawaited(_loadFilmRollPhotos(recovered.id));
        unawaited(_loadFilmRollPlaces(recovered.id));
        unawaited(
          _backfillPlaceImages(recovered.id, regionId: recovered.regionId),
        );
      }
      final locationResult = _locationResult;
      if (locationResult != null) {
        unawaited(_loadNearbyPlaces(locationResult));
      }
    } catch (e, st) {
      log('필름롤 복구 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  /// 갤러리(큰 사진+필름스트립)에 쓸 이 필름롤의 전체 사진(최대 24장)을 조회한다.
  Future<void> _loadFilmRollPhotos(String filmRollId) async {
    final requestToken = ++_filmRollPhotosRequestToken;
    try {
      final photos = await FilmRollModule.instance.photoRepository
          .findByFilmRoll(filmRollId);
      if (!mounted || requestToken != _filmRollPhotosRequestToken) return;
      setState(() => _filmRollPhotos = photos);
    } catch (e, st) {
      log('필름롤 사진 조회 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  /// 갤러리 필름스트립(장소 단위 칸)에 쓸 이 필름롤의 장소 목록을 조회한다.
  /// [_loadNearbyPlaces]/[_backfillPlaceImages]도 부수적으로 같은 상태를
  /// 갱신하지만 각각 위치 인증 완료·백필 성공 여부에 걸려있어 항상 도는
  /// 경로가 아니다 — 필름스트립이 장소 목록에 전적으로 의존하게 된 뒤로는
  /// 이 경로가 실패/지연되면 필름스트립 전체가 빈 상태로 보이는 문제가
  /// 있었다. 그래서 필름롤이 복구될 때마다 무조건 한 번 더 직접 읽어온다.
  Future<void> _loadFilmRollPlaces(String filmRollId) async {
    try {
      final places = await FilmRollModule.instance.filmRollPlaceRepository
          .findByFilmRoll(filmRollId);
      if (!mounted) return;
      setState(() => _filmRollPlaces = places);
    } catch (e, st) {
      log('필름롤 장소 조회 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  /// [SelectCourseUseCase]의 이미지 보충 기능 이전에 이미 코스가 확정된
  /// 필름롤은 장소 이미지가 계속 비어있다. 홈 진입 시 한 번 소급 보충하고,
  /// 갤러리("가 볼 장소" 미리보기)가 바로 반영하도록 장소 목록을 다시 읽는다.
  /// 이미 이미지가 있는 장소는 건드리지 않아 여러 번 호출해도 안전하다.
  Future<void> _backfillPlaceImages(String filmRollId, {int? regionId}) async {
    try {
      await FilmRollModule.instance.backfillPlaceImages(
        filmRollId,
        regionId: regionId,
      );
    } catch (e, st) {
      log('장소 이미지 소급 보충 실패', name: _tag, error: e, stackTrace: st);
      return;
    }
    if (!mounted) return;
    await _loadFilmRollPlaces(filmRollId);
  }

  /// 위치 인증으로 확인된 지역에 대한 로컬 필름롤을 찾거나 새로 생성해 진입한다.
  Future<void> _onStartFilmRollTap() async {
    final locationResult = _locationResult;
    if (locationResult == null ||
        _isEnteringFilmRoll ||
        _isAutoConnectingFilmRoll) {
      return;
    }

    setState(() => _isEnteringFilmRoll = true);
    try {
      final filmRoll = await FilmRollModule.instance.enterRegion(
        locationResult.region.cityCountyName,
        regionId: locationResult.region.regionId,
      );
      if (!mounted) return;
      // 새로 만든 필름롤은 아직 코스가 없으므로 코스 선택으로 바로 이어준다.
      // 이후 진행 상태는 FilmRollScreen이 아니라 홈의 사진 갤러리가 보여준다.
      await pushCourseSelectionAndConfirm(
        context,
        filmRollId: filmRoll.id,
        regionId: locationResult.region.regionId,
      );
      if (!mounted) return;
      await refresh();
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

  /// 진행중 필름롤은 있지만 코스를 아직 선택하지 않았을 때(예: 코스 선택
  /// 화면에서 뒤로가기로 빠져나온 경우) 갤러리 대신 뜨는 안내 카드의 버튼에서
  /// 호출한다. 채록길 탭의 [FilmRollProgressView._onSelectCourseTap]과 같은
  /// 목적지(코스 선택 화면)로 이어준다.
  Future<void> _onSelectCourseForRecoveredFilmRollTap() async {
    final filmRoll = _recoveredFilmRoll;
    if (filmRoll == null || _isSelectingCourseFromGallery) return;
    final regionId = filmRoll.regionId ?? _locationResult?.region.regionId;
    if (regionId == null) return;

    setState(() => _isSelectingCourseFromGallery = true);
    try {
      await pushCourseSelectionAndConfirm(
        context,
        filmRollId: filmRoll.id,
        regionId: regionId,
      );
      if (!mounted) return;
      await refresh();
    } finally {
      if (mounted) setState(() => _isSelectingCourseFromGallery = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOutOfService) {
      return OutOfServiceHomeView(
        onExploreRegionRequested: (region) =>
            widget.onExploreRegionRequested?.call(region),
      );
    }

    // 현재 위치 인증으로 확인된 지역의 필름롤 색·라벨 색(충남 외 지역 홈과 동일
    // 팔레트/규칙). 4개 지역 밖의 값이거나 위치 인증 전이면 배경색+검정 라벨로
    // 폴백한다.
    final regionCode = _locationResult != null
        ? RegionCode.fromCityCountyName(_locationResult!.region.cityCountyName)
        : null;
    final regionColor = regionCode?.filmTabColor ?? ChaerokColors.background;
    // filmLabelColor의 null은 "이 지역은 기본(흰색)을 쓴다"는 의도적 값이라
    // regionCode 자체가 없을 때(위치 인증 전/4개 지역 밖)만 검정으로 폴백한다.
    final regionLabelColor = regionCode == null
        ? const Color(0xFF000000)
        : regionCode.filmLabelColor;

    return Scaffold(
      backgroundColor: ChaerokColors.background,
      body: SafeArea(
        child: FolderCardDeck<HomeCardTab>(
          deckOrder: _deckOrder,
          onOpen: _onOpenTab,
          cardBuilder: (context, tab, opened) => switch (tab) {
            HomeCardTab.region => FolderCard(
              color: regionColor,
              label: _locationResult != null
                  ? '${_locationResult!.region.cityCountyName} 필름롤'
                  : '필름롤',
              labelColor: regionLabelColor,
              opened: opened,
              closedPreview: ColoredBox(color: regionColor),
              openedBody: _RoundedOpenedBody(
                child: _RegionHomeBody(
                  userNickname: _user?.nickname,
                  locationResult: _locationResult,
                  weather: _weather,
                  recoveredFilmRoll: _recoveredFilmRoll,
                  filmRollPhotos: _filmRollPhotos,
                  filmRollPlaces: _filmRollPlaces,
                  nearbyPlaces: _nearbyPlaces,
                  isAutoConnectingFilmRoll: _isAutoConnectingFilmRoll,
                  isEnteringFilmRoll: _isEnteringFilmRoll,
                  isSelectingCourse: _isSelectingCourseFromGallery,
                  onStartFilmRollTap: _onStartFilmRollTap,
                  onSelectCourseTap: _onSelectCourseForRecoveredFilmRollTap,
                  onVisitCompleted: refresh,
                ),
              ),
            ),
            HomeCardTab.filmArchive => FolderCard(
              color: ChaerokColors.skyBlue,
              label: '지난여행',
              opened: opened,
              closedPreview: const ColoredBox(color: ChaerokColors.skyBlue),
              openedBody: const _RoundedOpenedBody(
                child: _PlaceholderCardBody(text: '지난여행 화면은 곧 만나볼 수 있어요'),
              ),
            ),
            HomeCardTab.myPage => FolderCard(
              color: ChaerokColors.softBrown,
              label: '마이페이지',
              opened: opened,
              closedPreview: const ColoredBox(color: ChaerokColors.softBrown),
              openedBody: const _RoundedOpenedBody(
                child: MyScreen(showAppBar: false),
              ),
            ),
          },
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.userNickname, required this.regionName});

  static const _weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

  final String? userNickname;
  final String? regionName;

  /// "8월 14일 금요일"처럼 오늘 날짜를 한글 형식으로 표시한다.
  String get _todayLabel {
    final now = DateTime.now();
    return '${now.month}월 ${now.day}일 ${_weekdayNames[now.weekday - 1]}요일';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: ChaerokSpacing.xs),
        Text(
          regionName != null ? '$_todayLabel · $regionName' : _todayLabel,
          style: ChaerokTypography.caption.copyWith(
            color: ChaerokColors.textSecondary,
          ),
        ),
        const SizedBox(height: ChaerokSpacing.xxs),
        Text(
          userNickname != null ? '$userNickname님,\n오늘의 여행 기록을 남겨주세요' : '안녕하세요',
          style: ChaerokTypography.titleLarge.copyWith(
            color: ChaerokColors.textPrimary,
          ),
        ),
        const SizedBox(height: ChaerokSpacing.xs),
      ],
    );
  }
}

/// 폴더 카드 덱의 "현재여행지역" 탭 열린 본문. 기존 홈 대시보드가 그리던
/// 헤더·날씨·필름롤 카드·근처 채록 장소를 그대로 담는다(로직 변경 없이 위치만
/// 이동). 카드 body 영역 안에서 자체 스크롤한다.
class _RegionHomeBody extends StatelessWidget {
  const _RegionHomeBody({
    required this.userNickname,
    required this.locationResult,
    required this.weather,
    required this.recoveredFilmRoll,
    required this.filmRollPhotos,
    required this.filmRollPlaces,
    required this.nearbyPlaces,
    required this.isAutoConnectingFilmRoll,
    required this.isEnteringFilmRoll,
    required this.isSelectingCourse,
    required this.onStartFilmRollTap,
    required this.onSelectCourseTap,
    required this.onVisitCompleted,
  });

  final String? userNickname;
  final LocationVerificationResult? locationResult;
  final WeatherSummaryData? weather;
  final FilmRoll? recoveredFilmRoll;
  final List<FilmRollPhoto> filmRollPhotos;
  final List<FilmRollPlace> filmRollPlaces;
  final List<RecommendedPlaceSummaryData> nearbyPlaces;
  final bool isAutoConnectingFilmRoll;
  final bool isEnteringFilmRoll;

  /// 진행중 필름롤은 있지만 코스 미선택일 때 뜨는 안내 카드의 버튼 로딩 상태.
  final bool isSelectingCourse;
  final VoidCallback onStartFilmRollTap;

  /// 코스 미선택 안내 카드의 "추천 코스 선택하기" 버튼 콜백.
  final VoidCallback onSelectCourseTap;

  /// 갤러리에서 미방문 장소를 카메라로 인증하고 돌아오면, 최신 방문/사진
  /// 상태를 다시 읽어오도록 호출하는 콜백(`HomeDashboardScreenState.refresh`).
  final Future<void> Function() onVisitCompleted;

  /// 홈 콘텐츠 공통 좌우 패딩.
  static const _contentPadding = EdgeInsets.symmetric(
    horizontal: ChaerokSpacing.xl,
  );

  @override
  Widget build(BuildContext context) {
    // 필름롤이 진행중이면 사진 갤러리로 전체를 대체한다(헤더/날씨/근처 장소 없음).
    // 단, 코스를 아직 선택하지 않았다면(예: 코스 선택 화면에서 뒤로가기로
    // 빠져나온 경우) 빈 갤러리 대신 코스 선택으로 이어주는 안내 카드를 보여준다
    // — 채록길 탭의 FilmRollProgressView.hasCourse 분기와 동일한 목적.
    if (recoveredFilmRoll != null) {
      if (recoveredFilmRoll!.isDeveloping) {
        return ColoredBox(
          color: ChaerokColors.background,
          child: FilmRollDevelopingView(filmRoll: recoveredFilmRoll!),
        );
      }
      if (recoveredFilmRoll!.selectedCourseId == null) {
        return ColoredBox(
          color: ChaerokColors.background,
          child: Center(
            child: Padding(
              padding: _contentPadding,
              child: _buildNeedsCourseSelectionCard(),
            ),
          ),
        );
      }
      return ColoredBox(
        color: ChaerokColors.background,
        child: RegionPhotoGallery(
          filmRollId: recoveredFilmRoll!.id,
          photos: filmRollPhotos,
          places: filmRollPlaces,
          onVisitCompleted: onVisitCompleted,
        ),
      );
    }

    return ColoredBox(
      color: ChaerokColors.background,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: _contentPadding,
              child: _HomeHeader(
                userNickname: userNickname,
                regionName: locationResult?.region.cityCountyName,
              ),
            ),
            const SizedBox(height: ChaerokSpacing.md),
            if (weather != null) ...[
              Padding(
                padding: _contentPadding,
                child: WeatherCard(data: weather!),
              ),
              const SizedBox(height: ChaerokSpacing.lg),
            ],
            Padding(padding: _contentPadding, child: _buildStartFilmRollCard()),
            if (nearbyPlaces.isNotEmpty) ...[
              const SizedBox(height: ChaerokSpacing.xxl),
              Padding(
                padding: _contentPadding,
                child: _buildNearbyPlacesSection(),
              ),
            ],
            const SizedBox(height: ChaerokSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyPlacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('가까운 채록 장소', style: ChaerokTypography.titleMedium),
        const SizedBox(height: ChaerokSpacing.sm),
        for (final place in nearbyPlaces) ...[
          RecommendedPlaceCard(data: place, onTap: () {}),
          const SizedBox(height: ChaerokSpacing.sm),
        ],
      ],
    );
  }

  Widget _buildStartFilmRollCard() {
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
          const Text('필름롤', style: ChaerokTypography.bodyMedium),
          const SizedBox(height: ChaerokSpacing.xs),
          Text(
            locationResult != null
                ? '${locationResult!.region.cityCountyName}에서 필름롤을 시작해보세요.'
                : '위치 인증이 완료되면 필름롤을 시작할 수 있어요.',
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.sm),
          ChaerokButton(
            text: '필름롤 시작하기',
            isEnabled: locationResult != null && !isAutoConnectingFilmRoll,
            isLoading: isEnteringFilmRoll || isAutoConnectingFilmRoll,
            onPressed: onStartFilmRollTap,
          ),
        ],
      ),
    );
  }

  /// 진행중 필름롤은 있지만 코스를 아직 선택하지 않았을 때 빈 갤러리 대신
  /// 보여주는 안내 카드 — 채록길 탭의 "추천 코스 선택하기" 버튼과 동일한
  /// 문구/목적지를 쓴다.
  Widget _buildNeedsCourseSelectionCard() {
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
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('필름롤', style: ChaerokTypography.bodyMedium),
          const SizedBox(height: ChaerokSpacing.xs),
          Text(
            '코스를 아직 선택하지 않았어요. 코스를 선택하고 채록을 시작해보세요.',
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.sm),
          ChaerokButton(
            text: '추천 코스 선택하기',
            isEnabled: !isSelectingCourse,
            isLoading: isSelectingCourse,
            onPressed: onSelectCourseTap,
          ),
        ],
      ),
    );
  }
}

/// 열린 카드 본문 상단 좌우만 [ChaerokRadius.lg]로 둥글게 — 충남 외 지역 홈의
/// 크림 영역(`region_film_card.dart`의 `_bodyTopRadius`)과 동일한 값·처리.
/// 충남 홈 세 탭(현재여행지역/지난여행/마이페이지) 본문이 공통으로 쓴다.
class _RoundedOpenedBody extends StatelessWidget {
  const _RoundedOpenedBody({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(ChaerokRadius.lg),
      ),
      child: child,
    );
  }
}

/// "지난여행"/"마이페이지" 탭의 임시 본문. 화면 구성은 후속 작업에서 채운다.
class _PlaceholderCardBody extends StatelessWidget {
  const _PlaceholderCardBody({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ChaerokColors.background,
      child: Center(
        child: Text(
          text,
          style: ChaerokTypography.bodyMedium.copyWith(
            color: ChaerokColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
