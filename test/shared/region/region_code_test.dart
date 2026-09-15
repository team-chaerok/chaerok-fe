import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RegionCode.fromCityCountyName', () {
    test('행정구역명으로 일치하는 RegionCode를 찾는다', () {
      expect(RegionCode.fromCityCountyName('공주시'), RegionCode.gongju);
      expect(RegionCode.fromCityCountyName('부여군'), RegionCode.buyeo);
      expect(RegionCode.fromCityCountyName('서산시'), RegionCode.seosan);
      expect(RegionCode.fromCityCountyName('예산군'), RegionCode.yesan);
    });

    test('4개 지역 밖의 값이면 null을 반환한다', () {
      expect(RegionCode.fromCityCountyName('천안시'), isNull);
      expect(RegionCode.fromCityCountyName(''), isNull);
    });
  });
}
