import 'package:chaerok/data/models/place_category.dart';
import 'package:chaerok/features/explore/domain/explore_place.dart';

/// 탐색 모드의 장소 카테고리 필터 칩.
///
/// `categoryGroup`(TOURISM/FOOD/CAFE_DESSERT)은 신뢰할 수 있으므로 우선 사용하고,
/// 소분류는 `categoryDetail` enum과 원본 문자열 키워드를 함께 본다(백엔드가
/// 영문 enum 값 대신 한글 분류를 줄 가능성에 대비 — analyze ⚠️3).
enum ExploreCategoryFilter {
  all('전체'),
  nature('자연'),
  culture('문화'),
  heritage('유적'),
  food('음식'),
  cafe('카페');

  const ExploreCategoryFilter(this.label);

  final String label;

  bool matches(ExplorePlace place) {
    switch (this) {
      case ExploreCategoryFilter.all:
        return true;
      case ExploreCategoryFilter.food:
        return place.categoryGroup == PlaceCategoryGroup.food ||
            _labelHasAny(place, const ['음식', '식당', '맛집']);
      case ExploreCategoryFilter.cafe:
        return place.categoryGroup == PlaceCategoryGroup.cafeDessert ||
            _labelHasAny(place, const ['카페', '디저트', '베이커리', '찻집']);
      case ExploreCategoryFilter.nature:
        return _detailIn(place, const [
              PlaceCategoryDetail.nature,
              PlaceCategoryDetail.walk,
            ]) ||
            _labelHasAny(place, const ['자연', '산책', '공원', '숲', '하천']);
      case ExploreCategoryFilter.culture:
        return _detailIn(place, const [
              PlaceCategoryDetail.museum,
              PlaceCategoryDetail.experience,
            ]) ||
            _labelHasAny(place, const ['문화', '전시', '박물관', '미술', '체험']);
      case ExploreCategoryFilter.heritage:
        return _detailIn(place, const [PlaceCategoryDetail.heritage]) ||
            _labelHasAny(place, const ['유적', '역사', '사적', '문화재', '고분']);
    }
  }

  static bool _detailIn(ExplorePlace place, List<PlaceCategoryDetail> details) {
    return place.categoryDetail != PlaceCategoryDetail.unknown &&
        details.contains(place.categoryDetail);
  }

  static bool _labelHasAny(ExplorePlace place, List<String> keywords) {
    final label = place.categoryDetailLabel;
    return keywords.any(label.contains);
  }
}
