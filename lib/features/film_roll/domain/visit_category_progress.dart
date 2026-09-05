import 'package:chaerok/data/models/place_category.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';

/// 현상(완료) 조건을 충족하는 데 필요한 서로 다른 관광 유형 수(관광/식당/카페·디저트).
const int requiredVisitCategoryCount = 3;

/// 서버 판정([VisitsApi.getVisits]의 `visitRequirementMet`)을 아직 받지 못했을 때
/// (오프라인·동기화 지연) 로컬 방문 기록만으로 현상 조건을 근사 판정하기 위해,
/// 방문한 장소들의 서로 다른 관광 유형(TOURISM/FOOD/CAFE_DESSERT) 수를 센다.
///
/// [FilmRollPlace.category]는 소분류(categoryDetail)를 우선하고 없으면 대분류
/// (categoryGroup)를 담은 문자열이라, 소분류 값이면 대분류로 승격해 그룹 단위로 센다.
int countDistinctVisitedCategories(List<FilmRollPlace> places) {
  final groups = <PlaceCategoryGroup>{};
  for (final place in places) {
    if (!place.isVisited) continue;
    final group = resolvePlaceCategoryGroup(place.category);
    if (group != PlaceCategoryGroup.unknown) groups.add(group);
  }
  return groups.length;
}

/// 로컬 방문 기록 기준으로 현상 조건(서로 다른 유형 [requiredVisitCategoryCount]개
/// 이상 방문)을 충족했는지 여부.
bool hasMetLocalCategoryRequirement(List<FilmRollPlace> places) {
  return countDistinctVisitedCategories(places) >= requiredVisitCategoryCount;
}

/// 장소 카테고리 문자열([FilmRollPlace.category])을 대분류 그룹으로 정규화한다.
/// 소분류(categoryDetail) 값이면 대응 대분류로 승격하고, 매핑에 없으면
/// [PlaceCategoryGroup.unknown]을 반환한다.
PlaceCategoryGroup resolvePlaceCategoryGroup(String rawCategory) {
  final detail = PlaceCategoryDetail.fromWire(rawCategory);
  if (detail != PlaceCategoryDetail.unknown) {
    return _groupForDetail(detail);
  }
  return PlaceCategoryGroup.fromWire(rawCategory);
}

PlaceCategoryGroup _groupForDetail(PlaceCategoryDetail detail) {
  switch (detail) {
    case PlaceCategoryDetail.heritage:
    case PlaceCategoryDetail.museum:
    case PlaceCategoryDetail.walk:
    case PlaceCategoryDetail.market:
    case PlaceCategoryDetail.souvenirShop:
    case PlaceCategoryDetail.nature:
    case PlaceCategoryDetail.experience:
      return PlaceCategoryGroup.tourism;
    case PlaceCategoryDetail.restaurant:
    case PlaceCategoryDetail.localFood:
    case PlaceCategoryDetail.snackMeal:
      return PlaceCategoryGroup.food;
    case PlaceCategoryDetail.cafe:
    case PlaceCategoryDetail.bakery:
    case PlaceCategoryDetail.dessert:
    case PlaceCategoryDetail.teaHouse:
    case PlaceCategoryDetail.snack:
      return PlaceCategoryGroup.cafeDessert;
    case PlaceCategoryDetail.unknown:
      return PlaceCategoryGroup.unknown;
  }
}
