import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/course_create_request.dart';
import 'package:chaerok/data/models/course_place_response.dart';
import 'package:chaerok/data/models/course_place_save_request.dart';
import 'package:chaerok/data/models/course_response.dart';
import 'package:chaerok/data/remote/courses_api.dart';
import 'package:chaerok/data/remote/places_api.dart';
import 'package:chaerok/features/explore/data/bookmark_store.dart';
import 'package:chaerok/features/explore/domain/explore_place.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/page/course_selection_result.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/recommended_course_carousel.dart';
import 'package:chaerok/shared/widgets/chaerok_appbar.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:chaerok/shared/widgets/course_map_view.dart';
import 'package:flutter/material.dart';

const _maxCustomCoursePlaces = 3;

/// 추천 코스 지도 영역을 그리는 빌더. 테스트에서 플랫폼 뷰인 카카오맵을 대체한다.
typedef CourseMapBuilder =
    Widget Function(
      BuildContext context,
      List<CoursePlaceResponse> places,
      int? focusOrder,
      ValueChanged<int> onMarkerTap,
    );

/// [CourseSelectionScreen]을 열 때 처음 보여줄 탭.
enum CourseSelectionInitialTab { recommended, custom }

enum _CourseMode { recommended, custom }

enum _CustomPlaceSource { region, search, bookmark }

/// 지역의 추천 코스 후보를 조회해 사용자가 하나를 고르거나, 관광지 목록·검색·
/// 북마크에서 장소를 직접 골라 코스를 만들 수 있는 화면.
///
/// 추천 모드에서 고른 [CourseResponse], 또는 직접 만들기 모드에서 이미
/// `CoursesApi.createCourse`로 생성한 [SelectedCourseResponse]와 원본 장소
/// 목록이 [CourseSelectionResult]에 담겨 `Navigator.pop`으로 반환된다.
/// 필름롤 스냅샷 저장(로컬 DB)은 [filmRollId]를 다시 요구하는 호출부가 맡는다.
/// 이 화면은 [filmRollId]를 직접 만들기 확정 전 변경 차단 여부 사전 확인에만 쓴다.
class CourseSelectionScreen extends StatefulWidget {
  const CourseSelectionScreen({
    super.key,
    required this.regionId,
    required this.filmRollId,
    this.initialTab = CourseSelectionInitialTab.recommended,
    this.initialSelectedPlace,
    this.debugFetchCourses,
    this.debugFetchRegionPlaces,
    this.debugMapBuilder,
  });

  final int regionId;

  /// 직접 만들기 모드 확정 시, 서버에 코스를 생성하기 전에 이미 방문/촬영
  /// 기록이 있어 변경이 차단될지 미리 확인하는 데 쓴다(§ 위험요소 참고).
  final String filmRollId;
  final CourseSelectionInitialTab initialTab;

  /// 북마크 카드의 "이 장소로 코스 만들기" 진입점에서 미리 담아 둘 장소.
  final ExplorePlace? initialSelectedPlace;

  /// 테스트용: 지정하면 추천 코스 조회를 API 대신 이 함수로 대체한다.
  final Future<List<CourseResponse>> Function()? debugFetchCourses;

  /// 테스트용: 지정하면 직접 만들기의 지역 관광지 조회를 API 대신 이 함수로 대체한다.
  final Future<List<ExplorePlace>> Function()? debugFetchRegionPlaces;

  /// 테스트용: 지정하면 지도 영역을 카카오맵 대신 이 빌더로 그린다.
  final CourseMapBuilder? debugMapBuilder;

  @override
  State<CourseSelectionScreen> createState() => _CourseSelectionScreenState();
}

class _CourseSelectionScreenState extends State<CourseSelectionScreen> {
  static const _tag = 'CourseSelectionScreen';

  // 추천 모드 상태.
  bool _isLoading = true;
  String? _errorMessage;
  List<CourseResponse> _courses = const [];

  /// 캐러셀에서 지금 보고 있는 추천 코스. 확정은 하단 버튼으로만 한다.
  int _selectedCourseIndex = 0;

  /// 지도가 강조 중인 장소의 코스 내 순번(1부터). 없으면 코스 전체를 보여준다.
  int? _focusedPlaceOrder;

  late _CourseMode _mode;

  // 직접 만들기 모드 상태.
  _CustomPlaceSource _customSource = _CustomPlaceSource.region;
  bool _isLoadingRegionPlaces = false;
  String? _regionPlacesError;
  List<ExplorePlace> _regionPlaces = const [];
  List<ExplorePlace> _searchResults = const [];
  String _searchKeyword = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  List<BookmarkedPlace> _bookmarkedPlaces = const [];
  String? _bookmarkedPlacesError;
  final List<ExplorePlace> _selectedPlaces = [];

  /// [_selectedPlaces]를 지도용으로 변환한 목록. 선택이 바뀔 때만 새로 만들어,
  /// 무관한 setState(검색어 입력 등)에서 지도가 다시 그려지지 않게 한다.
  List<CoursePlaceResponse> _selectedMapPlaces = const [];

  /// 직접 만들기 지도에서 강조 중인 선택 장소의 순번(1부터). 없으면 전체 보기.
  int? _customFocusOrder;
  bool _isCreatingCustomCourse = false;

  // 추천 코스 확정(서버 장소 확보) 중 여부.
  bool _isConfirmingCourse = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialTab == CourseSelectionInitialTab.custom
        ? _CourseMode.custom
        : _CourseMode.recommended;

    final initialPlace = widget.initialSelectedPlace;
    if (initialPlace != null) {
      _selectedPlaces.add(initialPlace);
      _syncSelectedMapPlaces();
      _customSource = _CustomPlaceSource.bookmark;
    }

    unawaited(_fetchCourses());
    if (_mode == _CourseMode.custom) {
      unawaited(_loadRegionPlaces());
      unawaited(_loadBookmarkedPlaces());
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final debugFetch = widget.debugFetchCourses;
      final courses = debugFetch != null
          ? await debugFetch()
          : (await CoursesApi.getRecommendedCourses(widget.regionId)).courses;

      if (!mounted) return;
      setState(() {
        _courses = courses;
        _selectedCourseIndex = 0;
        _focusedPlaceOrder = null;
        _isLoading = false;
      });
    } catch (e, st) {
      log('추천 코스 조회 실패', name: _tag, error: e, stackTrace: st);

      if (!mounted) return;
      setState(() {
        _errorMessage = apiErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  /// 추천 코스를 확정한다. 응답의 카카오 소싱 장소는 이 시점까지 `placeId`가
  /// 없다(서버 DB에 아직 없음) — 커스텀 코스와 마찬가지로 `createCourse`를
  /// 호출해 그 자리에서 장소를 찾거나 만들고, 응답의 실제 placeId를 채워
  /// 넣은 뒤 확정한다. 이 값을 그대로 두면 서버엔 place row가 없어 그
  /// 장소의 방문 인증이 영원히 동기화되지 않는다.
  Future<void> _onCourseSelected(CourseResponse course) async {
    if (_isConfirmingCourse) return;
    setState(() => _isConfirmingCourse = true);
    try {
      // createCourse는 서버의 기존 ACTIVE 코스를 조용히 INACTIVE 처리하고
      // 새로 만든다. 이미 방문/촬영 기록이 있어 로컬 확정(selectCourse)이
      // 어차피 막힐 상황이면, 서버 상태만 먼저 바뀌어 로컬/서버가 어긋나지
      // 않도록 호출 전에 미리 확인해 막는다(직접 만들기와 동일한 정책).
      final isBlocked = await FilmRollModule.instance.filmRollRepository
          .hasVisitOrPhotoRecords(widget.filmRollId);
      if (isBlocked) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 방문/촬영 기록이 있어 코스를 변경할 수 없습니다.')),
        );
        return;
      }

      // createCourse는 서버의 기존 ACTIVE 코스를 조용히 INACTIVE 처리하고
      // 새로 만든다. 방문/촬영 기록이 없어 위 확인은 통과했더라도, 이미
      // 만들어 둔 코스가 있다면(아직 하나도 인증하지 않은 상태) 사용자
      // 동의 없이 조용히 대체되지 않도록 직접 만들기와 동일하게 확인한다.
      final hasActiveCourse = await _hasActiveCourse();
      if (hasActiveCourse) {
        if (!mounted) return;
        final confirmed = await _showReplaceActiveCourseDialog();
        if (confirmed != true) return;
      }
      if (!mounted) return;

      final resolved = await CoursesApi.createCourse(
        CourseCreateRequest(
          regionId: widget.regionId,
          title: course.title,
          places: [
            for (final place in course.places)
              CoursePlaceSaveRequest(
                placeId: place.placeId,
                externalPlaceId: place.externalPlaceId,
                source: place.source,
                title: place.title,
                categoryGroup: place.categoryGroup,
                categoryDetail: place.categoryDetail,
                address: place.address,
                latitude: place.latitude,
                longitude: place.longitude,
                placeUrl: place.placeUrl,
              ),
          ],
        ),
      );
      if (!mounted) return;

      final resolvedPlaces = [...resolved.places]
        ..sort((a, b) => a.sequence.compareTo(b.sequence));
      // sequence로 index-정렬해 매칭하는 건 응답 장소 수가 요청 장소 수와
      // 정확히 같고 sequence 값이 서로 겹치지 않을 때만 안전하다. 어긋나면
      // 잘못된 placeId를 엉뚱한 장소에 붙이는 대신 매칭하지 않는다(직접
      // 만들기의 [SelectCustomCourseUseCase]와 동일한 정책).
      final isFullyResolved =
          resolvedPlaces.length == course.places.length &&
          resolvedPlaces.map((p) => p.sequence).toSet().length ==
              resolvedPlaces.length;
      final mergedPlaces = [
        for (var i = 0; i < course.places.length; i++)
          if (isFullyResolved)
            course.places[i].copyWithPlaceId(resolvedPlaces[i].placeId)
          else
            course.places[i],
      ];

      Navigator.of(context).pop(
        CourseSelectionResult.recommended(
          CourseResponse(
            title: course.title,
            score: course.score,
            places: mergedPlaces,
          ),
        ),
      );
    } catch (e, st) {
      log('추천 코스 확정 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isConfirmingCourse = false);
    }
  }

  void _onCoursePageChanged(int index) {
    setState(() {
      _selectedCourseIndex = index;
      _focusedPlaceOrder = null;
    });
  }

  /// 같은 장소를 다시 탭하면 강조를 풀고 코스 전체 보기로 돌아간다.
  void _onFocusPlace(int order) {
    setState(() {
      _focusedPlaceOrder = _focusedPlaceOrder == order ? null : order;
    });
  }

  void _onModeChanged(_CourseMode mode) {
    if (mode == _mode) return;
    setState(() => _mode = mode);
    if (mode == _CourseMode.custom &&
        _regionPlaces.isEmpty &&
        !_isLoadingRegionPlaces) {
      unawaited(_loadRegionPlaces());
      unawaited(_loadBookmarkedPlaces());
    }
  }

  Future<void> _loadRegionPlaces() async {
    setState(() {
      _isLoadingRegionPlaces = true;
      _regionPlacesError = null;
    });
    try {
      final debugFetch = widget.debugFetchRegionPlaces;
      final places = debugFetch != null
          ? await debugFetch()
          : (await PlacesApi.getPlaces(
              widget.regionId,
            )).map(ExplorePlace.fromListResponse).toList();
      if (!mounted) return;
      setState(() {
        _regionPlaces = places;
        _isLoadingRegionPlaces = false;
      });
    } catch (e, st) {
      log('관광지 목록 조회 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _regionPlacesError = apiErrorMessage(e);
        _isLoadingRegionPlaces = false;
      });
    }
  }

  Future<void> _loadBookmarkedPlaces() async {
    try {
      final places = await BookmarkStore.instance.list();
      if (!mounted) return;
      setState(() {
        _bookmarkedPlaces = places;
        _bookmarkedPlacesError = null;
      });
    } catch (e, st) {
      log('북마크 목록 조회 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _bookmarkedPlacesError = apiErrorMessage(e));
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

    final requestId = ++_searchRequestId;
    try {
      final results = await PlacesApi.searchPlaces(
        regionId: widget.regionId,
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

  int? _selectedOrderOf(ExplorePlace place) {
    final index = _selectedPlaces.indexWhere(
      (p) => p.identityKey == place.identityKey,
    );
    return index == -1 ? null : index + 1;
  }

  void _onTogglePlace(ExplorePlace place) {
    final index = _selectedPlaces.indexWhere(
      (p) => p.identityKey == place.identityKey,
    );
    if (index != -1) {
      setState(() {
        _selectedPlaces.removeAt(index);
        _syncSelectedMapPlaces();
        _customFocusOrder = null;
      });
      return;
    }
    if (_selectedPlaces.length >= _maxCustomCoursePlaces) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('코스는 최대 $_maxCustomCoursePlaces곳까지 담을 수 있어요'),
        ),
      );
      return;
    }
    setState(() {
      _selectedPlaces.add(place);
      _syncSelectedMapPlaces();
      // 방금 담은 장소를 지도에서 바로 확인할 수 있게 그곳을 비춘다.
      _customFocusOrder = _selectedPlaces.length;
    });
  }

  void _syncSelectedMapPlaces() {
    _selectedMapPlaces = [
      for (final place in _selectedPlaces)
        CoursePlaceResponse(
          source: place.source,
          title: place.title,
          categoryGroup: place.categoryGroupWire,
          address: place.address,
          latitude: place.latitude,
          longitude: place.longitude,
        ),
    ];
  }

  /// 같은 장소를 다시 탭하면 강조를 풀고 선택한 장소 전체 보기로 돌아간다.
  void _onFocusCustomPlace(int order) {
    setState(() {
      _customFocusOrder = _customFocusOrder == order ? null : order;
    });
  }

  void _onMoveSelected(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _selectedPlaces.length) return;
    setState(() {
      final place = _selectedPlaces.removeAt(index);
      _selectedPlaces.insert(target, place);
      _syncSelectedMapPlaces();
      _customFocusOrder = null;
    });
  }

  Future<void> _onConfirmCustomCourse() async {
    if (_selectedPlaces.isEmpty || _isCreatingCustomCourse) return;

    setState(() => _isCreatingCustomCourse = true);
    try {
      // 커스텀 코스는 매번 서버가 새 courseId를 발급하므로, 이미 방문/촬영
      // 기록이 있는 필름롤이면 항상 CourseChangeBlockedException으로
      // 차단된다. 이 판정은 로컬 확정 시점(호출부의 selectCustomCourse)에야
      // 내려지는데, 그때는 이미 서버 ACTIVE 코스가 생성/대체된 뒤라 서버와
      // 로컬이 어긋난다. createCourse를 호출하기 전에 미리 확인해 막는다.
      final isBlocked = await FilmRollModule.instance.filmRollRepository
          .hasVisitOrPhotoRecords(widget.filmRollId);
      if (isBlocked) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('이미 방문/촬영 기록이 있어 코스를 변경할 수 없습니다.')),
        );
        return;
      }

      final hasActiveCourse = await _hasActiveCourse();
      if (hasActiveCourse) {
        if (!mounted) return;
        final confirmed = await _showReplaceActiveCourseDialog();
        if (confirmed != true) return;
      }
      if (!mounted) return;

      final selectedPlaces = List<ExplorePlace>.of(_selectedPlaces);
      final response = await CoursesApi.createCourse(
        CourseCreateRequest(
          regionId: widget.regionId,
          title: '${selectedPlaces.first.title} 코스',
          places: [
            for (final place in selectedPlaces)
              CoursePlaceSaveRequest(
                placeId: place.serverId,
                externalPlaceId: place.externalPlaceId,
                source: place.source,
                title: place.title,
                categoryGroup: place.categoryGroupWire,
                categoryDetail: place.categoryDetailLabel,
                address: place.address.isEmpty ? null : place.address,
                latitude: place.latitude,
                longitude: place.longitude,
              ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pop(CourseSelectionResult.custom(response, selectedPlaces));
    } catch (e, st) {
      log('커스텀 코스 생성 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
    } finally {
      if (mounted) setState(() => _isCreatingCustomCourse = false);
    }
  }

  /// 현재 ACTIVE 코스가 있는지 확인한다. 조회에 실패하면(예: 아직 하나도
  /// 없어 404) 없는 것으로 간주해 대체 확인 없이 바로 진행한다 — 서버가
  /// 어차피 기존 ACTIVE 코스를 안전하게 대체하므로, 확인 여부 판단 실패가
  /// 코스 생성 자체를 막지는 않는다.
  Future<bool> _hasActiveCourse() async {
    try {
      final active = await CoursesApi.getActiveCourse();
      return active.placeCount > 0;
    } catch (e, st) {
      log('ACTIVE 코스 조회 실패', name: _tag, error: e, stackTrace: st);
      return false;
    }
  }

  Future<bool?> _showReplaceActiveCourseDialog() {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('기존에 만든 코스를 대체할까요?'),
        content: const Text('이미 만들어 둔 코스가 있어요. 새로 만들면 기존 코스는 사라져요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('대체하기'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: const ChaerokAppbar(title: '코스 선택'),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  ChaerokSpacing.md,
                  ChaerokSpacing.sm,
                  ChaerokSpacing.md,
                  0,
                ),
                child: _buildModeSwitch(),
              ),
              Expanded(
                child: _mode == _CourseMode.recommended
                    ? _buildRecommendedBody()
                    : _buildCustomBody(),
              ),
            ],
          ),
          if (_isConfirmingCourse)
            const ColoredBox(
              color: Color(0x66000000),
              child: Center(child: ChaerokLoadingIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildModeSwitch() {
    return Row(
      children: [
        Expanded(
          child: _ModeChip(
            label: '추천 코스',
            isSelected: _mode == _CourseMode.recommended,
            onTap: () => _onModeChanged(_CourseMode.recommended),
          ),
        ),
        const SizedBox(width: ChaerokSpacing.sm),
        Expanded(
          child: _ModeChip(
            label: '직접 만들기',
            isSelected: _mode == _CourseMode.custom,
            onTap: () => _onModeChanged(_CourseMode.custom),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedBody() {
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
            TextButton(onPressed: _fetchCourses, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return const Center(
        child: Text('추천 코스가 없어요', style: ChaerokTypography.bodyMedium),
      );
    }

    final selectedCourse = _courses[_selectedCourseIndex];
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              ChaerokSpacing.md,
              ChaerokSpacing.sm,
              ChaerokSpacing.md,
              ChaerokSpacing.sm,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(ChaerokRadius.lg),
              child: _buildCourseMap(selectedCourse),
            ),
          ),
        ),
        RecommendedCourseCarousel(
          courses: _courses,
          selectedIndex: _selectedCourseIndex,
          focusedPlaceOrder: _focusedPlaceOrder,
          onPageChanged: _onCoursePageChanged,
          onPlaceTap: _onFocusPlace,
        ),
        Container(
          padding: const EdgeInsets.all(ChaerokSpacing.md),
          child: SafeArea(
            top: false,
            child: ChaerokButton(
              text: '이 코스로 시작하기',
              isLoading: _isConfirmingCourse,
              onPressed: () => _onCourseSelected(selectedCourse),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseMap(CourseResponse course) {
    final builder = widget.debugMapBuilder;
    if (builder != null) {
      return builder(context, course.places, _focusedPlaceOrder, _onFocusPlace);
    }
    return CourseMapView(
      places: course.places,
      focusOrder: _focusedPlaceOrder,
      onMarkerTap: _onFocusPlace,
    );
  }

  Widget _buildCustomBody() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ChaerokSpacing.md,
            ChaerokSpacing.sm,
            ChaerokSpacing.md,
            0,
          ),
          child: _buildSourceSwitch(),
        ),
        if (_customSource == _CustomPlaceSource.search)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              ChaerokSpacing.md,
              ChaerokSpacing.sm,
              ChaerokSpacing.md,
              0,
            ),
            child: _buildSearchField(),
          ),
        // 키보드가 올라오면(검색 입력 중) 목록 공간을 지키기 위해 지도를 접는다.
        if (MediaQuery.of(context).viewInsets.bottom == 0)
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                ChaerokSpacing.md,
                ChaerokSpacing.sm,
                ChaerokSpacing.md,
                0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ChaerokRadius.lg),
                child: _buildCustomMap(),
              ),
            ),
          ),
        Expanded(flex: 3, child: _buildSourceList()),
        _buildSelectedPreview(),
        _buildConfirmFooter(),
      ],
    );
  }

  Widget _buildCustomMap() {
    final builder = widget.debugMapBuilder;
    if (builder != null && _selectedMapPlaces.isNotEmpty) {
      return builder(
        context,
        _selectedMapPlaces,
        _customFocusOrder,
        _onFocusCustomPlace,
      );
    }
    return ColoredBox(
      color: ChaerokColors.sageLight,
      child: CourseMapView(
        places: _selectedMapPlaces,
        focusOrder: _customFocusOrder,
        onMarkerTap: _onFocusCustomPlace,
        emptyMessage: '아래에서 장소를 고르면\n지도에 순서대로 표시돼요',
      ),
    );
  }

  Widget _buildSourceSwitch() {
    return Row(
      children: [
        for (final source in _CustomPlaceSource.values) ...[
          if (source != _CustomPlaceSource.values.first)
            const SizedBox(width: ChaerokSpacing.xs),
          Expanded(
            child: ChoiceChip(
              label: Text(_sourceLabel(source)),
              selected: _customSource == source,
              onSelected: (_) => setState(() => _customSource = source),
              selectedColor: ChaerokColors.primary,
              backgroundColor: ChaerokColors.sageLight,
              labelStyle: ChaerokTypography.bodyMedium.copyWith(
                color: _customSource == source
                    ? ChaerokColors.surface
                    : ChaerokColors.primaryDark,
              ),
              side: BorderSide.none,
            ),
          ),
        ],
      ],
    );
  }

  String _sourceLabel(_CustomPlaceSource source) => switch (source) {
    _CustomPlaceSource.region => '관광지 목록',
    _CustomPlaceSource.search => '검색',
    _CustomPlaceSource.bookmark => '북마크',
  };

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

  Widget _buildSourceList() {
    return switch (_customSource) {
      _CustomPlaceSource.region => _buildRegionPlacesList(),
      _CustomPlaceSource.search => _buildSearchResultsList(),
      _CustomPlaceSource.bookmark => _buildBookmarkedPlacesList(),
    };
  }

  Widget _buildRegionPlacesList() {
    if (_isLoadingRegionPlaces) {
      return const Center(child: ChaerokLoadingIndicator());
    }
    if (_regionPlacesError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _regionPlacesError!,
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.error,
              ),
            ),
            const SizedBox(height: ChaerokSpacing.sm),
            TextButton(
              onPressed: _loadRegionPlaces,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    return _buildPlacePickerList(
      _regionPlaces,
      emptyLabel: '이 지역의 관광지 정보가 없어요',
    );
  }

  Widget _buildSearchResultsList() {
    if (_searchKeyword.isEmpty) {
      return const Center(
        child: Text('장소를 검색해 보세요', style: ChaerokTypography.bodyMedium),
      );
    }
    return _buildPlacePickerList(_searchResults, emptyLabel: '검색 결과가 없어요');
  }

  Widget _buildBookmarkedPlacesList() {
    if (_bookmarkedPlacesError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _bookmarkedPlacesError!,
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.error,
              ),
            ),
            const SizedBox(height: ChaerokSpacing.sm),
            TextButton(
              onPressed: _loadBookmarkedPlaces,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final usable = <ExplorePlace>[];
    var excludedCount = 0;
    for (final place in _bookmarkedPlaces) {
      if (place.canBuildCourse) {
        usable.add(ExplorePlace.fromBookmarkedPlace(place));
      } else {
        excludedCount++;
      }
    }

    // 필드 보강(categoryGroupWire/source 등) 이전에 저장된 북마크는
    // canBuildCourse가 false라 조용히 제외되는데, 그러면 실제로는 북마크가
    // 있는데도 "없어요"만 보여 사용자가 원인을 알 수 없다. 제외된 개수를 알린다.
    if (usable.isEmpty) {
      return Center(
        child: Text(
          excludedCount > 0
              ? '코스에 사용할 수 없는 북마크 $excludedCount곳은 다시 북마크해 주세요'
              : '북마크한 장소가 없어요',
          textAlign: TextAlign.center,
          style: ChaerokTypography.bodyMedium,
        ),
      );
    }

    if (excludedCount == 0) {
      return _buildPlacePickerList(usable, emptyLabel: '북마크한 장소가 없어요');
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: ChaerokSpacing.md,
            vertical: ChaerokSpacing.xs,
          ),
          child: Text(
            '코스에 사용할 수 없는 북마크 $excludedCount곳은 제외했어요. 다시 북마크해 주세요.',
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: _buildPlacePickerList(usable, emptyLabel: '북마크한 장소가 없어요'),
        ),
      ],
    );
  }

  Widget _buildPlacePickerList(
    List<ExplorePlace> places, {
    required String emptyLabel,
  }) {
    if (places.isEmpty) {
      return Center(
        child: Text(emptyLabel, style: ChaerokTypography.bodyMedium),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      itemCount: places.length,
      separatorBuilder: (_, _) => const SizedBox(height: ChaerokSpacing.xs),
      itemBuilder: (context, index) {
        final place = places[index];
        return _PlacePickerTile(
          place: place,
          selectedOrder: _selectedOrderOf(place),
          onTap: () => _onTogglePlace(place),
        );
      },
    );
  }

  Widget _buildSelectedPreview() {
    if (_selectedPlaces.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ChaerokSpacing.md,
        vertical: ChaerokSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ChaerokColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '선택한 장소 (${_selectedPlaces.length}/$_maxCustomCoursePlaces)',
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.xs),
          for (final (index, place) in _selectedPlaces.indexed)
            _SelectedPlaceRow(
              order: index + 1,
              place: place,
              isFocused: _customFocusOrder == index + 1,
              onTap: () => _onFocusCustomPlace(index + 1),
              canMoveUp: index > 0,
              canMoveDown: index < _selectedPlaces.length - 1,
              onMoveUp: () => _onMoveSelected(index, -1),
              onMoveDown: () => _onMoveSelected(index, 1),
              onRemove: () => _onTogglePlace(place),
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmFooter() {
    return Container(
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      decoration: const BoxDecoration(
        color: ChaerokColors.surface,
        border: Border(top: BorderSide(color: ChaerokColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: ChaerokButton(
          text: '이 장소들로 코스 만들기',
          isEnabled: _selectedPlaces.isNotEmpty,
          isLoading: _isCreatingCustomCourse,
          onPressed: _onConfirmCustomCourse,
        ),
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? ChaerokColors.primary : ChaerokColors.sageLight,
      borderRadius: BorderRadius.circular(ChaerokRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ChaerokSpacing.sm),
          child: Center(
            child: Text(
              label,
              style: ChaerokTypography.bodyMedium.copyWith(
                color: isSelected
                    ? ChaerokColors.surface
                    : ChaerokColors.primaryDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 관광지 목록·검색·북마크 공통 장소 피커 항목. 선택 순서를 배지로 보여준다.
class _PlacePickerTile extends StatelessWidget {
  const _PlacePickerTile({
    required this.place,
    required this.selectedOrder,
    required this.onTap,
  });

  final ExplorePlace place;
  final int? selectedOrder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedOrder != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ChaerokRadius.md),
      child: Container(
        padding: const EdgeInsets.all(ChaerokSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? ChaerokColors.sageLight : ChaerokColors.surface,
          borderRadius: BorderRadius.circular(ChaerokRadius.md),
          border: Border.all(
            color: isSelected ? ChaerokColors.primary : ChaerokColors.border,
          ),
        ),
        child: Row(
          children: [
            _SelectionBadge(order: selectedOrder),
            const SizedBox(width: ChaerokSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.title, style: ChaerokTypography.bodyMedium),
                  const SizedBox(height: 2),
                  Text(
                    place.categoryDisplayLabel,
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
    );
  }
}

class _SelectionBadge extends StatelessWidget {
  const _SelectionBadge({required this.order});

  final int? order;

  @override
  Widget build(BuildContext context) {
    final order = this.order;
    return Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: order != null ? ChaerokColors.primary : Colors.transparent,
        border: Border.all(
          color: order != null ? ChaerokColors.primary : ChaerokColors.border,
        ),
      ),
      child: order != null
          ? Text(
              '$order',
              style: ChaerokTypography.caption.copyWith(
                color: ChaerokColors.surface,
              ),
            )
          : null,
    );
  }
}

/// 선택된 장소 미리보기의 한 행. 순서 변경(위/아래)과 제거를 제공한다.
class _SelectedPlaceRow extends StatelessWidget {
  const _SelectedPlaceRow({
    required this.order,
    required this.place,
    required this.isFocused,
    required this.onTap,
    required this.canMoveUp,
    required this.canMoveDown,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onRemove,
  });

  final int order;
  final ExplorePlace place;
  final bool isFocused;
  final VoidCallback onTap;
  final bool canMoveUp;
  final bool canMoveDown;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Row(
                children: [
                  Text('$order.', style: ChaerokTypography.caption),
                  const SizedBox(width: ChaerokSpacing.xs),
                  Expanded(
                    child: Text(
                      place.title,
                      style: ChaerokTypography.bodyMedium.copyWith(
                        fontWeight: isFocused
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            onPressed: canMoveUp ? onMoveUp : null,
            icon: const Icon(Icons.arrow_upward),
          ),
          IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            onPressed: canMoveDown ? onMoveDown : null,
            icon: const Icon(Icons.arrow_downward),
          ),
          IconButton(
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            onPressed: onRemove,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}
