/// 앱 전역 간격(padding·margin·gap) 토큰. 4px 기반 스케일이며 이름 뒤 주석이
/// 실제 픽셀 값이다. 레이아웃에 raw 숫자를 쓰지 말고 이 토큰을 사용한다.
class ChaerokSpacing {
  const ChaerokSpacing._();

  /// 4px — 아이콘·텍스트 사이 등 최소 간격.
  static const double xxs = 4;

  /// 8px — 밀집된 요소 사이 기본 간격.
  static const double xs = 8;

  /// 12px — 카드 내부 요소 사이 간격.
  static const double sm = 12;

  /// 16px — 화면 기본 좌우 패딩, 섹션 내 간격.
  static const double md = 16;

  /// 20px — 카드 사이, 섹션 제목과 본문 사이.
  static const double lg = 20;

  /// 24px — 섹션과 섹션 사이.
  static const double xl = 24;

  /// 32px — 화면 상하 여백 등 가장 큰 간격.
  static const double xxl = 32;
}
