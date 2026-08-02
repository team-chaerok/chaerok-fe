/// 필름롤 진행 상태.
enum FilmRollStatus {
  /// 코스 선택/방문/촬영이 진행 중인 상태. 지역당 1개만 존재할 수 있다.
  inProgress,

  /// 코스 선택 + 전체 장소 방문이 완료된 상태. 지역당 여러 개 존재할 수 있다.
  completed,
}
