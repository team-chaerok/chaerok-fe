import 'package:chaerok/core/test_mode/test_mode_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final session = TestModeSession.instance;

  tearDown(session.reset);

  test('기본 상태는 전부 비활성', () {
    expect(session.gongjuEntered, false);
    expect(session.gongjuExited, false);
    expect(session.isInjecting, false);
    expect(session.overridesLocation, false);
  });

  test('enterGongju 는 진입을 켜고 이탈을 끈다', () {
    session.exitGongju();
    session.enterGongju();

    expect(session.gongjuEntered, true);
    expect(session.gongjuExited, false);
    expect(session.overridesLocation, true);
  });

  test('injectPlace 는 좌표를 노출하고 clearInjection 이 되돌린다', () {
    session.injectPlace(latitude: 36.1, longitude: 127.2);

    expect(session.isInjecting, true);
    expect(session.injectedLatitude, 36.1);
    expect(session.injectedLongitude, 127.2);
    expect(session.overridesLocation, true);

    session.clearInjection();

    expect(session.isInjecting, false);
    expect(session.injectedLatitude, isNull);
  });

  test('reset 은 모든 강제값을 되돌린다', () {
    session
      ..enterGongju()
      ..exitGongju()
      ..injectPlace(latitude: 1, longitude: 2);

    session.reset();

    expect(session.gongjuEntered, false);
    expect(session.gongjuExited, false);
    expect(session.isInjecting, false);
    expect(session.overridesLocation, false);
  });

  test('상태 변경 시 리스너에 통지한다', () {
    var notified = 0;
    void listener() => notified++;
    session.addListener(listener);
    addTearDown(() => session.removeListener(listener));

    session.enterGongju();
    session.injectPlace(latitude: 1, longitude: 2);
    session.reset();

    expect(notified, 3);
  });
}
