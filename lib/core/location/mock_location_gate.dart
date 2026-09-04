import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/location/mock_location_spots.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// mock 위치를 실제 GPS 대신 쓸 수 있는지, 실제로 써야 하는지, 그리고 어떤
/// 좌표를 반환할지를 한곳에서 판정한다. `LocationProviderFactory`와
/// `LocationPermissionService`가 이 게이트를 공유해 두 경로의 동작을 일치시킨다.
class MockLocationGate {
  const MockLocationGate._();

  /// 이 빌드/계정이 mock 위치를 쓸 수 있는가.
  /// - 디버그/프로파일 빌드: 항상 허용(개발·QA 편의).
  /// - release 빌드: 서버가 내려준 테스트 계정 플래그(`isTester`)가 있을 때만 허용.
  ///   Play 심사(테스트 계정)에서 실제 이동 없이 인증 흐름을 재현하기 위한 것으로,
  ///   일반 사용자는 release에서 항상 실제 GPS를 쓴다.
  static Future<bool> isAllowed() async {
    if (!kReleaseMode) return true;
    return AppPreferences.instance.isTester();
  }

  /// 실제로 mock 좌표를 반환해야 하는가(허용된 상태에서 사용자가 mock을 켰는지).
  static Future<bool> isActive() async {
    if (!await isAllowed()) return false;
    return AppPreferences.instance.isMockLocationEnabled();
  }

  /// 현재 선택된 지역/지점의 mock [Position].
  /// 방문 인증 게이트를 실제처럼 통과시키기 위해 `accuracy`는 0이 아니라
  /// [kMockGpsAccuracyMeters]를 쓴다.
  static Future<Position> currentMockPosition() async {
    final preferences = AppPreferences.instance;
    final regionCodeName = await preferences.getMockRegionCodeName();
    final region = RegionCode.values.firstWhere(
      (value) => value.name == regionCodeName,
      orElse: () => RegionCode.gongju,
    );
    final spots =
        mockLocationSpots[region] ?? mockLocationSpots[RegionCode.gongju]!;
    final storedIndex = await preferences.getMockSpotIndex();
    final index = storedIndex.clamp(0, spots.length - 1);
    final spot = spots[index];

    return Position(
      latitude: spot.latitude,
      longitude: spot.longitude,
      timestamp: DateTime.now(),
      accuracy: kMockGpsAccuracyMeters,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
      isMocked: true,
    );
  }
}
