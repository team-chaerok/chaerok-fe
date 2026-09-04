import 'package:chaerok/core/location/location_provider.dart';
import 'package:chaerok/core/location/mock_location_gate.dart';
import 'package:chaerok/core/location/mock_location_provider.dart';
import 'package:chaerok/core/location/real_location_provider.dart';

/// 현재 설정에 맞는 [LocationProvider]를 생성한다.
/// mock 위치 허용 여부(빌드 모드 + 테스트 계정)와 사용자 on/off는
/// [MockLocationGate]가 판정하며, release 일반 사용자는 항상
/// [RealLocationProvider]를 받는다.
class LocationProviderFactory {
  const LocationProviderFactory._();

  static Future<LocationProvider> create() async {
    if (await MockLocationGate.isActive()) {
      return const MockLocationProvider();
    }
    return const RealLocationProvider();
  }
}
