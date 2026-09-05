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
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/usecase/resolve_film_roll_entry_use_case.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_screen.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_entry_flow.dart';
import 'package:chaerok/features/home/data/weather_api_service.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/nearby_place_recorder.dart';
import 'package:chaerok/features/home/presentation/widgets/active_film_roll_card.dart';
import 'package:chaerok/features/home/presentation/widgets/film_collection_button.dart';
import 'package:chaerok/features/home/presentation/widgets/my_page_button.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart';
import 'package:chaerok/features/home/presentation/widgets/recommended_place_card.dart';
import 'package:chaerok/features/home/presentation/widgets/weather_card.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/features/location/presentation/location_verification_screen.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

/// 홈 탭: 현재 지역, 진행중 필름롤 진행률을 요약해 다음 행동(재개/시작)으로
/// 이끄는 상태 요약 대시보드. `home_screen.dart`(구 홈 화면)의 사용자 조회 ·
/// 위치 인증 게이트 · 필름롤 진입/재개 로직을 이식했다.
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key, this.onExploreRegionRequested});

  /// 충남 외 지역 홈에서 "OO 추천 채록길"/"전체보기" 탭 시, 채록길 탭으로
  /// 전환하며 해당 지역을 선택하도록 MainTabScreen에 위임한다.
  final ValueChanged<RegionCode>? onExploreRegionRequested;

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  static const _tag = 'HomeDashboardScreen';

  /// 홈 화면 캐러셀에 노출할 최근 촬영 사진 수(전체가 아닌 미리보기).
  static const _recentPhotoPreviewLimit = 10;

  /// 홈 콘텐츠 공통 좌우 패딩. ActiveFilmRollCard만 이 패딩을 적용하지 않아
  /// 화면 가장자리까지 노출된다.
  static const _contentPadding = EdgeInsets.symmetric(
    horizontal: ChaerokSpacing.xl,
  );

  UserResponse? _user;
  LocationVerificationResult? _locationResult;
  bool _isOutOfService = false;
  FilmRoll? _recoveredFilmRoll;
  bool _isEnteringFilmRoll = false;

  // 위치 인증 성공 직후 자동으로 지역 진입 → 코스 선택까지 이어주는 동안,
  // 같은 화면의 수동 "필름롤 시작하기" 버튼이 동시에 눌려 내비게이션이
  // 중복 push되는 것을 막기 위한 플래그.
  bool _isAutoConnectingFilmRoll = false;
  WeatherSummaryData? _weather;
  List<String> _recentPhotoThumbnailPaths = const [];
  List<RecommendedPlaceSummaryData> _nearbyPlaces = const [];

  // 재개/시작 버튼이 연타되는 등 _loadNearbyPlaces/_loadRecentPhotos가 겹쳐
  // 호출될 때, 먼저 시작한 요청이 나중에 끝나며 최신 상태를 stale 데이터로
  // 덮어쓰지 않도록 각각 요청 토큰으로 최신 호출만 반영한다.
  int _nearbyPlacesRequestToken = 0;
  int _recentPhotosRequestToken = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchUserInfo());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_ensureLocationVerified());
    });
    unawaited(_loadRecoveredFilmRoll());
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
  /// 아직 완료되지 않았다면 위치 인증 화면을 진입시킨다.
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

    final outcome = await Navigator.of(context)
        .push<LocationVerificationOutcome>(
          MaterialPageRoute(builder: (_) => const LocationVerificationScreen()),
        );
    if (!mounted) return;
    switch (outcome) {
      case LocationVerified(:final result):
        setState(() => _locationResult = result);
        unawaited(_onLocationVerified(result));
      case LocationOutOfService():
        setState(() => _isOutOfService = true);
      case null:
        // 사용자가 "지역별로 둘러보기" CTA 대신 AppBar/시스템 뒤로가기로 게이트를
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
  /// 코스 선택 화면까지 이어준다. 이미 진행중이면 진행 화면으로, 현상
  /// 대기중이면 현상 대기 화면으로 바로 연결한다(`ResolveFilmRollEntryUseCase`).
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

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FilmRollScreen(
            filmRollId: decision.filmRoll.id,
            regionId: result.region.regionId,
          ),
        ),
      );
    } on UnsupportedRegionException {
      // 서비스 미지원 지역 — 자동 진입 없이 기존 "필름롤 시작하기" 카드로 폴백.
    } catch (e, st) {
      log('필름롤 자동 진입 실패', name: _tag, error: e, stackTrace: st);
    } finally {
      if (mounted) setState(() => _isAutoConnectingFilmRoll = false);
      if (mounted) await _loadRecoveredFilmRoll();
    }
  }

  Future<void> _fetchWeather(LocationVerificationResult result) async {
    try {
      final weather = await WeatherApiService.getCurrentWeather(
        latitude: result.position.latitude,
        longitude: result.position.longitude,
      );
      if (!mounted || weather == null) return;
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

  /// 앱 재시작 시 진행중이던 필름롤이 있다면 복구해 "이어하기"로 노출한다.
  /// 복구 결과에 따라 사진 캐러셀과(위치 인증이 끝났다면) 근처 채록 장소의
  /// 채록 여부 뱃지도 함께 갱신한다.
  Future<void> _loadRecoveredFilmRoll() async {
    try {
      final recovered = await FilmRollModule.instance
          .recoverLastActiveFilmRoll();
      if (!mounted) return;
      setState(() {
        _recoveredFilmRoll = recovered;
        if (recovered == null) {
          _recentPhotoThumbnailPaths = const [];
          // 이전에 시작된 사진 조회가 아직 끝나지 않았다면, 그 결과가 뒤늦게
          // 도착해 방금 비운 상태를 다시 덮어쓰지 않도록 토큰을 무효화한다.
          _recentPhotosRequestToken++;
        }
      });

      if (recovered != null) {
        unawaited(_loadRecentPhotos(recovered.id));
      }
      final locationResult = _locationResult;
      if (locationResult != null) {
        unawaited(_loadNearbyPlaces(locationResult));
      }
    } catch (e, st) {
      log('필름롤 복구 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> _loadRecentPhotos(String filmRollId) async {
    final requestToken = ++_recentPhotosRequestToken;
    try {
      final photos = await FilmRollModule.instance.photoRepository
          .findByFilmRoll(filmRollId, limit: _recentPhotoPreviewLimit);
      if (!mounted || requestToken != _recentPhotosRequestToken) return;
      setState(() {
        _recentPhotoThumbnailPaths = photos
            .map((photo) => photo.thumbnailPath)
            .toList();
      });
    } catch (e, st) {
      log('최근 촬영 사진 조회 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> _onResumeFilmRollTap() async {
    final recovered = _recoveredFilmRoll;
    if (recovered == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FilmRollScreen(filmRollId: recovered.id),
      ),
    );
    if (!mounted) return;
    await _loadRecoveredFilmRoll();
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
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FilmRollScreen(
            filmRollId: filmRoll.id,
            regionId: locationResult.region.regionId,
          ),
        ),
      );
      if (!mounted) return;
      await _loadRecoveredFilmRoll();
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

  @override
  Widget build(BuildContext context) {
    if (_isOutOfService) {
      return OutOfServiceHomeView(
        onExploreRegionRequested: (region) =>
            widget.onExploreRegionRequested?.call(region),
      );
    }

    // 지름 593 고정 원. left/right를 둘 다 주면 자식 폭이 화면 폭으로 강제돼
    // 원이 393으로 줄어들기 때문에, left만 음수로 줘서 화면 중앙에 두고
    // 좌우로 넘치는 부분은 Stack 기본 클립(Clip.hardEdge)으로 잘리게 한다.
    const circleDiameter = 593.0;
    final circleLeft = (MediaQuery.sizeOf(context).width - circleDiameter) / 2;

    return Scaffold(
      backgroundColor: ChaerokColors.background,
      // 배경 원을 스크롤 뷰 바깥 Stack 자식으로 둬서 스크롤에 따라 움직이지 않는다.
      body: Stack(
        children: [
          Positioned(
            top: -382,
            left: circleLeft,
            child: Container(
              height: circleDiameter,
              width: circleDiameter,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: ChaerokColors.sageLight,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
            // 홈 콘텐츠는 좌우 패딩(_contentPadding)을 개별 자식에 적용하고,
            // ActiveFilmRollCard만 패딩 없이 화면 가장자리까지(full-bleed) 노출한다.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: _contentPadding,
                  child: _HomeHeader(
                    userNickname: _user?.nickname,
                    regionName: _locationResult?.region.cityCountyName,
                  ),
                ),
                const SizedBox(height: ChaerokSpacing.md),
                if (_weather != null) ...[
                  Padding(
                    padding: _contentPadding,
                    child: WeatherCard(data: _weather!),
                  ),
                  const SizedBox(height: ChaerokSpacing.lg),
                ],
                if (_recoveredFilmRoll != null)
                  GestureDetector(
                    onTap: _onResumeFilmRollTap,
                    child: ActiveFilmRollCard(
                      data: FilmRollSummaryData(
                        name: _recoveredFilmRoll!.title,
                        capturedCount: _recoveredFilmRoll!.visitedPlaceCount,
                        totalCount: _recoveredFilmRoll!.totalPlaceCount,
                        photoThumbnailPaths: _recentPhotoThumbnailPaths,
                      ),
                    ),
                  )
                else
                  Padding(
                    padding: _contentPadding,
                    child: _buildStartFilmRollCard(),
                  ),
                if (_nearbyPlaces.isNotEmpty) ...[
                  const SizedBox(height: ChaerokSpacing.xxl),
                  Padding(
                    padding: _contentPadding,
                    child: _buildNearbyPlacesSection(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyPlacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('가까운 채록 장소', style: ChaerokTypography.titleMedium),
        const SizedBox(height: ChaerokSpacing.sm),
        for (final place in _nearbyPlaces) ...[
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
            _locationResult != null
                ? '${_locationResult!.region.cityCountyName}에서 필름롤을 시작해보세요.'
                : '위치 인증이 완료되면 필름롤을 시작할 수 있어요.',
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.sm),
          ChaerokButton(
            text: '필름롤 시작하기',
            isEnabled: _locationResult != null && !_isAutoConnectingFilmRoll,
            isLoading: _isEnteringFilmRoll || _isAutoConnectingFilmRoll,
            onPressed: _onStartFilmRollTap,
          ),
        ],
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
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    regionName != null
                        ? '$_todayLabel · $regionName'
                        : _todayLabel,
                    style: ChaerokTypography.caption.copyWith(
                      color: ChaerokColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: ChaerokSpacing.xxs),
                  Text(
                    userNickname != null
                        ? '$userNickname님,\n오늘의 여행 기록을 남겨주세요'
                        : '안녕하세요',
                    style: ChaerokTypography.titleLarge.copyWith(
                      color: ChaerokColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const FilmCollectionButton(),
            const MyPageButton(),
          ],
        ),
        const SizedBox(height: ChaerokSpacing.xs),
      ],
    );
  }
}
