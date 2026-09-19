/// [FilmRollSyncService.syncFilmRoll]의 실행 요약.
/// best-effort 동기화이므로 예외 대신 이 값으로 결과를 전달한다.
class FilmRollSyncResult {
  const FilmRollSyncResult({
    this.created = false,
    this.photosPushed = 0,
    this.photosSkipped = 0,
    this.visitsPushed = 0,
    this.visitsSkipped = 0,
    this.serverStatus,
    this.error,
    this.blockedByOtherActiveFilmRoll = false,
  });

  /// 이번 호출에서 서버 필름롤을 새로 생성(또는 멱등 조회로 연결)했는지 여부.
  final bool created;

  /// 이번 호출에서 S3로 새로 업로드된(또는 이미 업로드된 것으로 복구된) 사진 수.
  final int photosPushed;

  /// 업로드하지 못하고 건너뛴 사진 수(S3 미설정 환경 등).
  final int photosSkipped;

  /// 이번 호출에서 서버로 새로 전송된 방문 수(중복 응답으로 동기화 처리된 것 포함).
  final int visitsPushed;

  /// `serverPlaceId` 또는 업로드된 사진이 없어 서버로 보내지 못한 방문 수.
  final int visitsSkipped;

  /// 미러링된 서버 필름롤 status. 조회 실패 시 null.
  final String? serverStatus;

  /// 부분 실패를 유발한 오류(있으면). 네트워크/서버 오류는 여기에 담기고
  /// 예외로 던져지지 않는다.
  final Object? error;

  /// 이 계정에 이탈 처리되지 않은 *다른* 활성 필름롤(clientFilmRollId가 다름)이
  /// 서버에 이미 있어 생성/연결이 막혔는지 여부. [hasError]와 달리 재시도로
  /// 해결되지 않는 영구적인 상태다(그 필름롤이 서버에서 이탈 처리되기 전까지).
  final bool blockedByOtherActiveFilmRoll;

  bool get hasError => error != null;
}
