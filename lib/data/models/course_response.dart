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

  /// 코스 후보의 안정적인 로컬 식별자. 추천 API는 후보별 id를 내려주지 않고
  /// title은 서로 다른 후보끼리 우연히 겹칠 수 있으므로, 장소 구성(순서 포함)을
  /// 결합해 만든다. 코스 변경 차단(CourseChangeBlockedException) 판단에 쓰인다.
  String get courseId => places.map((place) => place.identity).join('|');
}
