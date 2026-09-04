import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/visit_category_progress.dart';
import 'package:flutter_test/flutter_test.dart';

FilmRollPlace _place({
  required String category,
  bool isVisited = true,
  String id = 'place',
}) {
  return FilmRollPlace(
    id: id,
    filmRollId: 'film-roll',
    name: '테스트 장소',
    address: '주소',
    category: category,
    latitude: 0,
    longitude: 0,
    visitOrder: 0,
    isVisited: isVisited,
    photoCount: 0,
  );
}

void main() {
  test('서로 다른 유형(소분류) 3곳을 방문하면 3으로 집계된다', () {
    final places = [
      _place(id: '1', category: 'HERITAGE'),
      _place(id: '2', category: 'RESTAURANT'),
      _place(id: '3', category: 'CAFE'),
    ];

    expect(countDistinctVisitedCategories(places), 3);
    expect(hasMetLocalCategoryRequirement(places), isTrue);
  });

  test('같은 대분류 안의 서로 다른 소분류는 1개로 묶여 센다', () {
    final places = [
      _place(id: '1', category: 'HERITAGE'),
      _place(id: '2', category: 'MUSEUM'),
      _place(id: '3', category: 'WALK'),
    ];

    expect(countDistinctVisitedCategories(places), 1);
    expect(hasMetLocalCategoryRequirement(places), isFalse);
  });

  test('소분류 없이 대분류 문자열만 와도 그룹으로 인식한다', () {
    final places = [
      _place(id: '1', category: 'TOURISM'),
      _place(id: '2', category: 'FOOD'),
      _place(id: '3', category: 'CAFE_DESSERT'),
    ];

    expect(countDistinctVisitedCategories(places), 3);
    expect(hasMetLocalCategoryRequirement(places), isTrue);
  });

  test('방문하지 않은 장소는 유형 집계에서 제외된다', () {
    final places = [
      _place(id: '1', category: 'HERITAGE'),
      _place(id: '2', category: 'RESTAURANT'),
      _place(id: '3', category: 'CAFE', isVisited: false),
    ];

    expect(countDistinctVisitedCategories(places), 2);
    expect(hasMetLocalCategoryRequirement(places), isFalse);
  });

  test('알 수 없는 카테고리 문자열은 집계에 포함되지 않는다', () {
    final places = [
      _place(id: '1', category: 'HERITAGE'),
      _place(id: '2', category: 'RESTAURANT'),
      _place(id: '3', category: '알 수 없는 카테고리'),
    ];

    expect(countDistinctVisitedCategories(places), 2);
    expect(hasMetLocalCategoryRequirement(places), isFalse);
  });

  test('빈 목록이면 0을 반환한다', () {
    expect(countDistinctVisitedCategories(const []), 0);
    expect(hasMetLocalCategoryRequirement(const []), isFalse);
  });
}
