import 'package:chaerok/data/models/course_place_response.dart';
import 'package:chaerok/data/models/course_response.dart';
import 'package:flutter_test/flutter_test.dart';

CoursePlaceResponse _place({
  int? placeId,
  String? externalPlaceId,
  String source = 'TOUR_API',
  String title = '경복궁',
  String address = '서울 종로구',
}) {
  return CoursePlaceResponse(
    placeId: placeId,
    externalPlaceId: externalPlaceId,
    source: source,
    title: title,
    categoryGroup: 'TOURISM',
    address: address,
  );
}

CourseResponse _course(List<CoursePlaceResponse> places) {
  return CourseResponse(title: 'course', score: 1, places: places);
}

void main() {
  test('장소 구성이 같으면 courseId도 동일하다', () {
    final a = _course([_place(placeId: 1), _place(placeId: 2)]);
    final b = _course([_place(placeId: 1), _place(placeId: 2)]);

    expect(a.courseId, b.courseId);
  });

  test('장소 순서가 다르면 courseId도 다르다', () {
    final a = _course([_place(placeId: 1), _place(placeId: 2)]);
    final b = _course([_place(placeId: 2), _place(placeId: 1)]);

    expect(a.courseId, isNot(b.courseId));
  });

  test('식별자에 구분자 문자가 포함된 장소들이 이어붙여져 다른 개수의 장소 목록과 '
      '같은 문자열이 되지 않는다 (join 방식이었다면 충돌 가능)', () {
    // 예전 join('|') 방식이라면 "12|34" (2개 장소, placeId 12, 34)와
    // externalPlaceId가 "12|34"인 단일 장소 목록이 동일한 문자열이 될 수 있었다.
    final twoPlaces = _course([_place(placeId: 12), _place(placeId: 34)]);
    final onePlaceWithSeparatorLikeId = _course([
      _place(externalPlaceId: '12|34'),
    ]);

    expect(twoPlaces.courseId, isNot(onePlaceWithSeparatorLikeId.courseId));
  });

  test('title/address 조합에 구분자 문자가 포함되어도 다른 장소 개수 구성과 충돌하지 않는다', () {
    // 예전 방식이라면 title="A", address="B|C@D" (1개 장소, title+address 대체 식별자)와
    // title="A", address="B" + 별도 장소(title="C", address="D") (2개 장소)가
    // 우연히 같은 결합 문자열을 만들어낼 수 있었다.
    final onePlaceWithComplexAddress = _course([
      _place(
        placeId: null,
        externalPlaceId: null,
        title: 'A',
        address: 'B|C@D',
      ),
    ]);
    final twoSimplePlaces = _course([
      _place(placeId: null, externalPlaceId: null, title: 'A', address: 'B'),
      _place(placeId: null, externalPlaceId: null, title: 'C', address: 'D'),
    ]);

    expect(
      onePlaceWithComplexAddress.courseId,
      isNot(twoSimplePlaces.courseId),
    );
  });

  test('ID 종류(placeId vs externalPlaceId)가 다르면 값이 같아도 다른 장소로 구분된다', () {
    final withPlaceId = _course([_place(placeId: 99)]);
    final withExternalId = _course([
      _place(placeId: null, externalPlaceId: '99'),
    ]);

    expect(withPlaceId.courseId, isNot(withExternalId.courseId));
  });

  test('출처(source)가 다르면 같은 placeId라도 다른 장소로 구분된다', () {
    final tourApi = _course([_place(placeId: 1, source: 'TOUR_API')]);
    final kakao = _course([_place(placeId: 1, source: 'KAKAO')]);

    expect(tourApi.courseId, isNot(kakao.courseId));
  });
}
