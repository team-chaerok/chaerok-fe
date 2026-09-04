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
