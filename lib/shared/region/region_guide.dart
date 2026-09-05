import 'package:chaerok/shared/region/region_code.dart';

/// 충남 외 지역 홈 화면의 지역 소개 카피. 디자이너/백엔드 소스가 없어
/// 클라이언트에 하드코딩한다. Figma에 노출된 예산·서산은 그대로,
/// 공주·부여는 초안 카피(추후 확정 시 이 파일만 수정).
class RegionGuide {
  const RegionGuide({
    required this.romanized,
    required this.tagline,
    required this.hashtags,
  });

  /// 자간을 벌려 표시하는 로마자 라벨. 예: "Y E S A N"
  final String romanized;

  /// 1~2줄 지역 소개 문구.
  final String tagline;

  /// 해시태그 칩 텍스트(# 제외). 정확히 3개.
  final List<String> hashtags;
}

const Map<RegionCode, RegionGuide> kRegionGuides = {
  RegionCode.gongju: RegionGuide(
    romanized: 'G O N G J U',
    tagline: '백제의 왕도, 공산성과 무령왕릉이 있는 역사의 도시',
    hashtags: ['공산성', '무령왕릉', '갑사'],
  ),
  RegionCode.buyeo: RegionGuide(
    romanized: 'B U Y E O',
    tagline: '사비 백제의 마지막 수도, 부소산과 궁남지가 있는 곳',
    hashtags: ['부소산성', '궁남지', '정림사지'],
  ),
  RegionCode.seosan: RegionGuide(
    romanized: 'S E O S A N',
    tagline: '바다와 갯벌, 노을이 어우러진 느린 여행의 도시',
    hashtags: ['해미읍성', '간월도', '서산버드랜드'],
  ),
  RegionCode.yesan: RegionGuide(
    romanized: 'Y E S A N',
    tagline: '고즈넉한 사찰과 넓은 호수, 시장의 온기가 함께 있는 곳',
    hashtags: ['수덕사', '예당호', '예산시장'],
  ),
};

extension RegionGuideX on RegionCode {
  RegionGuide get guide => kRegionGuides[this]!;
}
