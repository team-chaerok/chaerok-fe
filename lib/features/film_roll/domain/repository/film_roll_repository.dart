import 'package:chaerok/features/film_roll/domain/entity/course_candidate_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/shared/region/region_code.dart';

/// 필름롤(FilmRoll) 애그리게잇을 관리하는 리포지토리.
abstract class FilmRollRepository {
  /// 해당 지역의 진행중(inProgress) 필름롤을 찾아 반환하고, 없으면 새로 생성한다.
  /// 지역당 진행중 필름롤은 1개만 존재해야 하며, 이 연산은 원자적으로 처리된다.
  Future<FilmRoll> findOrCreateActiveByRegion({
    required RegionCode regionCode,
    required String regionName,
  });

  Future<FilmRoll?> findById(String filmRollId);

  /// 진행중/완료 구분 없이 모든 필름롤을 최신순으로 반환한다(필름 컬렉션 화면용).
  Future<List<FilmRoll>> findAll();

  /// [filmRollId]의 변경 사항을 구독한다. 삭제되면 null을 발행한다.
  Stream<FilmRoll?> watchById(String filmRollId);

  /// 추천 코스 후보를 확정해 필름롤에 스냅샷으로 저장한다.
  /// [courseId]는 후보를 식별하는 안정적인 로컬 식별자([CourseResponse.courseId])로,
  /// 서로 다른 후보가 우연히 같은 [courseTitle]을 가지더라도 다른 코스로
  /// 인식되도록 한다. 이미 방문/사진 기록이 있는 상태에서 기존과 다른
  /// [courseId]로 변경하려 하면 [CourseChangeBlockedException]을 던진다
  /// (안전 기본값 정책).
  ///
  /// 충돌 없는 식별자 계약: [courseId]는 서로 다른 장소 구성(장소 개수,
  /// 순서, 각 장소의 ID 종류/출처/값 중 하나라도)에 대해 항상 서로 다른
  /// 문자열이어야 한다. 이 계약이 깨지면 실제로는 다른 코스인데 같은
  /// 코스로 오인되어 변경 차단이 누락될 수 있다. 구현은
  /// [CourseResponse.courseId]/[CoursePlaceResponse.identityParts]를 참고.
  Future<void> selectCourse({
    required String filmRollId,
    required String courseId,
    required String courseTitle,
    required List<CourseCandidatePlace> places,
  });

  /// 완료 조건(코스 선택 + 전체 장소 방문)을 검증하고 필름롤을 완료 처리한다.
  /// 조건을 충족하지 못하면 [FilmRollNotCompletableException]을 던진다.
  Future<void> completeFilmRoll(String filmRollId);

  /// 필름롤과 연관된 장소/사진 레코드(DB) 및 사진 원본 파일을 함께 삭제한다.
  Future<void> deleteFilmRoll(String filmRollId);

  /// 계정 스코프 도입 이전에 생성돼 계정이 비어있는 레거시 필름롤을
  /// [userId] 소유로 1회 확정한다. 이미 계정이 확정된 행은 건드리지 않는다.
  Future<void> claimLegacyData(int userId);
}
