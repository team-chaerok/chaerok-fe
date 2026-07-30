import 'package:chaerok/core/location/location_provider.dart';
import 'package:chaerok/features/location/data/location_permission_service.dart';
import 'package:geolocator/geolocator.dart';

/// 실제 기기 GPS 좌표를 조회하는 [LocationProvider] 구현체.
class RealLocationProvider implements LocationProvider {
  const RealLocationProvider();

  @override
  Future<Position?> getCurrentPosition() {
    return LocationPermissionService.getCurrentPosition();
  }
}
