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

/// 코스에 포함된 장소들을 카카오맵 위에 순번이 매겨진 마커로 표시하는 위젯.
/// 유효 좌표가 하나도 없으면 지도 대신 안내 문구를 보여준다.
class CourseMapView extends StatelessWidget {
  const CourseMapView({super.key, required this.places});

  final List<CoursePlaceResponse> places;

  static const double _markerSize = 28.0;

  @override
  Widget build(BuildContext context) {
    final markers = CourseMapMarker.fromCoursePlaces(places);

    if (markers.isEmpty) {
      return const Center(
        child: Text('지도에 표시할 위치 정보가 없어요', style: ChaerokTypography.bodyMedium),
      );
    }

    return KakaoMap(
      option: KakaoMapOption(
        position: LatLng(markers.first.latitude, markers.first.longitude),
        zoomLevel: 15,
      ),
      onMapReady: (controller) => _addMarkers(controller, markers),
    );
  }

  Future<void> _addMarkers(
    KakaoMapController controller,
    List<CourseMapMarker> markers,
  ) async {
    for (final marker in markers) {
      final icon = await KImage.fromWidget(
        _MarkerBadge(order: marker.order),
        const Size(_markerSize, _markerSize),
      );
      await controller.labelLayer.addPoi(
        LatLng(marker.latitude, marker.longitude),
        style: PoiStyle(
          icon: icon,
          textStyle: const [
            PoiTextStyle(size: 24, color: ChaerokColors.textPrimary),
          ],
        ),
        text: marker.title,
      );
    }
  }
}

class _MarkerBadge extends StatelessWidget {
  const _MarkerBadge({required this.order});

  final int order;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: ChaerokColors.primaryDark,
        shape: BoxShape.circle,
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
