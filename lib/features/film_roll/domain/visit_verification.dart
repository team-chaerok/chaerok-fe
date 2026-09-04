import 'package:geolocator/geolocator.dart';

/// 방문 인증 가능 반경(m). 사용자 위치가 대상 장소로부터 이 거리 이내여야 인증할 수 있다.
const double kVisitVerifiableRadiusMeters = 100;

/// 방문 인증에 허용되는 최대 GPS 오차(m). `Position.accuracy`가 이 값을 넘으면
/// 위치가 충분히 정확하지 않은 것으로 보고 재조회를 유도한다.
const double kVisitMinGpsAccuracyMeters = 50;

enum VisitGateStatus { ok, alreadyVisited, noPosition, inaccurate, tooFar }

/// 방문 인증 4단계 게이트 평가 결과.
class VisitGateResult {
  const VisitGateResult(this.status, {this.distanceMeters});

  final VisitGateStatus status;

  /// 사용자 위치와 장소 사이 거리(m). 위치를 확인하지 못했으면 null.
  final double? distanceMeters;

  bool get canVerify => status == VisitGateStatus.ok;

  String get message => switch (status) {
    VisitGateStatus.ok => '지금 방문 인증할 수 있어요',
    VisitGateStatus.alreadyVisited => '이미 방문 인증한 장소예요',
    VisitGateStatus.noPosition => '현재 위치를 확인하는 중이에요',
    VisitGateStatus.inaccurate => '현재 위치가 정확하지 않아요. 잠시 후 다시 시도해주세요',
    VisitGateStatus.tooFar => '장소에 더 가까이 가면 방문 인증할 수 있어요',
  };
}

/// 방문 인증 게이트를 순서대로 평가한다:
/// 1. 동일 필름롤 내 이미 인증된 장소인지
/// 2. 현재 위치를 확보했는지
/// 3. GPS 정확도가 [kVisitMinGpsAccuracyMeters] 이내인지
/// 4. 장소와의 거리가 [kVisitVerifiableRadiusMeters] 이내인지
VisitGateResult evaluateVisitGate({
  required Position? position,
  required double placeLatitude,
  required double placeLongitude,
  required bool alreadyVisited,
}) {
  if (alreadyVisited) {
    return const VisitGateResult(VisitGateStatus.alreadyVisited);
  }
  if (position == null) {
    return const VisitGateResult(VisitGateStatus.noPosition);
  }
  if (position.accuracy > kVisitMinGpsAccuracyMeters) {
    return const VisitGateResult(VisitGateStatus.inaccurate);
  }
  final distance = Geolocator.distanceBetween(
    position.latitude,
    position.longitude,
    placeLatitude,
    placeLongitude,
  );
  if (distance > kVisitVerifiableRadiusMeters) {
    return VisitGateResult(VisitGateStatus.tooFar, distanceMeters: distance);
  }
  return VisitGateResult(VisitGateStatus.ok, distanceMeters: distance);
}
