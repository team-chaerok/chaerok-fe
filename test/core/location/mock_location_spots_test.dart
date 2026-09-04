import 'package:chaerok/core/location/mock_location_spots.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('4개 지역 모두 mock 지점을 3개 이상 갖는다', () {
    for (final region in RegionCode.values) {
      final spots = mockLocationSpots[region];
      expect(spots, isNotNull, reason: '$region 지점 세트 누락');
      expect(
        spots!.length,
        greaterThanOrEqualTo(3),
        reason: '$region 지점이 3개 미만',
      );
    }
  });

  test('모든 지점 좌표가 대한민국 범위 안에 있고 라벨이 비어있지 않다', () {
    for (final spots in mockLocationSpots.values) {
      for (final spot in spots) {
        expect(spot.label.trim(), isNotEmpty);
        expect(spot.latitude, inInclusiveRange(33, 39));
        expect(spot.longitude, inInclusiveRange(124, 132));
      }
    }
  });

  test('지역 내 지점 라벨은 서로 중복되지 않는다', () {
    for (final entry in mockLocationSpots.entries) {
      final labels = entry.value.map((spot) => spot.label).toList();
      expect(
        labels.toSet().length,
        labels.length,
        reason: '${entry.key} 라벨 중복',
      );
    }
  });

  test('mock GPS 정확도는 방문 게이트 임계값(50m)보다 작다', () {
    expect(kMockGpsAccuracyMeters, greaterThan(0));
    expect(kMockGpsAccuracyMeters, lessThan(50));
  });
}
