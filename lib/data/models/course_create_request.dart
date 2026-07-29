import 'package:chaerok/data/models/course_place_save_request.dart';

class CourseCreateRequest {
  const CourseCreateRequest({
    required this.regionId,
    required this.title,
    required this.places,
  });

  final int regionId;
  final String title;
  final List<CoursePlaceSaveRequest> places;

  Map<String, dynamic> toJson() => {
    'regionId': regionId,
    'title': title,
    'places': places.map((e) => e.toJson()).toList(),
  };
}
