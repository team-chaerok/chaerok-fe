import 'package:chaerok/shared/region/region_code.dart';

/// 행정구역명 문자열을 [RegionCode]로 정규화합니다.
/// 반드시 행정구역 필드(시/군 단위 정확한 명칭)와 완전 일치하는 경우에만 매칭하며,
/// `contains` 등 부분 일치는 사용하지 않는다(다른 지역명이 우연히 포함되는 오탐 방지).
class RegionNormalizer {
  const RegionNormalizer._();

  /// [cityCountyName]과 정확히 일치하는 지원 지역이 있으면 해당 [RegionCode]를,
  /// 없으면 null을 반환합니다.
  static RegionCode? fromCityCountyName(String cityCountyName) {
    for (final region in RegionCode.values) {
      if (region.cityCountyName == cityCountyName) {
        return region;
      }
    }
    return null;
  }
}
