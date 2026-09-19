import 'package:chaerok/data/models/place_category.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('카테고리 그룹마다 서로 다른 기본 일러스트를 배정한다', () {
    expect(
      moodForCategory(PlaceCategoryGroup.tourism),
      PlacePlaceholderMood.forest,
    );
    expect(moodForCategory(PlaceCategoryGroup.food), PlacePlaceholderMood.wall);
    expect(
      moodForCategory(PlaceCategoryGroup.cafeDessert),
      PlacePlaceholderMood.stream,
    );
    expect(
      moodForCategory(PlaceCategoryGroup.unknown),
      PlacePlaceholderMood.stream,
    );
  });
}
