import 'package:geolocator/geolocator.dart';

/// [MockLocationGate]가 만든 QA/테스트 계정용 mock 위치.
///
/// 방문 인증 게이트(`evaluateVisitGate`)는 이 타입일 때만 거리·정확도 검사를
/// 건너뛴다. `Position.isMocked`로 판별하지 않는 이유: 실제 GPS도 가짜 GPS
/// 앱을 쓰면 `isMocked == true`를 돌려주므로, 그 값으로 우회하면 일반 사용자가
/// 방문 인증을 속일 수 있다. 실제 위치 조회 경로는 이 타입을 만들지 않는다.
class MockPosition extends Position {
  const MockPosition({
    required super.latitude,
    required super.longitude,
    required super.timestamp,
    required super.accuracy,
  }) : super(
         altitude: 0,
         altitudeAccuracy: 0,
         heading: 0,
         headingAccuracy: 0,
         speed: 0,
         speedAccuracy: 0,
         isMocked: true,
       );
}
