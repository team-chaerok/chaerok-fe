import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/location/location_provider.dart';
import 'package:chaerok/core/location/mock_location_provider.dart';
import 'package:chaerok/core/location/real_location_provider.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/foundation.dart';

/// 현재 설정에 맞는 [LocationProvider]를 생성한다.
/// release 빌드에서는 저장된 mock 설정과 무관하게 항상 [RealLocationProvider]를 반환한다
/// (mock 위치는 개발/QA 전용 기능이며 production에서 강제 비활성화된다).
class LocationProviderFactory {
  const LocationProviderFactory._();

  static Future<LocationProvider> create() async {
    if (kReleaseMode) {
      return const RealLocationProvider();
    }

    final isMockEnabled = await AppPreferences.instance.isMockLocationEnabled();
    if (!isMockEnabled) {
      return const RealLocationProvider();
    }

    final regionCodeName = await AppPreferences.instance
        .getMockRegionCodeName();
    final regionCode = RegionCode.values.firstWhere(
      (region) => region.name == regionCodeName,
      orElse: () => RegionCode.gongju,
    );
    return MockLocationProvider(regionCode);
  }
}
