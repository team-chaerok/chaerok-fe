import 'package:chaerok/core/network/dio_client.dart';
import 'package:chaerok/data/models/course_add_places_request.dart';
import 'package:chaerok/data/models/course_create_request.dart';
import 'package:chaerok/data/models/course_recommend_response.dart';
import 'package:chaerok/data/models/selected_course_response.dart';

/// CoursesApi 클래스는 코스(Course) 리소스 관련 API 호출을 제공합니다.
class CoursesApi {
  const CoursesApi._();

  /// [사용자 선택 코스 생성] API 호출
  /// 사용자가 선택한 장소 1~3개로 ACTIVE 코스를 생성한다. 기존 ACTIVE 코스가 있으면 INACTIVE 처리하고 새 ACTIVE 코스를 생성한다.
  static Future<SelectedCourseResponse> createCourse(
    CourseCreateRequest request,
  ) async {
    final response = await DioClient.instance.post<SelectedCourseResponse>(
      '/api/courses',
      data: request.toJson(),
      fromJson: (data) =>
          SelectedCourseResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? SelectedCourseResponse.empty();
  }

  /// [ACTIVE 코스 장소 추가] API 호출
  /// 로그인 사용자의 ACTIVE 코스에 장소를 추가한다. ACTIVE 코스는 최대 3개 장소까지만 저장할 수 있다.
  static Future<SelectedCourseResponse> addActiveCoursePlaces(
    CourseAddPlacesRequest request,
  ) async {
    final response = await DioClient.instance.post<SelectedCourseResponse>(
      '/api/courses/active/places',
      data: request.toJson(),
      fromJson: (data) =>
          SelectedCourseResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? SelectedCourseResponse.empty();
  }

  /// [추천 코스 후보 조회] API 호출
  /// regionId 또는 anchorPlaceId를 기준으로 대표 장소 Anchor와 Kakao Local 음식점·카페 후보를 조합한 추천 코스 후보를 조회한다. 사용자 원본 좌표는 전달받지 않는다.
  static Future<CourseRecommendResponse> getRecommendedCourses(
    int regionId,
  ) async {
    final response = await DioClient.instance.get<CourseRecommendResponse>(
      '/api/courses/recommend',
      queryParameters: {'regionId': regionId},
      fromJson: (data) =>
          CourseRecommendResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? CourseRecommendResponse.empty();
  }

  /// [ACTIVE 코스 조회] API 호출
  /// 로그인 사용자의 현재 ACTIVE 코스를 조회한다.
  static Future<SelectedCourseResponse> getActiveCourse() async {
    final response = await DioClient.instance.get<SelectedCourseResponse>(
      '/api/courses/active',
      fromJson: (data) =>
          SelectedCourseResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? SelectedCourseResponse.empty();
  }
}
