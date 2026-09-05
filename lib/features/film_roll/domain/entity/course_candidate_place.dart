import 'package:chaerok/data/models/course_place_response.dart';
import 'package:chaerok/features/explore/domain/explore_place.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';

/// 추천/커스텀 코스 후보에 포함된 장소 하나를 필름롤 스냅샷으로 저장하기 위한 입력 값.
/// [CoursesApi.getRecommendedCourses]가 반환하는 [CoursePlaceResponse]나 커스텀 코스
/// 피커의 [ExplorePlace]를 그대로 저장하지 않고 이 값 객체로 변환한 뒤 코스 확정
/// 시점에만 로컬 DB에 저장한다.
class CourseCandidatePlace {
  const CourseCandidatePlace({
    required this.name,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.visitOrder,
    this.serverPlaceId,
    this.externalPlaceId,
    this.imageUrl,
  });

  /// 좌표(위도/경도)가 없으면 [InvalidCoursePlaceException]을 던진다
  /// ([SelectCourseUseCase]가 이 값을 저장하기 전에 호출됨).
  factory CourseCandidatePlace.fromCoursePlaceResponse(
    CoursePlaceResponse response, {
    required int visitOrder,
  }) {
    final latitude = response.latitude;
    final longitude = response.longitude;
    if (latitude == null || longitude == null) {
      throw InvalidCoursePlaceException(response.title, '좌표 정보 없음');
    }
    _validateCoordinateRange(response.title, latitude, longitude);

    return CourseCandidatePlace(
      serverPlaceId: response.placeId,
      externalPlaceId: response.externalPlaceId,
      name: response.title,
      address: response.address,
      category: response.categoryDetail ?? response.categoryGroup,
      latitude: latitude,
      longitude: longitude,
      visitOrder: visitOrder,
    );
  }

  /// 커스텀 코스 피커(관광지 목록·검색·북마크 통합 모델 [ExplorePlace])에서
  /// 사용자가 고른 장소를 필름롤 스냅샷 입력으로 변환한다. [ExplorePlace]는
  /// 좌표가 항상 있지만(비-nullable), NaN/범위 밖 값은 여전히 방어한다.
  factory CourseCandidatePlace.fromExplorePlace(
    ExplorePlace place, {
    required int visitOrder,
  }) {
    _validateCoordinateRange(place.title, place.latitude, place.longitude);

    return CourseCandidatePlace(
      serverPlaceId: place.serverId,
      externalPlaceId: place.externalPlaceId,
      name: place.title,
      address: place.address,
      category: place.categoryDetailLabel.isNotEmpty
          ? place.categoryDetailLabel
          : place.categoryGroupWire,
      latitude: place.latitude,
      longitude: place.longitude,
      visitOrder: visitOrder,
    );
  }

  /// 좌표(위도/경도)가 유한하지 않거나 유효 범위를 벗어나면
  /// [InvalidCoursePlaceException]을 던진다. 0으로 대체해 저장하면 실제
  /// 좌표(기니만)로 오인될 수 있고, NaN/Infinity나 범위를 벗어난 값도 지도
  /// 표시·거리 계산을 깨뜨릴 수 있어 코스 확정 자체를 막는다.
  static void _validateCoordinateRange(
    String placeName,
    double latitude,
    double longitude,
  ) {
    if (!latitude.isFinite || !longitude.isFinite) {
      throw InvalidCoursePlaceException(
        placeName,
        'latitude=$latitude, longitude=$longitude (유한한 값이 아님)',
      );
    }
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw InvalidCoursePlaceException(
        placeName,
        'latitude=$latitude, longitude=$longitude (허용 범위 밖: '
        'latitude [-90, 90], longitude [-180, 180])',
      );
    }
  }

  final int? serverPlaceId;
  final String? externalPlaceId;
  final String name;
  final String address;
  final String category;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final int visitOrder;
}
