import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_palette.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('모든 RegionCode에 서로 다른 탭 색이 정의돼 있다', () {
    final colors = {for (final r in RegionCode.values) r.filmTabColor};
    expect(colors.length, RegionCode.values.length, reason: '탭 색이 겹친다');
  });

  test('탭 색은 모두 흰 라벨이 읽히도록 충분히 어둡다', () {
    for (final region in RegionCode.values) {
      final luminance = region.filmTabColor.computeLuminance();
      expect(luminance, lessThan(0.25), reason: '$region 탭 색이 너무 밝다');
    }
  });

  test('예산은 기존 primaryDark(0xFF324D3E)를 유지한다', () {
    expect(RegionCode.yesan.filmTabColor.toARGB32(), 0xFF324D3E);
  });

  test('사진 에셋 경로는 지역별로 다르고 regions 폴더의 webp를 가리킨다', () {
    final paths = {for (final r in RegionCode.values) r.filmPhotoAsset};
    expect(paths.length, RegionCode.values.length);
    for (final path in paths) {
      expect(path, startsWith('assets/images/regions/'));
      expect(path, endsWith('.webp'));
    }
  });

  test('필터 에셋 경로는 지역별로 다르고 filters 폴더를 가리킨다', () {
    final paths = {for (final r in RegionCode.values) r.filmFilterAsset};
    expect(paths.length, RegionCode.values.length);
    for (final path in paths) {
      expect(path, startsWith('assets/images/filters/'));
    }
  });
}
