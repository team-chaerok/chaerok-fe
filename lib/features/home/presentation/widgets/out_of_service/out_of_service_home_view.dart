import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/data/models/resolve_region_request.dart';
import 'package:chaerok/data/remote/places_api.dart';
import 'package:chaerok/data/remote/regions_api.dart';
import 'package:chaerok/features/home/presentation/widgets/my_page_button.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_detail_panel.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_strip.dart';
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
/// 상단 필름롤 아코디언으로 4개 지역을 전환하며 지역별 장소를 둘러본다.
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

  /// Figma 기본 노출 지역(15-521).
  RegionCode _selected = RegionCode.yesan;

  final Map<RegionCode, _RegionData> _cache = {};

  /// 지역 전환이 빠르게 반복돼도 늦게 도착한 응답이 최신 상태를 덮어쓰지
  /// 않도록, 지역별 최신 요청만 반영한다(기존 화면들과 동일 패턴).
  final Map<RegionCode, int> _tokens = {};

  @override
  void initState() {
    super.initState();
    unawaited(_ensureLoaded(_selected));
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

  void _onSelect(RegionCode region) {
    if (region == _selected) return;
    setState(() => _selected = region);
    unawaited(_ensureLoaded(region));
  }

  @override
  Widget build(BuildContext context) {
    final data =
        _cache[_selected] ??
        const _RegionData(status: RegionLoadStatus.loading);

    return Scaffold(
      backgroundColor: ChaerokColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: MyPageButton(),
            ),
            RegionFilmStrip(selected: _selected, onSelect: _onSelect),
            Expanded(
              child: RegionDetailPanel(
                region: _selected,
                status: data.status,
                places: data.places,
                onRetry: () => _ensureLoaded(_selected, force: true),
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
