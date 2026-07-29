import 'package:chaerok/data/models/selected_course_place_response.dart';

class SelectedCourseResponse {
  const SelectedCourseResponse({
    required this.courseId,
    required this.regionId,
    required this.title,
    required this.status,
    required this.placeCount,
    required this.completed,
    required this.places,
  });

  factory SelectedCourseResponse.fromJson(Map<String, dynamic> json) {
    return SelectedCourseResponse(
      courseId: json['courseId'] as int,
      regionId: json['regionId'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      placeCount: json['placeCount'] as int,
      completed: json['completed'] as bool,
      places: (json['places'] as List<dynamic>)
          .map(
            (e) =>
                SelectedCoursePlaceResponse.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    );
  }

  factory SelectedCourseResponse.empty() {
    return const SelectedCourseResponse(
      courseId: 0,
      regionId: 0,
      title: '',
      status: '',
      placeCount: 0,
      completed: false,
      places: [],
    );
  }

  final int courseId;
  final int regionId;
  final String title;
  final String status;
  final int placeCount;
  final bool completed;
  final List<SelectedCoursePlaceResponse> places;
}
