import 'package:chaerok/core/config/app_flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CHAEROK_TEST_MODE 를 주입하지 않으면 isTestMode 는 false', () {
    // 테스트/정식 빌드에는 --dart-define=CHAEROK_TEST_MODE 가 없으므로 기본값이다.
    expect(AppFlavor.isTestMode, false);
  });
}
