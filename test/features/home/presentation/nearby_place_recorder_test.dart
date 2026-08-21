import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/home/presentation/nearby_place_recorder.dart';
import 'package:flutter_test/flutter_test.dart';

PlaceListResponse _place({
  int? id,
  String? kakaoPlaceId,
  String? tourContentId,
  required String source,
}) {
  return PlaceListResponse(
    id: id,
    kakaoPlaceId: kakaoPlaceId,
    tourContentId: tourContentId,
    title: '장소',
    address: '주소',
    latitude: 0,
    longitude: 0,
    categoryGroup: 'TOURISM',
    categoryDetail: 'HERITAGE',
    isRepresentative: false,
    source: source,
  );
}

FilmRollPlace _filmRollPlace({
  int? serverPlaceId,
  String? externalPlaceId,
  bool isVisited = true,
}) {
  return FilmRollPlace(
    id: 'frp-1',
    filmRollId: 'roll-1',
    serverPlaceId: serverPlaceId,
    externalPlaceId: externalPlaceId,
    name: '장소',
    address: '주소',
    category: '카테고리',
    latitude: 0,
    longitude: 0,
    visitOrder: 0,
    isVisited: isVisited,
    photoCount: 0,
  );
}

void main() {
  group('NearbyPlaceRecorder.isRecorded', () {
    test('서버 placeId가 같으면 채록된 장소로 판정한다', () {
      final place = _place(id: 42, source: 'TOUR_API');
      final filmRollPlaces = [_filmRollPlace(serverPlaceId: 42)];

      expect(NearbyPlaceRecorder.isRecorded(place, filmRollPlaces), isTrue);
    });

    test('KAKAO 출처는 kakaoPlaceId를 externalPlaceId와 비교한다', () {
      final place = _place(kakaoPlaceId: 'kakao-1', source: 'KAKAO');
      final filmRollPlaces = [_filmRollPlace(externalPlaceId: 'kakao-1')];

      expect(NearbyPlaceRecorder.isRecorded(place, filmRollPlaces), isTrue);
    });

    test('TOUR_API 출처는 tourContentId를 externalPlaceId와 비교한다', () {
      final place = _place(tourContentId: 'tour-1', source: 'TOUR_API');
      final filmRollPlaces = [_filmRollPlace(externalPlaceId: 'tour-1')];

      expect(NearbyPlaceRecorder.isRecorded(place, filmRollPlaces), isTrue);
    });

    test('방문하지 않은 필름롤 장소는 매칭되어도 채록으로 보지 않는다', () {
      final place = _place(id: 42, source: 'TOUR_API');
      final filmRollPlaces = [
        _filmRollPlace(serverPlaceId: 42, isVisited: false),
      ];

      expect(NearbyPlaceRecorder.isRecorded(place, filmRollPlaces), isFalse);
    });

    test('일치하는 장소가 없으면 false를 반환한다', () {
      final place = _place(id: 1, source: 'TOUR_API');
      final filmRollPlaces = [_filmRollPlace(serverPlaceId: 2)];

      expect(NearbyPlaceRecorder.isRecorded(place, filmRollPlaces), isFalse);
    });

    test('place.id가 있으면 서버 ID로만 판정하고, externalId가 우연히 같아도 무시한다', () {
      final place = _place(id: 1, kakaoPlaceId: 'shared-ext', source: 'KAKAO');
      final filmRollPlaces = [
        _filmRollPlace(serverPlaceId: 2, externalPlaceId: 'shared-ext'),
      ];

      expect(NearbyPlaceRecorder.isRecorded(place, filmRollPlaces), isFalse);
    });
  });
}
