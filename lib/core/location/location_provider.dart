import 'package:geolocator/geolocator.dart';

/// 현재 위치 좌표 조회를 추상화한다. 실제 기기 좌표(`RealLocationProvider`)와
/// 개발용 mock 좌표(`MockLocationProvider`)를 동일한 인터페이스로 다룰 수 있게 한다.
abstract class LocationProvider {
  Future<Position?> getCurrentPosition();
}
