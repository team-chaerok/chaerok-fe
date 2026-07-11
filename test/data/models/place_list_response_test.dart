import 'dart:convert';

import 'package:chaerok/data/models/place_list_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Swagger 예시 응답을 정상 파싱한다', () {
    final json =
        jsonDecode('''
    {
      "id": 1,
      "tourContentId": "126508",
      "kakaoPlaceId": "27336425",
      "title": "경복궁",
      "address": "서울 종로구 사직로 161",
      "latitude": 37,
      "longitude": 126,
      "firstImageUrl": "https://example.com/image.jpg",
      "categoryGroup": "TOURISM",
      "categoryDetail": "HERITAGE",
      "isRepresentative": true,
      "source": "TOUR_API"
    }
    ''')
            as Map<String, dynamic>;

    final result = PlaceListResponse.fromJson(json);

    expect(result.id, 1);
    expect(result.tourContentId, '126508');
    expect(result.kakaoPlaceId, '27336425');
    expect(result.title, '경복궁');
    expect(result.address, '서울 종로구 사직로 161');
    expect(result.latitude, 37.0);
    expect(result.longitude, 126.0);
    expect(result.firstImageUrl, 'https://example.com/image.jpg');
    expect(result.categoryGroup, 'TOURISM');
    expect(result.categoryDetail, 'HERITAGE');
    expect(result.isRepresentative, true);
    expect(result.source, 'TOUR_API');
  });

  test('tourContentId/kakaoPlaceId/firstImageUrl이 없는 응답도 null로 처리한다', () {
    final json =
        jsonDecode('''
    {
      "id": 2,
      "title": "카카오맵 등록 카페",
      "address": "서울 마포구",
      "latitude": 37.5,
      "longitude": 126.9,
      "categoryGroup": "CAFE",
      "categoryDetail": "DESSERT",
      "isRepresentative": false,
      "source": "KAKAO"
    }
    ''')
            as Map<String, dynamic>;

    final result = PlaceListResponse.fromJson(json);

    expect(result.tourContentId, isNull);
    expect(result.kakaoPlaceId, isNull);
    expect(result.firstImageUrl, isNull);
    expect(result.isRepresentative, false);
  });

  test('필수 필드(title)가 없으면 예외를 던진다', () {
    final json =
        jsonDecode('''
    {
      "id": 3,
      "address": "서울",
      "latitude": 37.5,
      "longitude": 126.9,
      "categoryGroup": "TOURISM",
      "categoryDetail": "HERITAGE",
      "isRepresentative": true,
      "source": "TOUR_API"
    }
    ''')
            as Map<String, dynamic>;

    expect(() => PlaceListResponse.fromJson(json), throwsA(isA<TypeError>()));
  });
}
