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

  group('setMockRegionCodeName', () {
    test('문자열을 저장하고 그대로 반환한다', () async {
      await AppPreferences.instance.setMockRegionCodeName('buyeo');
      expect(await AppPreferences.instance.getMockRegionCodeName(), 'buyeo');
    });

    test('null을 넘기면 저장 값을 지운다', () async {
      await AppPreferences.instance.setMockRegionCodeName('buyeo');
      await AppPreferences.instance.setMockRegionCodeName(null);
      expect(await AppPreferences.instance.getMockRegionCodeName(), isNull);
    });
  });

  group('mock 임의 좌표', () {
    test('저장된 값이 없으면 비활성이고 좌표는 null이다', () async {
      expect(await AppPreferences.instance.isMockCustomLocation(), false);
      expect(await AppPreferences.instance.getMockCustomLatitude(), isNull);
      expect(await AppPreferences.instance.getMockCustomLongitude(), isNull);
    });

    test('enabled=true + 좌표를 저장하면 그대로 반환한다', () async {
      await AppPreferences.instance.setMockCustomLocation(
        enabled: true,
        latitude: 37.5547,
        longitude: 126.9707,
      );

      expect(await AppPreferences.instance.isMockCustomLocation(), true);
      expect(await AppPreferences.instance.getMockCustomLatitude(), 37.5547);
      expect(await AppPreferences.instance.getMockCustomLongitude(), 126.9707);
    });

    test('enabled=false를 넘기면 좌표까지 함께 지운다', () async {
      await AppPreferences.instance.setMockCustomLocation(
        enabled: true,
        latitude: 37.5547,
        longitude: 126.9707,
      );
      await AppPreferences.instance.setMockCustomLocation(enabled: false);

      expect(await AppPreferences.instance.isMockCustomLocation(), false);
      expect(await AppPreferences.instance.getMockCustomLatitude(), isNull);
      expect(await AppPreferences.instance.getMockCustomLongitude(), isNull);
    });

    test('enabled=true지만 좌표가 없으면 비활성으로 저장한다', () async {
      await AppPreferences.instance.setMockCustomLocation(enabled: true);

      expect(await AppPreferences.instance.isMockCustomLocation(), false);
    });
  });
}
