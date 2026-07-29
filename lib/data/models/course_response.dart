import 'package:chaerok/data/models/course_place_response.dart';

class CourseResponse {
  const CourseResponse({
    required this.title,
    required this.score,
    required this.places,
  });

  factory CourseResponse.fromJson(Map<String, dynamic> json) {
    return CourseResponse(
      title: json['title'] as String,
      score: (json['score'] as num).toDouble(),
      places: (json['places'] as List<dynamic>)
          .map((e) => CoursePlaceResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String title;
  final double score;
  final List<CoursePlaceResponse> places;
}
