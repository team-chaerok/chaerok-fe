import 'dart:async';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/course_place_response.dart';

import 'package:flutter/material.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

/// 지도에 마커로 표시할 장소 하나를 나타내는 값 객체.
/// [CourseCandidatePlace.fromCoursePlaceResponse]와 달리 좌표가 없거나 유효하지
/// 않은 장소를 예외 없이 건너뛰기 위해 별도로 둔다(지도 미리보기는 일부 장소의
/// 마커가 빠지더라도 나머지 장소는 그대로 보여줘야 한다).
class CourseMapMarker {
  const CourseMapMarker({
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.order,
  });

  final String title;
  final double latitude;
  final double longitude;
  final int order;

  /// [places] 중 좌표(위도/경도)가 없거나 유효 범위를 벗어난 장소는 제외하고 변환한다.
  /// [order]는 제외된 장소를 포함한 원래 코스 순번(1부터)을 유지한다.
  static List<CourseMapMarker> fromCoursePlaces(
    List<CoursePlaceResponse> places,
  ) {
    final markers = <CourseMapMarker>[];
    for (var i = 0; i < places.length; i++) {
      final place = places[i];
      final latitude = place.latitude;
      final longitude = place.longitude;
      if (latitude == null || longitude == null) continue;
      if (!latitude.isFinite || !longitude.isFinite) continue;
      if (latitude < -90 || latitude > 90) continue;
      if (longitude < -180 || longitude > 180) continue;

      markers.add(
        CourseMapMarker(
          title: place.title,
          latitude: latitude,
          longitude: longitude,
          order: i + 1,
        ),
      );
    }
    return markers;
  }
}

/// [CourseMapView]가 카메라를 어디로 옮길지 정한 결과. 지도 SDK 없이 검증할 수
/// 있도록 계산만 분리했다.
class CourseMapCameraTarget {
  const CourseMapCameraTarget.center(this.center)
    : fitPoints = const [],
      assert(center != null);

  const CourseMapCameraTarget.fit(this.fitPoints) : center = null;

  /// 한 곳만 비출 때의 중심. [fitPoints]가 있으면 null.
  final CourseMapMarker? center;

  /// 두 곳 이상을 한 화면에 담을 때의 좌표들.
  final List<CourseMapMarker> fitPoints;

  bool get isFit => center == null;

  /// [focusOrder] 마커가 있으면 그곳을, 없으면 코스 전체를 비춘다.
  /// 표시할 마커가 없으면 null.
  static CourseMapCameraTarget? resolve(
    List<CourseMapMarker> markers, {
    int? focusOrder,
  }) {
    if (markers.isEmpty) return null;
    if (focusOrder != null) {
      for (final marker in markers) {
        if (marker.order == focusOrder) {
          return CourseMapCameraTarget.center(marker);
        }
      }
    }
    if (markers.length == 1) return CourseMapCameraTarget.center(markers.first);
    return CourseMapCameraTarget.fit(markers);
  }
}

/// 코스에 포함된 장소들을 카카오맵 위에 순번이 매겨진 마커와 이동 경로선으로
/// 표시하는 위젯. 유효 좌표가 하나도 없으면 지도 대신 안내 문구를 보여준다.
///
/// [places]가 바뀌면 마커/경로를 새로 그리고 코스 전체가 보이도록 카메라를
/// 맞춘다. [focusOrder]가 바뀌면 해당 순번 마커를 강조하고 그곳으로 이동하며,
/// null이면 다시 코스 전체를 비춘다. 마커를 탭하면 [onMarkerTap]으로 순번이
/// 전달된다.
class CourseMapView extends StatefulWidget {
  const CourseMapView({
    super.key,
    required this.places,
    this.focusOrder,
    this.onMarkerTap,
  });

  final List<CoursePlaceResponse> places;
  final int? focusOrder;
  final ValueChanged<int>? onMarkerTap;

  @override
  State<CourseMapView> createState() => _CourseMapViewState();
}

class _CourseMapViewState extends State<CourseMapView> {
  static const double _markerSize = 28.0;
  static const double _focusedMarkerSize = 38.0;
  static const int _singlePlaceZoomLevel = 15;
  static const int _fitPadding = 80;

  KakaoMapController? _controller;
  final Map<int, Poi> _pois = {};
  Polyline? _polyline;

  /// 빠르게 코스를 넘길 때 앞선 그리기 작업이 늦게 끝나 뒤 코스 위에 덧그려지지
  /// 않도록, 새 그리기를 시작할 때마다 올려 이전 작업을 무효화한다.
  int _renderToken = 0;

  /// 아이콘 이미지는 (순번, 강조 여부)마다 한 번만 만든다.
  final Map<(int, bool), KImage> _iconCache = {};

  List<CourseMapMarker> get _markers =>
      CourseMapMarker.fromCoursePlaces(widget.places);

  @override
  void didUpdateWidget(CourseMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller == null) return;
    if (!identical(oldWidget.places, widget.places)) {
      unawaited(_render());
    } else if (oldWidget.focusOrder != widget.focusOrder) {
      unawaited(_applyFocus(oldWidget.focusOrder));
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = _markers;

    if (markers.isEmpty) {
      return const Center(
        child: Text('지도에 표시할 위치 정보가 없어요', style: ChaerokTypography.bodyMedium),
      );
    }

    return KakaoMap(
      option: KakaoMapOption(
        position: LatLng(markers.first.latitude, markers.first.longitude),
        zoomLevel: _singlePlaceZoomLevel,
      ),
      onMapReady: (controller) {
        _controller = controller;
        unawaited(_render());
      },
    );
  }

  Future<void> _render() async {
    final controller = _controller;
    if (controller == null) return;
    final token = ++_renderToken;
    final markers = _markers;

    await _clear(controller);
    if (!_isCurrent(token)) return;

    if (markers.length >= 2) {
      final polyline = await controller.shapeLayer.addPolylineShape(
        MapPoint([for (final m in markers) LatLng(m.latitude, m.longitude)]),
        PolylineStyle(
          ChaerokColors.primaryDark.withValues(alpha: 0.55),
          4,
          strokeWidth: 1,
          strokeColor: Colors.white,
        ),
        PolylineCap.round,
      );
      if (!_isCurrent(token)) {
        await polyline.remove();
        return;
      }
      _polyline = polyline;
    }

    for (final marker in markers) {
      final isFocused = marker.order == widget.focusOrder;
      final poi = await controller.labelLayer.addPoi(
        LatLng(marker.latitude, marker.longitude),
        style: await _poiStyle(marker.order, isFocused),
        text: marker.title,
        onClick: () => widget.onMarkerTap?.call(marker.order),
      );
      if (!_isCurrent(token)) {
        await poi.remove();
        return;
      }
      _pois[marker.order] = poi;
    }

    await _moveCamera(controller, markers);
  }

  /// 강조 마커만 다시 스타일링하고 카메라를 옮긴다(전체 재렌더 없이).
  Future<void> _applyFocus(int? previousFocusOrder) async {
    final controller = _controller;
    if (controller == null) return;

    final restyle = <int>{
      if (previousFocusOrder != null) previousFocusOrder,
      if (widget.focusOrder != null) widget.focusOrder!,
    };
    for (final order in restyle) {
      final poi = _pois[order];
      if (poi == null) continue;
      await poi.changeStyles(
        await _poiStyle(order, order == widget.focusOrder),
      );
    }
    await _moveCamera(controller, _markers);
  }

  Future<void> _moveCamera(
    KakaoMapController controller,
    List<CourseMapMarker> markers,
  ) async {
    final target = CourseMapCameraTarget.resolve(
      markers,
      focusOrder: widget.focusOrder,
    );
    if (target == null) return;

    final update = target.isFit
        ? CameraUpdate.fitMapPoints([
            for (final m in target.fitPoints) LatLng(m.latitude, m.longitude),
          ], padding: _fitPadding)
        : CameraUpdate.newCenterPosition(
            LatLng(target.center!.latitude, target.center!.longitude),
            zoomLevel: _singlePlaceZoomLevel,
          );
    await controller.moveCamera(update, animation: const CameraAnimation(300));
  }

  Future<void> _clear(KakaoMapController controller) async {
    final pois = _pois.values.toList();
    _pois.clear();
    for (final poi in pois) {
      await poi.remove();
    }
    final polyline = _polyline;
    _polyline = null;
    await polyline?.remove();
  }

  bool _isCurrent(int token) => mounted && token == _renderToken;

  Future<PoiStyle> _poiStyle(int order, bool isFocused) async {
    return PoiStyle(
      icon: await _icon(order, isFocused),
      textStyle: [
        PoiTextStyle(
          size: isFocused ? 26 : 24,
          color: ChaerokColors.textPrimary,
        ),
      ],
    );
  }

  Future<KImage> _icon(int order, bool isFocused) async {
    final key = (order, isFocused);
    final cached = _iconCache[key];
    if (cached != null) return cached;
    final size = isFocused ? _focusedMarkerSize : _markerSize;
    final icon = await KImage.fromWidget(
      _MarkerBadge(order: order, isFocused: isFocused),
      Size(size, size),
    );
    _iconCache[key] = icon;
    return icon;
  }

  @override
  void dispose() {
    _renderToken++;
    super.dispose();
  }
}

class _MarkerBadge extends StatelessWidget {
  const _MarkerBadge({required this.order, required this.isFocused});

  final int order;
  final bool isFocused;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ChaerokColors.primaryDark,
        shape: BoxShape.circle,
        border: isFocused ? Border.all(color: Colors.white, width: 3) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$order',
        style: ChaerokTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
