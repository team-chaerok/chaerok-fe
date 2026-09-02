import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:flutter/material.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

/// 지도 마커 하나의 상태. 탐색 모드/진행 모드에서 서로 다른 스타일로 렌더된다.
enum ExploreMarkerState {
  /// 탐색: 일반 주변 장소.
  normal,

  /// 탐색: 추천/대표 장소 강조.
  recommended,

  /// 진행: 방문 완료.
  visited,

  /// 진행: 다음 방문 대상.
  next,

  /// 진행: 미방문.
  unvisited,

  /// 진행: 현재 위치 기준 방문 인증 가능.
  verifiable,
}

/// 지도에 찍을 마커 한 건.
class ExploreMapMarker {
  const ExploreMapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.state,
  });

  final String id;
  final double latitude;
  final double longitude;
  final String label;
  final ExploreMarkerState state;

  bool get hasValidCoordinate =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

/// `CourseMapView`와 달리 마커 목록이 바뀔 때마다 갱신되는 카카오맵 위젯.
///
/// `KakaoMap`은 `onMapReady`가 최초 1회만 발화하므로, 컨트롤러를 State에
/// 보관하고 [didUpdateWidget]에서 POI를 다시 그린다. [enabled]가 false면
/// 네이티브 뷰를 만들지 않는다(탭 최초 진입 전 지연 로드).
class ExploreMapView extends StatefulWidget {
  const ExploreMapView({
    super.key,
    required this.markers,
    this.focus,
    this.enabled = true,
  });

  final List<ExploreMapMarker> markers;

  /// 카메라를 이동시킬 좌표(다음 장소 보기 등). null이면 이동하지 않는다.
  final ExploreMapMarker? focus;
  final bool enabled;

  @override
  State<ExploreMapView> createState() => _ExploreMapViewState();
}

class _ExploreMapViewState extends State<ExploreMapView> {
  static const _tag = 'ExploreMapView';
  static const double _markerSize = 28;
  static const int _defaultZoomLevel = 13;

  KakaoMapController? _controller;
  final List<Poi> _pois = [];

  /// 마커 갱신 요청 세대. 이전 세대의 비동기 addPoi가 뒤늦게 끝나 새 마커를
  /// 덮어쓰지 않도록 한다.
  int _syncGeneration = 0;

  String? _focusedMarkerId;

  @override
  void didUpdateWidget(covariant ExploreMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_markerListEquals(oldWidget.markers, widget.markers)) {
      unawaited(_syncMarkers());
    }
    final focus = widget.focus;
    if (focus != null && focus.id != _focusedMarkerId) {
      _focusedMarkerId = focus.id;
      unawaited(_moveCameraTo(focus));
    }
  }

  Future<void> _onMapReady(KakaoMapController controller) async {
    _controller = controller;
    await _syncMarkers();
    final focus = widget.focus;
    if (focus != null) {
      _focusedMarkerId = focus.id;
      await _moveCameraTo(focus);
    }
  }

  Future<void> _syncMarkers() async {
    final controller = _controller;
    if (controller == null) return;

    final generation = ++_syncGeneration;
    final validMarkers = widget.markers
        .where((marker) => marker.hasValidCoordinate)
        .toList();

    try {
      for (final poi in _pois) {
        await poi.remove();
      }
      _pois.clear();

      for (final marker in validMarkers) {
        if (generation != _syncGeneration || !mounted) return;
        final icon = await KImage.fromWidget(
          _MarkerBadge(state: marker.state),
          const Size(_markerSize, _markerSize),
        );
        final poi = await controller.labelLayer.addPoi(
          LatLng(marker.latitude, marker.longitude),
          style: PoiStyle(
            icon: icon,
            textStyle: const [
              PoiTextStyle(size: 22, color: ChaerokColors.textPrimary),
            ],
          ),
          text: marker.label,
        );
        _pois.add(poi);
      }
    } catch (e, st) {
      log('지도 마커 갱신 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> _moveCameraTo(ExploreMapMarker marker) async {
    final controller = _controller;
    if (controller == null || !marker.hasValidCoordinate) return;
    try {
      await controller.moveCamera(
        CameraUpdate.newCenterPosition(
          LatLng(marker.latitude, marker.longitude),
          zoomLevel: _defaultZoomLevel + 2,
        ),
      );
    } catch (e, st) {
      log('지도 카메라 이동 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  bool _markerListEquals(List<ExploreMapMarker> a, List<ExploreMapMarker> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].state != b[i].state) return false;
    }
    return true;
  }

  ExploreMapMarker? get _firstValidMarker {
    for (final marker in widget.markers) {
      if (marker.hasValidCoordinate) return marker;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const ColoredBox(color: ChaerokColors.sageLight);
    }

    final first = _firstValidMarker;
    return KakaoMap(
      option: KakaoMapOption(
        position: first != null
            ? LatLng(first.latitude, first.longitude)
            : KakaoMapOption.defaultPosition,
        zoomLevel: _defaultZoomLevel,
      ),
      onMapReady: (controller) => unawaited(_onMapReady(controller)),
    );
  }
}

/// 마커 아이콘. 상태별로 색/글리프를 달리한다.
class _MarkerBadge extends StatelessWidget {
  const _MarkerBadge({required this.state});

  final ExploreMarkerState state;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (state) {
      ExploreMarkerState.normal => (ChaerokColors.primary, Icons.place),
      ExploreMarkerState.recommended => (
        ChaerokColors.primaryDark,
        Icons.star_rounded,
      ),
      ExploreMarkerState.visited => (
        ChaerokColors.primaryDark,
        Icons.check_rounded,
      ),
      ExploreMarkerState.next => (
        ChaerokColors.primaryDark,
        Icons.navigation_rounded,
      ),
      ExploreMarkerState.unvisited => (ChaerokColors.primary, Icons.place),
      ExploreMarkerState.verifiable => (
        ChaerokColors.error,
        Icons.my_location_rounded,
      ),
    };

    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 14),
    );
  }
}
