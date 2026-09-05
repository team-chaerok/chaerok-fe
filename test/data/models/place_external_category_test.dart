import 'package:chaerok/data/models/place_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PlaceExternalCategory.fromWire', () {
    test('8개 코드를 각각 올바른 값으로 매핑한다', () {
      expect(
        PlaceExternalCategory.fromWire('RESTAURANT'),
        PlaceExternalCategory.restaurant,
      );
      expect(
        PlaceExternalCategory.fromWire('CAFE'),
        PlaceExternalCategory.cafe,
      );
      expect(
        PlaceExternalCategory.fromWire('HERITAGE'),
        PlaceExternalCategory.heritage,
      );
      expect(
        PlaceExternalCategory.fromWire('EXPERIENCE'),
        PlaceExternalCategory.experience,
      );
      expect(
        PlaceExternalCategory.fromWire('ATTRACTION'),
        PlaceExternalCategory.attraction,
      );
      expect(
        PlaceExternalCategory.fromWire('NATURE'),
        PlaceExternalCategory.nature,
      );
      expect(
        PlaceExternalCategory.fromWire('SHOPPING'),
        PlaceExternalCategory.shopping,
      );
      expect(
        PlaceExternalCategory.fromWire('ACCOMMODATION'),
        PlaceExternalCategory.accommodation,
      );
    });

    test('대소문자·공백을 정규화한다', () {
      expect(
        PlaceExternalCategory.fromWire('  restaurant '),
        PlaceExternalCategory.restaurant,
      );
      expect(
        PlaceExternalCategory.fromWire('Cafe'),
        PlaceExternalCategory.cafe,
      );
    });

    test('매핑에 없는 값과 null은 unknown', () {
      expect(
        PlaceExternalCategory.fromWire('AT4'),
        PlaceExternalCategory.unknown,
      );
      expect(
        PlaceExternalCategory.fromWire('관광지'),
        PlaceExternalCategory.unknown,
      );
      expect(
        PlaceExternalCategory.fromWire(null),
        PlaceExternalCategory.unknown,
      );
      expect(PlaceExternalCategory.fromWire(''), PlaceExternalCategory.unknown);
    });
  });

  group('PlaceExternalCategory.displayLabel', () {
    test('영문 코드는 한글 라벨로 변환한다', () {
      expect(PlaceExternalCategory.displayLabel('RESTAURANT'), '음식점');
      expect(PlaceExternalCategory.displayLabel('cafe'), '카페');
      expect(PlaceExternalCategory.displayLabel('HERITAGE'), '역사·문화');
      expect(PlaceExternalCategory.displayLabel('EXPERIENCE'), '체험');
      expect(PlaceExternalCategory.displayLabel('ATTRACTION'), '관광지');
      expect(PlaceExternalCategory.displayLabel('NATURE'), '자연');
      expect(PlaceExternalCategory.displayLabel('SHOPPING'), '쇼핑');
      expect(PlaceExternalCategory.displayLabel('ACCOMMODATION'), '숙박');
    });

    test('매핑에 없는 값은 원본(trim)을 그대로 돌려준다', () {
      expect(PlaceExternalCategory.displayLabel('  관광지 '), '관광지');
      expect(PlaceExternalCategory.displayLabel('AT4'), 'AT4');
      expect(PlaceExternalCategory.displayLabel(null), '');
    });
  });
}
