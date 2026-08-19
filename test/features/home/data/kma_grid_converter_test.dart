import 'package:chaerok/features/home/data/kma_grid_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('서울시청 좌표를 기상청 공식 예시 격자좌표(nx=60, ny=127)로 변환한다', () {
    final grid = KmaGridConverter.toGrid(
      latitude: 37.5665,
      longitude: 126.9780,
    );

    expect(grid.nx, 60);
    expect(grid.ny, 127);
  });
}
