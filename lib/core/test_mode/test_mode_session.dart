import 'package:flutter/foundation.dart';

/// Test Mode(비공개 테스트용 위치 판정 우회 + E2E 시나리오)의 진행 상태를 한곳에서
/// 관리하는 세션 싱글턴.
///
/// 이 프로젝트는 별도 상태관리 라이브러리를 쓰지 않으므로 Flutter 기본
/// [ChangeNotifier]로 변경을 통지한다(외부 의존성 없음). `MockLocationGate`,
/// 위치 인증 화면, 진행 모드 뷰가 이 값을 읽어 위치 판정만 테스트용으로 강제한다.
///
/// 값은 앱 재시작 시 초기화된다(영속화는 범위 밖). 정식 빌드에서는 Test Mode
/// 패널 자체가 노출되지 않는 한 어떤 값도 세팅되지 않으므로, 위치 우회 경로는
/// 항상 비활성이다.
class TestModeSession extends ChangeNotifier {
  TestModeSession._();

  static final TestModeSession instance = TestModeSession._();

  bool _gongjuEntered = false;
  bool _gongjuExited = false;
  double? _injectedLatitude;
  double? _injectedLongitude;

  /// "공주 진입"을 강제한 상태. 위치 인증의 시·도/서비스 지역 판정을 공주로
  /// 통과시키고, 진행 모드의 실제 지역 이탈 감지는 무시한다(명시적 "공주 이탈"
  /// 전까지).
  bool get gongjuEntered => _gongjuEntered;

  /// "공주 이탈"을 강제한 상태. 진행 모드가 실제 GPS와 무관하게 지역 이탈로 처리한다.
  bool get gongjuExited => _gongjuExited;

  /// 특정 장소 좌표를 주입 중인지. 방문 인증 시 대상 장소의 실제 좌표를 주입해
  /// 거리/정확도 게이트를 실제 그대로 통과시킨다(게이트 우회 아님).
  bool get isInjecting =>
      _injectedLatitude != null && _injectedLongitude != null;

  double? get injectedLatitude => _injectedLatitude;

  double? get injectedLongitude => _injectedLongitude;

  /// Test Mode가 위치 조회 경로에 개입 중인지. `MockLocationGate.isActive`가
  /// mock 좌표를 써야 하는지 판단하는 데 쓴다.
  bool get overridesLocation => _gongjuEntered || _gongjuExited || isInjecting;

  void enterGongju() {
    _gongjuEntered = true;
    _gongjuExited = false;
    notifyListeners();
  }

  void exitGongju() {
    _gongjuExited = true;
    notifyListeners();
  }

  void injectPlace({required double latitude, required double longitude}) {
    _injectedLatitude = latitude;
    _injectedLongitude = longitude;
    notifyListeners();
  }

  void clearInjection() {
    _injectedLatitude = null;
    _injectedLongitude = null;
    notifyListeners();
  }

  /// 진입/방문/이탈 강제값을 모두 되돌린다(처음부터 다시 시작).
  void reset() {
    _gongjuEntered = false;
    _gongjuExited = false;
    _injectedLatitude = null;
    _injectedLongitude = null;
    notifyListeners();
  }
}
