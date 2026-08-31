import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';

/// 필름롤에 속한 장소(FilmRollPlace) 조회 및 방문 처리를 담당하는 리포지토리.
abstract class FilmRollPlaceRepository {
  Future<List<FilmRollPlace>> findByFilmRoll(String filmRollId);

  Future<FilmRollPlace?> findById(String filmRollPlaceId);

  /// 방문 인증을 기록한다. 이미 방문 처리된 장소라면 아무 것도 하지 않는다(중복 방지).
  Future<void> markVisited(String filmRollPlaceId);

  /// 해당 필름롤에 방문 기록 또는 사진이 하나라도 있는지 여부.
  /// 코스 변경 차단 정책(방문/사진 기록이 있으면 변경 차단) 판단에 사용된다.
  Future<bool> hasAnyVisitedOrPhoto(String filmRollId);

  /// 방문 처리(`isVisited`)됐지만 아직 서버에 전송되지 않은(`visitSyncedAt == null`)
  /// 장소 목록. 필름롤 동기화 시 서버로 보낼 방문을 고르는 데 쓴다.
  Future<List<FilmRollPlace>> findUnsyncedVisitedPlaces(String filmRollId);

  /// 방문이 서버에 반영됐음을 기록한다.
  Future<void> markVisitSynced(String filmRollPlaceId, {required DateTime at});
}
