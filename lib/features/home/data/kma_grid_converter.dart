import 'dart:math' as math;

/// 위경도를 기상청 단기예보 API가 요구하는 격자좌표(nx, ny)로 변환합니다.
/// 기상청이 공개한 LCC DFS(Lambert Conformal Conic) 변환식을 그대로 구현했다.
class KmaGridConverter {
  const KmaGridConverter._();

  static const double _re = 6371.00877;
  static const double _grid = 5.0;
  static const double _slat1 = 30.0;
  static const double _slat2 = 60.0;
  static const double _olon = 126.0;
  static const double _olat = 38.0;
  static const double _xo = 43;
  static const double _yo = 136;

  static const double _degToRad = math.pi / 180.0;

  static ({int nx, int ny}) toGrid({
    required double latitude,
    required double longitude,
  }) {
    final re = _re / _grid;
    final slat1 = _slat1 * _degToRad;
    final slat2 = _slat2 * _degToRad;
    final olon = _olon * _degToRad;
    final olat = _olat * _degToRad;

    var sn =
        math.tan(math.pi * 0.25 + slat2 * 0.5) /
        math.tan(math.pi * 0.25 + slat1 * 0.5);
    sn = math.log(math.cos(slat1) / math.cos(slat2)) / math.log(sn);
    var sf = math.tan(math.pi * 0.25 + slat1 * 0.5);
    sf = math.pow(sf, sn) * math.cos(slat1) / sn;
    var ro = math.tan(math.pi * 0.25 + olat * 0.5);
    ro = re * sf / math.pow(ro, sn);

    var ra = math.tan(math.pi * 0.25 + latitude * _degToRad * 0.5);
    ra = re * sf / math.pow(ra, sn);
    var theta = longitude * _degToRad - olon;
    if (theta > math.pi) theta -= 2.0 * math.pi;
    if (theta < -math.pi) theta += 2.0 * math.pi;
    theta *= sn;

    final nx = (ra * math.sin(theta) + _xo + 0.5).floor();
    final ny = (ro - ra * math.cos(theta) + _yo + 0.5).floor();
    return (nx: nx, ny: ny);
  }
}
