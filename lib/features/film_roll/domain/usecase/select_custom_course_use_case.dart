import 'package:chaerok/data/models/selected_course_response.dart';
import 'package:chaerok/features/explore/domain/explore_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/course_candidate_place.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';

/// 커스텀 코스 피커([CourseSelectionScreen])에서 이미 `CoursesApi.createCourse`로
/// 생성된 [SelectedCourseResponse]를 필름롤에 스냅샷으로 확정한다.
/// [SelectCourseUseCase]가 추천 코스([CourseResponse])를 확정하는 것과 대칭 구조다
/// (코스 생성 API 호출은 화면이 이미 끝냈고, 여기서는 로컬 확정만 담당).
///
/// `createCourse` 응답(`SelectedCoursePlaceResponse`)에는 위도/경도가 없어
/// ([analyze] 참고), 로컬 DB 저장에 필요한 좌표는 사용자가 고른 원본
/// [ExplorePlace]에서 그대로 가져온다. 다만 `placeId`는 서버 응답 값을
/// 반드시 써야 한다 — 카카오 장소는 저장 요청 *전*엔 서버 ID가 없고,
/// `createCourse`가 그 자리에서 장소를 찾거나 만들어 실제 placeId를
/// 응답에 담아 돌려주기 때문이다(요청 전 [ExplorePlace.serverId]는 항상
/// null). 이 값을 무시하면 서버엔 place row가 있는데 로컬만 영원히
/// `serverPlaceId=null`로 남아 방문 인증이 서버에 동기화되지 않는다.
/// 이미 방문/사진 기록이 있는 상태에서 다른 코스로 변경하려 하면
/// [CourseChangeBlockedException]을 던진다(안전 기본값 정책, [SelectCourseUseCase]와 동일).
class SelectCustomCourseUseCase {
  const SelectCustomCourseUseCase(this._filmRollRepository);

  final FilmRollRepository _filmRollRepository;

  /// [places]는 [course]를 생성할 때 보낸 것과 같은 순서의 원본 장소 목록이어야
  /// 한다(서버 응답의 `sequence`가 요청 순서와 1:1 대응함을 확인함). 혹시라도
  /// 응답 순서가 요청과 다르게 와도 안전하도록 `sequence`로 다시 정렬해 맞춘다.
  Future<void> call({
    required String filmRollId,
    required SelectedCourseResponse course,
    required List<ExplorePlace> places,
  }) {
    final resolvedPlaces = [...course.places]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));

    // sequence로 index-정렬해 매칭하는 건 응답 장소 수가 요청 장소 수와
    // 정확히 같고, sequence 값이 서로 겹치지 않아 정렬 순서가 명확할 때만
    // 안전하다. 둘 중 하나라도 어긋나면 어떤 응답 장소가 어떤 요청 장소에
    // 대응하는지 확신할 수 없으므로 — 잘못된 placeId를 엉뚱한 장소에 붙이는
    // 대신, 아예 매칭하지 않고 기존처럼 서버 미확보(null)로 둔다.
    final isFullyResolved =
        resolvedPlaces.length == places.length &&
        resolvedPlaces.map((p) => p.sequence).toSet().length ==
            resolvedPlaces.length;

    final candidatePlaces = <CourseCandidatePlace>[
      for (var i = 0; i < places.length; i++)
        CourseCandidatePlace.fromExplorePlace(
          places[i],
          visitOrder: i,
          resolvedServerPlaceId: isFullyResolved
              ? resolvedPlaces[i].placeId
              : null,
        ),
    ];

    return _filmRollRepository.selectCourse(
      filmRollId: filmRollId,
      courseId: course.courseId.toString(),
      courseTitle: course.title,
      places: candidatePlaces,
    );
  }
}
