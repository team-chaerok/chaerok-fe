import 'package:chaerok/features/film_roll/domain/region_departure.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

Position _positionWithAccuracy(double accuracy) {
  return Position(
    latitude: 36.4465,
    longitude: 127.1189,
    timestamp: DateTime(2026, 9, 5),
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
  group('evaluateRegionDeparture', () {
    test('position가 없으면 unknown', () {
      final result = evaluateRegionDeparture(
        filmRollRegion: RegionCode.gongju,
        currentCityCountyName: '공주시',
        position: null,
      );
      expect(result, RegionDepartureStatus.unknown);
    });

    test('GPS 정확도가 임계값을 넘으면 unknown', () {
      final result = evaluateRegionDeparture(
        filmRollRegion: RegionCode.gongju,
        currentCityCountyName: '부여군',
        position: _positionWithAccuracy(51),
      );
      expect(result, RegionDepartureStatus.unknown);
    });

    test('역지오코딩 실패(null)면 unknown', () {
      final result = evaluateRegionDeparture(
        filmRollRegion: RegionCode.gongju,
        currentCityCountyName: null,
        position: _positionWithAccuracy(10),
      );
      expect(result, RegionDepartureStatus.unknown);
    });

    test('현재 행정구역이 필름롤 지역과 같으면 inside', () {
      final result = evaluateRegionDeparture(
        filmRollRegion: RegionCode.gongju,
        currentCityCountyName: '공주시',
        position: _positionWithAccuracy(10),
      );
      expect(result, RegionDepartureStatus.inside);
    });

    test('다른 지원 지역으로 이동했으면 departed', () {
      final result = evaluateRegionDeparture(
        filmRollRegion: RegionCode.gongju,
        currentCityCountyName: '부여군',
        position: _positionWithAccuracy(10),
      );
      expect(result, RegionDepartureStatus.departed);
    });

    test('지원 밖 시/군으로 이동했으면 departed', () {
      final result = evaluateRegionDeparture(
        filmRollRegion: RegionCode.gongju,
        currentCityCountyName: '천안시',
        position: _positionWithAccuracy(10),
      );
      expect(result, RegionDepartureStatus.departed);
    });
  });
}
