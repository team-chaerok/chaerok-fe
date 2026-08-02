import 'dart:convert';

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
  ///
  /// 장소별 식별자([CoursePlaceResponse.identityParts])를 문자열로 단순
  /// join하면 한 장소의 식별자에 구분자와 같은 문자가 들어있거나 장소 개수가
  /// 다른 두 구성이 같은 문자열로 합쳐질 수 있다(충돌). 이를 막기 위해 각
  /// 장소의 식별자 구성 요소를 그대로 중첩 배열로 두고 JSON으로 인코딩해,
  /// 서로 다른 장소 구성이 항상 서로 다른 courseId를 갖도록(충돌 없는 표현)
  /// 보장한다.
  String get courseId =>
      jsonEncode(places.map((place) => place.identityParts).toList());
}
