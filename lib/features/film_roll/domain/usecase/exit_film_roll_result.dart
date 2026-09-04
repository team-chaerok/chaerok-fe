/// [ExitFilmRollUseCase]가 반환하는 지역 이탈 확정 결과.
enum ExitOutcome {
  /// 현상 조건을 충족해 현상이 예약됨(서버 `READY_TO_RENDER`).
  developing,

  /// 현상 조건을 충족하지 못해 종료됨(서버 `EXPIRED`).
  expired,
}

/// [ExitFilmRollUseCase.call]의 실행 결과.
class ExitFilmRollResult {
  const ExitFilmRollResult._({required this.outcome, this.developAvailableAt});

  const ExitFilmRollResult.developing(DateTime developAvailableAt)
    : this._(
        outcome: ExitOutcome.developing,
        developAvailableAt: developAvailableAt,
      );

  const ExitFilmRollResult.expired() : this._(outcome: ExitOutcome.expired);

  final ExitOutcome outcome;

  /// [outcome]이 [ExitOutcome.developing]일 때만 값이 있다.
  final DateTime? developAvailableAt;

  bool get isDeveloping => outcome == ExitOutcome.developing;
}
