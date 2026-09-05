/// 빌드 시 주입되는 컴파일 타임 플래그 모음.
///
/// 비공개 테스트(closed testing) 빌드에서만 `--dart-define-from-file=config/testers.json`
/// 로 `CHAEROK_TEST_MODE=true`를 주입한다. 정식 빌드에는 주입하지 않으므로
/// [isTestMode]는 `false` 상수가 되고, 이 값을 최상단 조건으로 쓰는 Test Mode
/// 코드 경로는 컴파일러가 제거한다.
///
/// 단, Test Mode 패널은 정식 빌드에서도 서버 테스트 계정(`isTester`)에는 노출된다
/// (기존 Play 심사용 Mock 위치 흐름 유지). 실제 위치 우회의 신뢰 경계는 이 플래그가
/// 아니라 `MockLocationGate.isAllowed()`(= `!kReleaseMode || isTester()`)다.
class AppFlavor {
  const AppFlavor._();

  /// 비공개 테스트 빌드 여부.
  static const bool isTestMode = bool.fromEnvironment(
    'CHAEROK_TEST_MODE',
    defaultValue: false,
  );
}
