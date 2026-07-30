import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/region/region_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('지원하는 4개 지역명을 각각 올바른 RegionCode로 정규화한다', () {
    expect(RegionNormalizer.fromCityCountyName('공주시'), RegionCode.gongju);
    expect(RegionNormalizer.fromCityCountyName('부여군'), RegionCode.buyeo);
    expect(RegionNormalizer.fromCityCountyName('서산시'), RegionCode.seosan);
    expect(RegionNormalizer.fromCityCountyName('예산군'), RegionCode.yesan);
  });

  test('지원하지 않는 지역명은 null을 반환한다', () {
    expect(RegionNormalizer.fromCityCountyName('천안시'), isNull);
  });

  test('부분 일치(contains)로는 매칭되지 않는다', () {
    // '공주시'를 포함하지만 완전히 일치하지 않는 문자열은 매칭되면 안 된다.
    expect(RegionNormalizer.fromCityCountyName('공주시 유구읍'), isNull);
    expect(RegionNormalizer.fromCityCountyName('신공주시'), isNull);
  });

  test('빈 문자열은 null을 반환한다', () {
    expect(RegionNormalizer.fromCityCountyName(''), isNull);
  });
}
