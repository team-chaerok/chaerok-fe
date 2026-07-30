import 'package:chaerok/data/models/course_response.dart';
import 'package:chaerok/features/film_roll/domain/entity/course_candidate_place.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';

/// 추천 코스 후보([CourseResponse])를 확정해 필름롤에 스냅샷으로 저장한다.
/// 이미 방문/사진 기록이 있는 상태에서 다른 코스로 변경하려 하면
/// [CourseChangeBlockedException]을 던진다(안전 기본값 정책).
class SelectCourseUseCase {
  const SelectCourseUseCase(this._filmRollRepository);

  final FilmRollRepository _filmRollRepository;

  Future<void> call({
    required String filmRollId,
    required CourseResponse course,
  }) {
    final places = <CourseCandidatePlace>[];
    for (var i = 0; i < course.places.length; i++) {
      places.add(
        CourseCandidatePlace.fromCoursePlaceResponse(
          course.places[i],
          visitOrder: i,
        ),
      );
    }

    return _filmRollRepository.selectCourse(
      filmRollId: filmRollId,
      courseTitle: course.title,
      places: places,
    );
  }
}
