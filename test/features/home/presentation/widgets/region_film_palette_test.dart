import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_palette.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('모든 RegionCode에 서로 다른 탭 색이 정의돼 있다', () {
    final colors = {for (final r in RegionCode.values) r.filmTabColor};
    expect(colors.length, RegionCode.values.length, reason: '탭 색이 겹친다');
  });

  test('예산 외 지역은 흰 라벨이 읽히도록 충분히 어둡다', () {
    for (final region in RegionCode.values) {
      if (region == RegionCode.yesan) continue;
      final luminance = region.filmTabColor.computeLuminance();
      expect(luminance, lessThan(0.25), reason: '$region 탭 색이 너무 밝다');
    }
  });

  test('예산은 밝은 팔레트를 쓴다(라벨은 RegionFilmCard가 어두운 색으로 강제)', () {
    expect(RegionCode.yesan.filmTabColor.toARGB32(), 0xFFEDE6E0);
    expect(
      RegionCode.yesan.filmTabColor.computeLuminance(),
      greaterThan(0.25),
      reason: '예산은 의도적으로 밝은 색을 쓴다 — 라벨 색은 RegionFilmCard에서 별도로 어둡게 강제한다',
    );
  });

  test('filmLabelColor: 예산만 어두운 색을 강제하고 나머지는 기본(흰색)을 쓴다', () {
    expect(RegionCode.yesan.filmLabelColor, const Color(0xFF45523D));
    expect(RegionCode.gongju.filmLabelColor, isNull);
    expect(RegionCode.buyeo.filmLabelColor, isNull);
    expect(RegionCode.seosan.filmLabelColor, isNull);
  });

  test('사진 에셋 경로는 지역별로 다르고 regions 폴더의 webp를 가리킨다', () {
    final paths = {for (final r in RegionCode.values) r.filmPhotoAsset};
    expect(paths.length, RegionCode.values.length);
    for (final path in paths) {
      expect(path, startsWith('assets/images/regions/'));
      expect(path, endsWith('.webp'));
    }
  });
}
