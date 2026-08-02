import 'package:chaerok/core/location/location_provider.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:geolocator/geolocator.dart';

/// 지역별 대표 좌표(시청/군청 인근). 개발 중 실제 이동 없이 각 지역 필름롤
/// 흐름을 검증하기 위한 근사값이며 정밀한 위치가 아니다.
const _regionCoordinates = {
  RegionCode.gongju: (latitude: 36.4465, longitude: 127.1189),
  RegionCode.buyeo: (latitude: 36.2756, longitude: 126.9099),
  RegionCode.seosan: (latitude: 36.7848, longitude: 126.4503),
  RegionCode.yesan: (latitude: 36.6816, longitude: 126.8462),
};

/// 개발 전용 mock 좌표를 반환하는 [LocationProvider] 구현체.
/// production 빌드에서는 `LocationProviderFactory`가 이 구현체를 절대 선택하지 않는다.
class MockLocationProvider implements LocationProvider {
  const MockLocationProvider(this.regionCode);

  final RegionCode regionCode;

  @override
  Future<Position?> getCurrentPosition() async {
    final coordinate = _regionCoordinates[regionCode]!;
    return Position(
      latitude: coordinate.latitude,
      longitude: coordinate.longitude,
      timestamp: DateTime.now(),
      accuracy: 0,
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
