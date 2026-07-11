import 'dart:convert';

import 'package:chaerok/data/models/place_search_response.dart';
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
      "source": "TOUR_API"
    }
    ''')
            as Map<String, dynamic>;

    final result = PlaceSearchResponse.fromJson(json);

    expect(result.id, 1);
    expect(result.title, '경복궁');
    expect(result.latitude, 37.0);
    expect(result.longitude, 126.0);
    expect(result.categoryGroup, 'TOURISM');
    expect(result.categoryDetail, 'HERITAGE');
    expect(result.source, 'TOUR_API');
  });

  test('tourContentId/kakaoPlaceId/firstImageUrl이 없는 응답도 null로 처리한다', () {
    final json =
        jsonDecode('''
    {
      "id": 2,
      "title": "카카오 로컬 검색 결과",
      "address": "서울 마포구",
      "latitude": 37.5,
      "longitude": 126.9,
      "categoryGroup": "RESTAURANT",
      "categoryDetail": "KOREAN",
      "source": "KAKAO"
    }
    ''')
            as Map<String, dynamic>;

    final result = PlaceSearchResponse.fromJson(json);

    expect(result.tourContentId, isNull);
    expect(result.kakaoPlaceId, isNull);
    expect(result.firstImageUrl, isNull);
  });

  test('PlaceListResponse와 달리 isRepresentative 필드를 갖지 않는다', () {
    final json =
        jsonDecode('''
    {
      "id": 3,
      "title": "검색 결과",
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

    final result = PlaceSearchResponse.fromJson(json);

    expect(result.id, 3);
    expect(result.source, 'TOUR_API');
  });
}
