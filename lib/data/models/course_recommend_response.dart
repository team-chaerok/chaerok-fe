import 'package:chaerok/data/models/course_response.dart';

class CourseRecommendResponse {
  const CourseRecommendResponse({
    required this.regionId,
    required this.recommendationType,
    required this.anchorPlaceId,
    required this.courses,
  });

  factory CourseRecommendResponse.fromJson(Map<String, dynamic> json) {
    return CourseRecommendResponse(
      regionId: json['regionId'] as int,
      recommendationType: json['recommendationType'] as String,
      anchorPlaceId: json['anchorPlaceId'] as int,
      courses: (json['courses'] as List<dynamic>)
          .map((e) => CourseResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory CourseRecommendResponse.empty() {
    return const CourseRecommendResponse(
      regionId: 0,
      recommendationType: '',
      anchorPlaceId: 0,
      courses: [],
    );
  }

  final int regionId;
  final String recommendationType;
  final int anchorPlaceId;
  final List<CourseResponse> courses;
}
