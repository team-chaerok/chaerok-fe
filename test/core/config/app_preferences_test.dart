import 'package:chaerok/core/config/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('isDebugOutOfServiceArea', () {
    test('저장된 값이 없으면 false를 반환한다', () async {
      expect(await AppPreferences.instance.isDebugOutOfServiceArea(), false);
    });

    test('setDebugOutOfServiceArea(true) 이후 true를 반환한다', () async {
      await AppPreferences.instance.setDebugOutOfServiceArea(true);
      expect(await AppPreferences.instance.isDebugOutOfServiceArea(), true);
    });

    test('다시 false로 되돌릴 수 있다', () async {
      await AppPreferences.instance.setDebugOutOfServiceArea(true);
      await AppPreferences.instance.setDebugOutOfServiceArea(false);
      expect(await AppPreferences.instance.isDebugOutOfServiceArea(), false);
    });
  });
}
