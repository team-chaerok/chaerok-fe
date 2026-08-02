/// 필름롤을 지원하는 4개 지역(공주시/부여군/서산시/예산군).
enum RegionCode { gongju, buyeo, seosan, yesan }

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
}
