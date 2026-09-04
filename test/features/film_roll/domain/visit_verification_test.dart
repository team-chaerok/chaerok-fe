import 'package:chaerok/features/film_roll/domain/visit_verification.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

Position _position({
  required double latitude,
  required double longitude,
  double accuracy = 10,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime(2026, 1, 1),
    accuracy: accuracy,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  // 대상 장소: 공주 시청 근처 임의 좌표.
  const placeLatitude = 36.4465;
  const placeLongitude = 127.1189;

  VisitGateResult evaluate(Position? position, {bool alreadyVisited = false}) {
    return evaluateVisitGate(
      position: position,
      placeLatitude: placeLatitude,
      placeLongitude: placeLongitude,
      alreadyVisited: alreadyVisited,
    );
  }

  test('방문 인증 시점에 재조회한 좌표가 반경 이내면 인증 가능(ok)', () {
    // 장소에서 북쪽으로 약 50m.
    final result = evaluate(
      _position(latitude: 36.44695, longitude: placeLongitude),
    );

    expect(result.status, VisitGateStatus.ok);
    expect(result.canVerify, isTrue);
    expect(
      result.distanceMeters,
      lessThanOrEqualTo(kVisitVerifiableRadiusMeters),
    );
  });

  test('재조회한 좌표가 반경 밖이면 tooFar — 오래된 좌표로 통과되지 않는다', () {
    // 장소에서 약 300m 떨어진 좌표(직전엔 가까웠더라도 지금은 멀다).
    final result = evaluate(
      _position(latitude: 36.4492, longitude: placeLongitude),
    );

    expect(result.status, VisitGateStatus.tooFar);
    expect(result.canVerify, isFalse);
    expect(result.distanceMeters, greaterThan(kVisitVerifiableRadiusMeters));
  });

  test('재조회한 좌표의 GPS 정확도가 기준을 넘으면 inaccurate', () {
    final result = evaluate(
      _position(
        latitude: placeLatitude,
        longitude: placeLongitude,
        accuracy: kVisitMinGpsAccuracyMeters + 1,
      ),
    );

    expect(result.status, VisitGateStatus.inaccurate);
  });

  test('좌표 재조회에 실패해 position이 null이면 noPosition', () {
    expect(evaluate(null).status, VisitGateStatus.noPosition);
  });

  test('이미 방문 인증한 장소는 좌표와 무관하게 alreadyVisited', () {
    final result = evaluate(
      _position(latitude: placeLatitude, longitude: placeLongitude),
      alreadyVisited: true,
    );

    expect(result.status, VisitGateStatus.alreadyVisited);
  });

  test('GPS 정확도가 기준값과 같으면(경계) 통과한다', () {
    final result = evaluate(
      _position(
        latitude: placeLatitude,
        longitude: placeLongitude,
        accuracy: kVisitMinGpsAccuracyMeters,
      ),
    );

    expect(result.status, VisitGateStatus.ok);
  });
}
