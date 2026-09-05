import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/location/location_provider_factory.dart';
import 'package:chaerok/core/location/mock_location_provider.dart';
import 'package:chaerok/core/location/real_location_provider.dart';
import 'package:chaerok/core/test_mode/test_mode_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(TestModeSession.instance.reset);

  test('Mock이 비활성이면 RealLocationProvider를 반환한다', () async {
    final provider = await LocationProviderFactory.create();

    expect(provider, isA<RealLocationProvider>());
  });

  test('Mock이 활성(허용 + 사용 on)이면 MockLocationProvider를 반환한다', () async {
    await AppPreferences.instance.setMockLocationEnabled(true);

    final provider = await LocationProviderFactory.create();

    expect(provider, isA<MockLocationProvider>());
  });

  test('Test Mode가 좌표 주입 중이면 MockLocationProvider를 반환한다', () async {
    TestModeSession.instance.injectPlace(latitude: 36.5, longitude: 127.1);

    final provider = await LocationProviderFactory.create();

    expect(provider, isA<MockLocationProvider>());
  });
}
