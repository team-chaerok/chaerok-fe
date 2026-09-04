import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter_test/flutter_test.dart';

FilmRoll _filmRoll({
  String? selectedCourseId = 'course-1',
  bool? visitRequirementMet,
}) {
  final now = DateTime(2026, 1, 1);
  return FilmRoll(
    id: 'film-roll',
    regionCode: RegionCode.gongju,
    regionName: '공주시',
    title: '테스트 필름롤',
    status: FilmRollStatus.inProgress,
    selectedCourseId: selectedCourseId,
    totalPlaceCount: 3,
    visitedPlaceCount: 3,
    createdAt: now,
    updatedAt: now,
    visitRequirementMet: visitRequirementMet,
  );
}

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

final _threeDistinctTypesVisited = [
  _place(id: '1', category: 'HERITAGE'),
  _place(id: '2', category: 'RESTAURANT'),
  _place(id: '3', category: 'CAFE'),
];

final _onlyOneTypeVisited = [
  _place(id: '1', category: 'HERITAGE'),
  _place(id: '2', category: 'MUSEUM'),
];

void main() {
  test('코스를 선택하지 않았으면 다른 조건과 무관하게 완료할 수 없다', () {
    final filmRoll = _filmRoll(
      selectedCourseId: null,
      visitRequirementMet: true,
    );

    expect(filmRoll.isCompletable(_threeDistinctTypesVisited), isFalse);
  });

  test('서버가 조건 충족을 알려주면 로컬 방문 기록과 무관하게 완료 가능하다', () {
    final filmRoll = _filmRoll(visitRequirementMet: true);

    expect(filmRoll.isCompletable(_onlyOneTypeVisited), isTrue);
  });

  test('서버가 조건 미충족을 알려주면 로컬에 3유형이 있어도 완료할 수 없다', () {
    final filmRoll = _filmRoll(visitRequirementMet: false);

    expect(filmRoll.isCompletable(_threeDistinctTypesVisited), isFalse);
  });

  test('서버 값이 없으면(미동기화) 로컬 방문 기록으로 판정한다 — 3유형 충족', () {
    final filmRoll = _filmRoll(visitRequirementMet: null);

    expect(filmRoll.isCompletable(_threeDistinctTypesVisited), isTrue);
  });

  test('서버 값이 없으면(미동기화) 로컬 방문 기록으로 판정한다 — 미충족', () {
    final filmRoll = _filmRoll(visitRequirementMet: null);

    expect(filmRoll.isCompletable(_onlyOneTypeVisited), isFalse);
  });
}
