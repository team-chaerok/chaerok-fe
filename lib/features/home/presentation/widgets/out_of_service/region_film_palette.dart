import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/widgets.dart';

/// 충남 외 지역 홈 필름롤에서 지역을 구분하는 프레젠테이션 값.
/// 탭 배경색과 상단 오른쪽 사진 스트립에 쓰이며, 카드 바디·해시태그 칩·배너 등
/// 나머지는 공용 디자인 토큰을 그대로 사용한다.
extension RegionFilmPalette on RegionCode {
  /// 필름롤 탭 배경색. 모두 어두워 흰색 라벨이 읽히고, 앱 올리브 계열과
  /// 조화되도록 잡았다. 확정 팔레트가 오면 여기만 바꾸면 된다.
  Color get filmTabColor => switch (this) {
    // Figma 기본 노출 지역 — 기존 primaryDark 유지.
    RegionCode.yesan => const Color(0xFFEDE6E0),
    // 갯벌·노을 — 딥 틸.
    RegionCode.seosan => const Color(0xFF867C5C),
    // 궁남지 연꽃 — 다크 플럼.
    RegionCode.buyeo => const Color(0xFF797A5E),
    // 백제 왕도 — 다크 엄버.
    RegionCode.gongju => const Color(0xFF52523D),
  };

  /// 지역 대표 사진 에셋 경로. 파일은 추후 추가되며, 없을 때는
  /// [RegionFilmPhoto]가 [filmTabColor] 블록으로 폴백한다.
  String get filmPhotoAsset => switch (this) {
    RegionCode.gongju => 'assets/images/regions/gongju.webp',
    RegionCode.buyeo => 'assets/images/regions/buyeo.webp',
    RegionCode.seosan => 'assets/images/regions/seosan.webp',
    RegionCode.yesan => 'assets/images/regions/yesan.webp',
  };

  /// 지역별 필름 질감(그레인·라이트 리크) 오버레이 에셋 경로.
  /// [RegionFilmPhoto]가 [filmPhotoAsset] 위에 [BlendMode.overlay]로 얹어
  /// 지역별 색감을 낸다.
  String get filmFilterAsset => switch (this) {
    RegionCode.gongju => 'assets/images/filters/gongju-filter.png',
    RegionCode.buyeo => 'assets/images/filters/buyeo-filter.png',
    RegionCode.seosan => 'assets/images/filters/seosan-filter.jpg',
    RegionCode.yesan => 'assets/images/filters/yesan-filter.jpg',
  };
}
