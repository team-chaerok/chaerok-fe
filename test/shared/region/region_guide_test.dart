import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/region/region_guide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('모든 RegionCode에 guide가 정의돼 있다', () {
    for (final region in RegionCode.values) {
      expect(kRegionGuides.containsKey(region), isTrue, reason: '$region 누락');
    }
  });

  test('각 guide는 해시태그 정확히 3개, 비어있지 않은 romanized/tagline', () {
    for (final region in RegionCode.values) {
      final guide = region.guide;
      expect(guide.hashtags.length, 3, reason: '$region 해시태그 개수');
      expect(guide.hashtags.every((t) => t.trim().isNotEmpty), isTrue);
      expect(guide.romanized.trim(), isNotEmpty);
      expect(guide.tagline.trim(), isNotEmpty);
    }
  });

  test('예산/서산 카피는 Figma 문구와 일치한다', () {
    expect(RegionCode.yesan.guide.tagline, '고즈넉한 사찰과 넓은 호수, 시장의 온기가 함께 있는 곳');
    expect(RegionCode.yesan.guide.hashtags, ['수덕사', '예당호', '예산시장']);
    expect(RegionCode.seosan.guide.tagline, '바다와 갯벌, 노을이 어우러진 느린 여행의 도시');
    expect(RegionCode.seosan.guide.hashtags, ['해미읍성', '간월도', '서산버드랜드']);
  });
}
