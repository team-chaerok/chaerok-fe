import 'package:chaerok/data/models/place_search_response.dart';
import 'package:chaerok/features/explore/domain/explore_place.dart';
import 'package:flutter_test/flutter_test.dart';

PlaceSearchResponse _searchResponse({
  int? id,
  String? kakaoPlaceId,
  String? tourContentId,
  required String source,
}) {
  return PlaceSearchResponse(
    id: id,
    kakaoPlaceId: kakaoPlaceId,
    tourContentId: tourContentId,
    title: '장소',
    address: '주소',
    latitude: 0,
    longitude: 0,
    categoryGroup: 'TOURISM',
    categoryDetail: 'HERITAGE',
    source: source,
  );
}

void main() {
  group('ExplorePlace.fromSearchResponse externalPlaceId', () {
    test(
      'source가 KAKAO_LOCAL(실제 백엔드 값)이어도 kakaoPlaceId를 externalPlaceId로 인식한다',
      () {
        final place = _searchResponse(
          kakaoPlaceId: 'kakao-1',
          source: 'KAKAO_LOCAL',
        );

        final result = ExplorePlace.fromSearchResponse(place);

        expect(result.externalPlaceId, 'kakao-1');
        expect(result.identityKey, 'external:KAKAO_LOCAL:kakao-1');
      },
    );

    test(
      'source가 KAKAO(Swagger 예시 값)여도 kakaoPlaceId를 externalPlaceId로 인식한다',
      () {
        final place = _searchResponse(kakaoPlaceId: 'kakao-1', source: 'KAKAO');

        final result = ExplorePlace.fromSearchResponse(place);

        expect(result.externalPlaceId, 'kakao-1');
      },
    );

    test('source가 TOUR_API면 tourContentId를 externalPlaceId로 인식한다', () {
      final place = _searchResponse(
        tourContentId: 'tour-1',
        source: 'TOUR_API',
      );

      final result = ExplorePlace.fromSearchResponse(place);

      expect(result.externalPlaceId, 'tour-1');
    });

    test('id가 null이어도(검색 결과는 DB에 저장되지 않음) 예외 없이 변환된다', () {
      final place = _searchResponse(
        tourContentId: 'tour-1',
        source: 'TOUR_API',
      );

      final result = ExplorePlace.fromSearchResponse(place);

      expect(result.serverId, isNull);
    });
  });
}
