import 'package:chaerok/data/models/course_place_response.dart';
import 'package:chaerok/data/models/course_response.dart';
import 'package:chaerok/features/film_roll/domain/entity/course_candidate_place.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/select_course_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubFilmRollRepository implements FilmRollRepository {
  List<CourseCandidatePlace>? savedPlaces;

  @override
  Future<void> selectCourse({
    required String filmRollId,
    required String courseId,
    required String courseTitle,
    required List<CourseCandidatePlace> places,
  }) async {
    savedPlaces = places;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

CoursePlaceResponse _place({
  int? placeId,
  String? externalPlaceId,
  String title = '테스트 장소',
}) => CoursePlaceResponse(
  placeId: placeId,
  externalPlaceId: externalPlaceId,
  source: 'TOUR_API',
  title: title,
  categoryGroup: 'TOURISM',
  address: '충남 어딘가',
  latitude: 36.5,
  longitude: 127.1,
);

void main() {
  test('서버 DB 장소(placeId 있음)는 placeImageFetcher로 이미지를 보충한다', () async {
    final repository = _StubFilmRollRepository();
    final fetchedIds = <int>[];
    final useCase = SelectCourseUseCase(
      repository,
      placeImageFetcher: (placeId) async {
        fetchedIds.add(placeId);
        return 'https://example.com/$placeId.jpg';
      },
    );

    await useCase.call(
      filmRollId: 'fr-1',
      course: CourseResponse(
        title: '코스',
        score: 1,
        places: [_place(placeId: 42)],
      ),
    );

    expect(fetchedIds, [42]);
    expect(
      repository.savedPlaces!.single.imageUrl,
      'https://example.com/42.jpg',
    );
  });

  test('placeId가 없는(외부 장소) 곳은 fetcher를 호출하지 않고 이미지 없이 저장한다', () async {
    final repository = _StubFilmRollRepository();
    var fetchCount = 0;
    final useCase = SelectCourseUseCase(
      repository,
      placeImageFetcher: (placeId) async {
        fetchCount++;
        return 'https://example.com/$placeId.jpg';
      },
    );

    await useCase.call(
      filmRollId: 'fr-1',
      course: CourseResponse(
        title: '코스',
        score: 1,
        places: [_place(externalPlaceId: 'ext-1')],
      ),
    );

    expect(fetchCount, 0);
    expect(repository.savedPlaces!.single.imageUrl, isNull);
  });

  test('이미지 보충이 실패해도(null 반환) 코스 저장 자체는 계속된다', () async {
    final repository = _StubFilmRollRepository();
    final useCase = SelectCourseUseCase(
      repository,
      placeImageFetcher: (placeId) async => null,
    );

    await useCase.call(
      filmRollId: 'fr-1',
      course: CourseResponse(
        title: '코스',
        score: 1,
        places: [
          _place(placeId: 1),
          _place(placeId: 2, title: '장소2'),
        ],
      ),
    );

    expect(repository.savedPlaces, hasLength(2));
    expect(repository.savedPlaces!.every((p) => p.imageUrl == null), isTrue);
  });

  test('여러 장소를 병렬로 보충하고 순서(visitOrder)는 그대로 유지한다', () async {
    final repository = _StubFilmRollRepository();
    final useCase = SelectCourseUseCase(
      repository,
      placeImageFetcher: (placeId) async => 'img-$placeId',
    );

    await useCase.call(
      filmRollId: 'fr-1',
      course: CourseResponse(
        title: '코스',
        score: 1,
        places: [
          _place(placeId: 10, title: 'A'),
          _place(placeId: 20, title: 'B'),
          _place(placeId: 30, title: 'C'),
        ],
      ),
    );

    final saved = repository.savedPlaces!;
    expect(saved.map((p) => p.name), ['A', 'B', 'C']);
    expect(saved.map((p) => p.visitOrder), [0, 1, 2]);
    expect(saved.map((p) => p.imageUrl), ['img-10', 'img-20', 'img-30']);
  });
}
