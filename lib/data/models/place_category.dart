/// 장소 카테고리 분류. 백엔드 응답의 `categoryGroup`(대분류)과 `categoryDetail`
/// (소분류)를 느슨하게 enum으로 승격한다. 백엔드가 값을 새로 추가해도 파싱이
/// 깨지지 않도록 미지값은 [PlaceCategoryGroup.unknown]/[PlaceCategoryDetail.unknown]
/// 으로 흡수한다.
enum PlaceCategoryGroup {
  tourism('TOURISM'),
  food('FOOD'),
  cafeDessert('CAFE_DESSERT'),
  unknown('');

  const PlaceCategoryGroup(this.wireValue);

  final String wireValue;

  static PlaceCategoryGroup fromWire(String? value) {
    for (final group in values) {
      if (group != unknown && group.wireValue == value) return group;
    }
    return unknown;
  }
}

/// `/api/places/external`(TourAPI 기반)가 내려주는 장소 카테고리 코드.
/// 화면에는 [label](한글)로 노출한다. 매핑에 없는 값은 [unknown]으로 흡수하고,
/// 표시에는 원본 문자열을 그대로 쓴다([displayLabel] 참고).
enum PlaceExternalCategory {
  restaurant('RESTAURANT', '음식점'),
  cafe('CAFE', '카페'),
  heritage('HERITAGE', '역사·문화'),
  experience('EXPERIENCE', '체험'),
  attraction('ATTRACTION', '관광지'),
  nature('NATURE', '자연'),
  shopping('SHOPPING', '쇼핑'),
  accommodation('ACCOMMODATION', '숙박'),
  unknown('', '');

  const PlaceExternalCategory(this.wireValue, this.label);

  final String wireValue;
  final String label;

  static PlaceExternalCategory fromWire(String? value) {
    if (value == null) return unknown;
    final normalized = value.trim().toUpperCase();
    for (final category in values) {
      if (category != unknown && category.wireValue == normalized) {
        return category;
      }
    }
    return unknown;
  }

  /// 원본 카테고리 문자열을 화면 표기용 한글로 변환한다. 매핑에 없으면
  /// 원본 문자열을 그대로 돌려준다(백엔드가 한글을 주는 경우 등 기존 동작 유지).
  static String displayLabel(String? raw) {
    final category = fromWire(raw);
    if (category != unknown) return category.label;
    return raw?.trim() ?? '';
  }
}

enum PlaceCategoryDetail {
  heritage('HERITAGE'),
  museum('MUSEUM'),
  walk('WALK'),
  market('MARKET'),
  souvenirShop('SOUVENIR_SHOP'),
  nature('NATURE'),
  experience('EXPERIENCE'),
  restaurant('RESTAURANT'),
  localFood('LOCAL_FOOD'),
  snackMeal('SNACK_MEAL'),
  cafe('CAFE'),
  bakery('BAKERY'),
  dessert('DESSERT'),
  teaHouse('TEA_HOUSE'),
  snack('SNACK'),
  unknown('');

  const PlaceCategoryDetail(this.wireValue);

  final String wireValue;

  static PlaceCategoryDetail fromWire(String? value) {
    for (final detail in values) {
      if (detail != unknown && detail.wireValue == value) return detail;
    }
    return unknown;
  }
}
