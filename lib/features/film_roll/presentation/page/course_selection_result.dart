import 'package:chaerok/data/models/course_response.dart';
import 'package:chaerok/data/models/selected_course_response.dart';
import 'package:chaerok/features/explore/domain/explore_place.dart';

/// [CourseSelectionResult]가 담고 있는 코스 종류.
enum CourseSelectionOutcome {
  /// 추천 코스 후보 중 하나를 그대로 선택함.
  recommended,

  /// 직접 만들기 모드에서 장소를 골라 `CoursesApi.createCourse`로 이미 생성함.
  custom,
}

/// `CourseSelectionScreen`이 `Navigator.pop`으로 반환하는 코스 선택 결과.
///
/// 추천/커스텀 두 경로가 서로 다른 서버 응답 타입([CourseResponse]/[SelectedCourseResponse])을
/// 반환해 하나로 합칠 수 없다. 이 프로젝트는 다중 결과를 `sealed class`가 아니라
/// enum + 단일 클래스(private 생성자 + named 생성자) 패턴으로 표현하므로
/// ([ExitFilmRollResult] 참고) 이를 그대로 따른다.
class CourseSelectionResult {
  const CourseSelectionResult._({
    required this.outcome,
    this.recommendedCourse,
    this.customCourse,
    this.customPlaces,
  });

  const CourseSelectionResult.recommended(CourseResponse course)
    : this._(
        outcome: CourseSelectionOutcome.recommended,
        recommendedCourse: course,
      );

  /// [places]는 [course]를 생성할 때 보낸 것과 같은 순서의 원본 장소 목록이다.
  /// `SelectCustomCourseUseCase`가 좌표 복원에 그대로 사용한다.
  const CourseSelectionResult.custom(
    SelectedCourseResponse course,
    List<ExplorePlace> places,
  ) : this._(
        outcome: CourseSelectionOutcome.custom,
        customCourse: course,
        customPlaces: places,
      );

  final CourseSelectionOutcome outcome;

  /// [outcome]이 [CourseSelectionOutcome.recommended]일 때만 값이 있다.
  final CourseResponse? recommendedCourse;

  /// [outcome]이 [CourseSelectionOutcome.custom]일 때만 값이 있다.
  final SelectedCourseResponse? customCourse;

  /// [outcome]이 [CourseSelectionOutcome.custom]일 때만 값이 있다.
  final List<ExplorePlace>? customPlaces;
}
