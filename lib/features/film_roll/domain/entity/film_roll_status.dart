/// 필름롤 진행 상태.
enum FilmRollStatus {
  /// 코스 선택/방문/촬영이 진행 중인 상태. 지역당 1개만 존재할 수 있다.
  inProgress,

  /// 코스 선택 + 전체 장소 방문이 완료된 상태. 지역당 여러 개 존재할 수 있다.
  completed,

  /// 지역 이탈이 확정되고 현상 조건(서로 다른 관광 유형 3개 + 사진 1장 이상)을
  /// 충족해 현상이 예약된 상태(서버 `READY_TO_RENDER`). [FilmRoll.developAvailableAt]
  /// 까지 대기하며, 완료 감지·전환은 이번 범위 밖(후속 이슈).
  developing,

  /// 지역 이탈은 확정됐으나 현상 조건을 충족하지 못해 종료된 상태(서버 `EXPIRED`).
  expired,
}
