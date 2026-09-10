import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/data/models/resolve_region_request.dart';
import 'package:chaerok/data/remote/places_api.dart';
import 'package:chaerok/data/remote/regions_api.dart';
import 'package:chaerok/features/home/presentation/widgets/film_collection_button.dart';
import 'package:chaerok/features/home/presentation/widgets/my_page_button.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_deck.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_load_status.dart';
import 'package:chaerok/features/settings/presentation/test_card_screen.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';

typedef RegionIdResolver = Future<int> Function(RegionCode region);
typedef PlacesFetcher = Future<List<PlaceListResponse>> Function(int regionId);

const _serviceProvinceName = '충청남도';

/// 기본 regionId 해석기: 백엔드에 (충청남도, 시/군)으로 지역 검증을 요청해
/// regionId를 얻는다. ExploreScreen._fetchPlaces와 동일 경로.
Future<int> defaultRegionIdResolver(RegionCode region) async {
  final resolved = await RegionsApi.resolveRegion(
    ResolveRegionRequest(
      provinceName: _serviceProvinceName,
      cityCountyName: region.cityCountyName,
    ),
  );
  return resolved.regionId;
}

/// 충청남도 외 지역 사용자에게 보여주는 홈 화면.
/// 상단 필름롤 스택([RegionFilmDeck])에서 4개 지역을 전환하며 지역별 장소를
/// 둘러본다. 열린 카드가 뷰포트를 채우고, 나머지 지역은 위에 탭만 겹친다.
class OutOfServiceHomeView extends StatefulWidget {
  const OutOfServiceHomeView({
    super.key,
    required this.onExploreRegionRequested,
    this.regionIdResolver = defaultRegionIdResolver,
    this.placesFetcher = PlacesApi.getExternalPlaces,
  });

  final ValueChanged<RegionCode> onExploreRegionRequested;
  final RegionIdResolver regionIdResolver;
  final PlacesFetcher placesFetcher;

  @override
  State<OutOfServiceHomeView> createState() => _OutOfServiceHomeViewState();
}

class _OutOfServiceHomeViewState extends State<OutOfServiceHomeView> {
  static const _tag = 'OutOfServiceHomeView';

  /// 필름롤 덱 순서. 맨 뒤 원소가 "열린" 카드이고, 나머지는 위에 탭만 겹친다.
  /// 초기값은 Figma 기준(공주·부여·서산 탭 + 예산 열림 = `RegionCode.values` 순서).
  List<RegionCode> _deckOrder = RegionCode.values.toList();

  RegionCode get _open => _deckOrder.last;

  final Map<RegionCode, _RegionData> _cache = {};

  /// 지역 전환이 빠르게 반복돼도 늦게 도착한 응답이 최신 상태를 덮어쓰지
  /// 않도록, 지역별 최신 요청만 반영한다(기존 화면들과 동일 패턴).
  final Map<RegionCode, int> _tokens = {};

  @override
  void initState() {
    super.initState();
    unawaited(_ensureLoaded(_open));
  }

  Future<void> _ensureLoaded(RegionCode region, {bool force = false}) async {
    final existing = _cache[region];
    if (!force &&
        existing != null &&
        existing.status == RegionLoadStatus.ready) {
      return;
    }

    final token = (_tokens[region] ?? 0) + 1;
    _tokens[region] = token;
    setState(() {
      _cache[region] = const _RegionData(status: RegionLoadStatus.loading);
    });

    try {
      final regionId =
          existing?.regionId ?? await widget.regionIdResolver(region);
      final places = await widget.placesFetcher(regionId);
      if (!mounted || _tokens[region] != token) return;
      setState(() {
        _cache[region] = _RegionData(
          status: RegionLoadStatus.ready,
          regionId: regionId,
          places: places,
        );
      });
    } catch (e, st) {
      log('지역 장소 로드 실패 ($region)', name: _tag, error: e, stackTrace: st);
      if (!mounted || _tokens[region] != token) return;
      setState(() {
        _cache[region] = _RegionData(
          status: RegionLoadStatus.error,
          regionId: existing?.regionId,
        );
      });
    }
  }

  /// 겹친 탭 탭 → 그 지역과 현재 열린 지역의 덱 슬롯을 스위치한다.
  /// 나머지 두 지역의 위치는 유지된다.
  void _onOpenRegion(RegionCode region) {
    if (region == _open) return;
    final next = [..._deckOrder];
    final tappedIndex = next.indexOf(region);
    final openIndex = next.length - 1;
    next[tappedIndex] = next[openIndex];
    next[openIndex] = region;
    setState(() => _deckOrder = next);
    unawaited(_ensureLoaded(region));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 하단 네비에서 없앤 필름 모음·마이페이지로 가는 유일한 진입점.
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const FilmCollectionButton(),
                const MyPageButton(),
                IconButton(
                  onPressed: () => unawaited(
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TestCardScreen(),
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.abc_outlined),
                ),
              ],
            ),
            Expanded(
              child: RegionFilmDeck(
                deckOrder: _deckOrder,
                dataByRegion: {
                  for (final region in RegionCode.values)
                    region: (
                      status:
                          _cache[region]?.status ?? RegionLoadStatus.loading,
                      places:
                          _cache[region]?.places ?? const <PlaceListResponse>[],
                    ),
                },
                onOpen: _onOpenRegion,
                onRetry: (region) =>
                    unawaited(_ensureLoaded(region, force: true)),
                onExploreRegionRequested: widget.onExploreRegionRequested,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionData {
  const _RegionData({
    required this.status,
    this.regionId,
    this.places = const [],
  });

  final RegionLoadStatus status;
  final int? regionId;
  final List<PlaceListResponse> places;
}
