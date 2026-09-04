import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/location/mock_location_gate.dart';
import 'package:chaerok/core/location/mock_location_spots.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('isAllowed', () {
    test('디버그/프로파일 빌드(테스트 환경)에서는 테스터가 아니어도 허용한다', () async {
      // 테스트는 kReleaseMode == false 이므로 항상 허용된다.
      expect(await MockLocationGate.isAllowed(), true);
    });
  });

  group('isActive', () {
    test('Mock 사용이 꺼져 있으면 비활성', () async {
      expect(await MockLocationGate.isActive(), false);
    });

    test('허용 상태 + Mock 사용이 켜져 있으면 활성', () async {
      await AppPreferences.instance.setMockLocationEnabled(true);
      expect(await MockLocationGate.isActive(), true);
    });
  });

  group('currentMockPosition', () {
    test('저장된 지역/지점의 좌표와 현실적인 정확도를 반환한다', () async {
      await AppPreferences.instance.setMockRegionCodeName(
        RegionCode.buyeo.name,
      );
      await AppPreferences.instance.setMockSpotIndex(2);

      final position = await MockLocationGate.currentMockPosition();
      final expected = mockLocationSpots[RegionCode.buyeo]![2];

      expect(position.latitude, expected.latitude);
      expect(position.longitude, expected.longitude);
      expect(position.accuracy, kMockGpsAccuracyMeters);
      expect(position.isMocked, true);
    });

    test('저장된 지점 인덱스가 지역 지점 수를 벗어나면 마지막 지점으로 clamp 한다', () async {
      await AppPreferences.instance.setMockRegionCodeName(
        RegionCode.gongju.name,
      );
      await AppPreferences.instance.setMockSpotIndex(999);

      final position = await MockLocationGate.currentMockPosition();
      final lastSpot = mockLocationSpots[RegionCode.gongju]!.last;

      expect(position.latitude, lastSpot.latitude);
      expect(position.longitude, lastSpot.longitude);
    });

    test('저장된 지역이 없으면 공주 첫 지점을 반환한다', () async {
      final position = await MockLocationGate.currentMockPosition();
      final firstSpot = mockLocationSpots[RegionCode.gongju]!.first;

      expect(position.latitude, firstSpot.latitude);
      expect(position.longitude, firstSpot.longitude);
    });
  });
}
