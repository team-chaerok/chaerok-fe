import 'package:chaerok/data/models/place_category.dart';
import 'package:chaerok/data/models/selected_course_place_response.dart';
import 'package:chaerok/data/models/selected_course_response.dart';
import 'package:chaerok/features/explore/domain/explore_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/course_candidate_place.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/select_custom_course_use_case.dart';
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

ExplorePlace _kakaoPlace({
  required String title,
  required String externalPlaceId,
}) => ExplorePlace(
  title: title,
  address: '충남 어딘가',
  latitude: 36.5,
  longitude: 127.1,
  categoryGroup: PlaceCategoryGroup.cafeDessert,
  categoryGroupWire: 'CAFE_DESSERT',
  categoryDetail: PlaceCategoryDetail.cafe,
  categoryDetailLabel: '카페',
  source: 'KAKAO_LOCAL',
  identityKey: 'external:KAKAO:$externalPlaceId',
  // 코스 생성 요청 전 카카오 장소는 서버 ID가 항상 없다 — 이게 이 버그의 핵심.
  serverId: null,
  externalPlaceId: externalPlaceId,
);

SelectedCoursePlaceResponse _resolvedPlace({
  required int placeId,
  required int sequence,
  String title = '테스트 장소',
}) => SelectedCoursePlaceResponse(
  placeId: placeId,
  source: 'KAKAO_LOCAL',
  title: title,
  categoryGroup: 'CAFE_DESSERT',
  address: '충남 어딘가',
  sequence: sequence,
);

void main() {
  test('createCourse 응답의 resolved placeId를 로컬 serverPlaceId로 저장한다'
      '(요청 전 ExplorePlace.serverId는 null이었음)', () async {
    final repository = _StubFilmRollRepository();
    final useCase = SelectCustomCourseUseCase(repository);

    await useCase.call(
      filmRollId: 'fr-1',
      course: SelectedCourseResponse(
        courseId: 99,
        regionId: 1,
        title: '커스텀 코스',
        status: 'CAPTURING',
        placeCount: 1,
        completed: false,
        places: [_resolvedPlace(placeId: 555, sequence: 0)],
      ),
      places: [_kakaoPlace(title: '카카오 카페', externalPlaceId: 'kakao-1')],
    );

    expect(repository.savedPlaces, hasLength(1));
    expect(repository.savedPlaces!.single.serverPlaceId, 555);
  });

  test('여러 장소도 sequence 기준으로 정확히 매칭해 placeId를 저장한다', () async {
    final repository = _StubFilmRollRepository();
    final useCase = SelectCustomCourseUseCase(repository);

    await useCase.call(
      filmRollId: 'fr-1',
      course: SelectedCourseResponse(
        courseId: 99,
        regionId: 1,
        title: '커스텀 코스',
        status: 'CAPTURING',
        placeCount: 3,
        completed: false,
        // 서버가 요청과 다른 순서로 돌려줘도(방어적으로) sequence로 다시
        // 맞춰야 한다.
        places: [
          _resolvedPlace(placeId: 20, sequence: 1, title: 'B'),
          _resolvedPlace(placeId: 10, sequence: 0, title: 'A'),
          _resolvedPlace(placeId: 30, sequence: 2, title: 'C'),
        ],
      ),
      places: [
        _kakaoPlace(title: 'A', externalPlaceId: 'kakao-a'),
        _kakaoPlace(title: 'B', externalPlaceId: 'kakao-b'),
        _kakaoPlace(title: 'C', externalPlaceId: 'kakao-c'),
      ],
    );

    final saved = repository.savedPlaces!;
    expect(saved.map((p) => p.name), ['A', 'B', 'C']);
    expect(saved.map((p) => p.serverPlaceId), [10, 20, 30]);
    expect(saved.map((p) => p.visitOrder), [0, 1, 2]);
  });

  test('좌표는 여전히 원본 ExplorePlace에서 그대로 가져온다(응답엔 좌표가 없음)', () async {
    final repository = _StubFilmRollRepository();
    final useCase = SelectCustomCourseUseCase(repository);

    await useCase.call(
      filmRollId: 'fr-1',
      course: SelectedCourseResponse(
        courseId: 99,
        regionId: 1,
        title: '커스텀 코스',
        status: 'CAPTURING',
        placeCount: 1,
        completed: false,
        places: [_resolvedPlace(placeId: 555, sequence: 0)],
      ),
      places: [_kakaoPlace(title: '카카오 카페', externalPlaceId: 'kakao-1')],
    );

    final saved = repository.savedPlaces!.single;
    expect(saved.latitude, 36.5);
    expect(saved.longitude, 127.1);
  });
}
