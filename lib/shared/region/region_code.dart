/// 필름롤을 지원하는 4개 지역(공주시/부여군/서산시/예산군).
enum RegionCode {
  gongju,
  buyeo,
  seosan,
  yesan;

  /// 행정구역명(예: "공주시")으로 [RegionCode]를 역으로 찾는다. 매칭되는
  /// 지역이 없으면 null(서비스 4개 지역 밖의 값이 들어온 경우).
  static RegionCode? fromCityCountyName(String cityCountyName) {
    for (final region in RegionCode.values) {
      if (region.cityCountyName == cityCountyName) return region;
    }
    return null;
  }
}

/// [RegionCode]의 행정구역명·표시명·필름롤 제목을 제공하는 extension.
extension RegionCodeX on RegionCode {
  /// 백엔드/Kakao Local API가 반환하는 행정구역명(시/군 단위)과 동일한 표기.
  String get cityCountyName => switch (this) {
    RegionCode.gongju => '공주시',
    RegionCode.buyeo => '부여군',
    RegionCode.seosan => '서산시',
    RegionCode.yesan => '예산군',
  };

  /// 화면에 노출할 짧은 표시명.
  String get displayName => switch (this) {
    RegionCode.gongju => '공주',
    RegionCode.buyeo => '부여',
    RegionCode.seosan => '서산',
    RegionCode.yesan => '예산',
  };

  /// 필름롤 생성 시 기본 제목.
  String get filmRollTitle => '$displayName 필름롤';

  /// 충남 외 지역 홈 화면의 필름롤 아코디언 헤더 라벨.
  String get filmStripLabel => '$displayName 필름롤';
}
