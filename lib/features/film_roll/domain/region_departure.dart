import 'package:chaerok/features/film_roll/domain/visit_verification.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/region/region_normalizer.dart';
import 'package:geolocator/geolocator.dart';

/// 필름롤 지역 이탈 판정 결과.
enum RegionDepartureStatus {
  /// 현재 위치가 필름롤 지역 안에 있다.
  inside,

  /// 현재 위치가 필름롤 지역을 벗어났다(다른 지원 지역이거나 지원 밖 지역).
  departed,

  /// 위치·역지오코딩 정보가 부족하거나 정확하지 않아 판정할 수 없다.
  unknown,
}

/// 현재 위치가 필름롤이 속한 지역을 벗어났는지 판정한다.
///
/// [position]이 없거나 GPS 정확도가 [kVisitMinGpsAccuracyMeters]를 넘으면(튐
/// 방지) [RegionDepartureStatus.unknown]을 반환한다. [currentCityCountyName]은
/// `KakaoLocalApiService.resolveAdministrativeRegion`으로 얻은 신선한
/// 역지오코딩 결과(시/군)여야 한다 — 세션 캐시된 값은 이동을 반영하지 못한다.
RegionDepartureStatus evaluateRegionDeparture({
  required RegionCode filmRollRegion,
  required String? currentCityCountyName,
  required Position? position,
}) {
  if (position == null) return RegionDepartureStatus.unknown;
  if (position.accuracy > kVisitMinGpsAccuracyMeters) {
    return RegionDepartureStatus.unknown;
  }
  if (currentCityCountyName == null) return RegionDepartureStatus.unknown;

  final currentRegion = RegionNormalizer.fromCityCountyName(
    currentCityCountyName,
  );
  return currentRegion == filmRollRegion
      ? RegionDepartureStatus.inside
      : RegionDepartureStatus.departed;
}
