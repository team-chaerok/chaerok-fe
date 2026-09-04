import 'package:chaerok/core/location/location_provider.dart';
import 'package:chaerok/core/location/mock_location_gate.dart';
import 'package:geolocator/geolocator.dart';

/// 개발/QA 전용 mock 좌표를 반환하는 [LocationProvider] 구현체.
/// release 빌드에서는 `LocationProviderFactory`가 테스트 계정이 아닌 한 이
/// 구현체를 선택하지 않는다. 실제 좌표/정확도는 [MockLocationGate]가
/// 저장된 지역·지점 설정을 기준으로 계산한다.
class MockLocationProvider implements LocationProvider {
  const MockLocationProvider();

  @override
  Future<Position?> getCurrentPosition() {
    return MockLocationGate.currentMockPosition();
  }
}
