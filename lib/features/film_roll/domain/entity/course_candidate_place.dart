import 'package:chaerok/data/models/course_place_response.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';

/// 추천 코스 후보에 포함된 장소 하나를 필름롤 스냅샷으로 저장하기 위한 입력 값.
/// [CoursesApi.getRecommendedCourses]가 반환하는 [CoursePlaceResponse]를 그대로 저장하지 않고
/// 이 값 객체로 변환한 뒤 코스 확정 시점에만 로컬 DB에 저장한다.
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

  /// 좌표(위도/경도)가 없는 장소는 [InvalidCoursePlaceException]을 던진다.
  /// 0으로 대체해 저장하면 실제 좌표(기니만)로 오인될 수 있어 코스 확정
  /// 자체를 막는다([SelectCourseUseCase]가 이 값을 저장하기 전에 호출됨).
  factory CourseCandidatePlace.fromCoursePlaceResponse(
    CoursePlaceResponse response, {
    required int visitOrder,
  }) {
    final latitude = response.latitude;
    final longitude = response.longitude;
    if (latitude == null || longitude == null) {
      throw InvalidCoursePlaceException(response.title);
    }

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
