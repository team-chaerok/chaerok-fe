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
/// [ExplorePlace]에서 그대로 가져온다. `courseId`만 서버 응답의 실제 값을 쓴다.
/// 이미 방문/사진 기록이 있는 상태에서 다른 코스로 변경하려 하면
/// [CourseChangeBlockedException]을 던진다(안전 기본값 정책, [SelectCourseUseCase]와 동일).
class SelectCustomCourseUseCase {
  const SelectCustomCourseUseCase(this._filmRollRepository);

  final FilmRollRepository _filmRollRepository;

  /// [places]는 [course]를 생성할 때 보낸 것과 같은 순서의 원본 장소 목록이어야
  /// 한다(서버 응답의 `sequence`가 요청 순서와 1:1 대응함을 확인함).
  Future<void> call({
    required String filmRollId,
    required SelectedCourseResponse course,
    required List<ExplorePlace> places,
  }) {
    final candidatePlaces = <CourseCandidatePlace>[
      for (var i = 0; i < places.length; i++)
        CourseCandidatePlace.fromExplorePlace(places[i], visitOrder: i),
    ];

    return _filmRollRepository.selectCourse(
      filmRollId: filmRollId,
      courseId: course.courseId.toString(),
      courseTitle: course.title,
      places: candidatePlaces,
    );
  }
}
