import 'package:chaerok/data/models/course_place_save_request.dart';

class CourseAddPlacesRequest {
  const CourseAddPlacesRequest({required this.places});

  final List<CoursePlaceSaveRequest> places;

  Map<String, dynamic> toJson() => {
    'places': places.map((e) => e.toJson()).toList(),
  };
}
