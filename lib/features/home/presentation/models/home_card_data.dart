import 'package:chaerok/data/models/place_category.dart';

/// 홈 대시보드/채록길 카드 위젯이 소비하는 표시 전용 뷰 데이터.
/// 도메인 엔티티(`FilmRoll`, `PlaceListResponse` 등)를 화면에서 이 타입으로
/// 매핑해 사용한다.
class RecommendedPlaceSummaryData {
  const RecommendedPlaceSummaryData({
    required this.name,
    required this.category,
    required this.placeholderMood,
    this.imageUrl,
    this.distance,
    this.isRecorded = false,
  });

  final String name;
  final String category;

  /// 관광지 대표 사진(한국관광공사 TourAPI `firstImageUrl`) URL.
  /// 없으면 [placeholderMood] 기반 일러스트로 대체한다.
  final String? imageUrl;

  /// 현재 위치를 확인할 수 없으면(예: 위치 권한 미허용) null.
  final String? distance;
  final PlacePlaceholderMood placeholderMood;

  /// 현재 진행중 필름롤에서 이미 채록(방문)을 완료한 장소인지 여부.
  final bool isRecorded;
}

enum PlacePlaceholderMood { stream, wall, forest }

/// 카테고리별 기본 일러스트 배정. 대표 사진이 없을 때 관광지·식당·카페가
/// 서로 다른 그림으로 구분되도록 고정 매핑한다(장소명 키워드 검색 등
/// 검증할 수 없는 이미지로 대체하지 않는다).
PlacePlaceholderMood moodForCategory(PlaceCategoryGroup group) {
  switch (group) {
    case PlaceCategoryGroup.tourism:
      return PlacePlaceholderMood.forest;
    case PlaceCategoryGroup.food:
      return PlacePlaceholderMood.wall;
    case PlaceCategoryGroup.cafeDessert:
    case PlaceCategoryGroup.unknown:
      return PlacePlaceholderMood.stream;
  }
}

/// 홈 대시보드의 날씨 카드가 소비하는 표시 전용 뷰 데이터.
class WeatherSummaryData {
  const WeatherSummaryData({
    required this.regionName,
    required this.temperature,
    required this.weatherLabel,
  });

  final String regionName;
  final double temperature;
  final String weatherLabel;
}
