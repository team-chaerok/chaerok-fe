import 'dart:convert';

import 'package:chaerok/data/models/place_detail_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Swagger 예시 응답을 정상 파싱한다', () {
    final json =
        jsonDecode('''
    {
      "id": 1,
      "regionId": 10,
      "tourContentId": "126508",
      "kakaoPlaceId": "27336425",
      "title": "경복궁",
      "address": "서울 종로구 사직로 161",
      "latitude": 37,
      "longitude": 126,
      "firstImageUrl": "https://example.com/image.jpg",
      "overview": "조선 왕조의 법궁",
      "lDongRegnCd": "11",
      "lDongSignguCd": "110",
      "lclsSystm1": "AA",
      "lclsSystm2": "AA01",
      "lclsSystm3": "AA0101",
      "categoryGroup": "TOURISM",
      "categoryDetail": "HERITAGE",
      "isRepresentative": true,
      "source": "TOUR_API"
    }
    ''')
            as Map<String, dynamic>;

    final result = PlaceDetailResponse.fromJson(json);

    expect(result.id, 1);
    expect(result.regionId, 10);
    expect(result.latitude, 37.0);
    expect(result.longitude, 126.0);
    expect(result.overview, '조선 왕조의 법궁');
    expect(result.lDongRegnCd, '11');
    expect(result.lDongSignguCd, '110');
    expect(result.lclsSystm1, 'AA');
    expect(result.lclsSystm2, 'AA01');
    expect(result.lclsSystm3, 'AA0101');
    expect(result.categoryGroup, 'TOURISM');
    expect(result.isRepresentative, true);
    expect(result.source, 'TOUR_API');
  });

  test('overview/lDong*/lclsSystm* 등 nullable 필드가 없는 응답도 null로 처리한다', () {
    final json =
        jsonDecode('''
    {
      "id": 2,
      "regionId": 11,
      "title": "카카오 등록 장소",
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

    final result = PlaceDetailResponse.fromJson(json);

    expect(result.overview, isNull);
    expect(result.lDongRegnCd, isNull);
    expect(result.lDongSignguCd, isNull);
    expect(result.lclsSystm1, isNull);
    expect(result.lclsSystm2, isNull);
    expect(result.lclsSystm3, isNull);
  });

  test('empty()는 안전한 기본값을 반환한다', () {
    final result = PlaceDetailResponse.empty();

    expect(result.id, 0);
    expect(result.regionId, 0);
    expect(result.title, '');
    expect(result.address, '');
    expect(result.latitude, 0);
    expect(result.longitude, 0);
    expect(result.categoryGroup, '');
    expect(result.categoryDetail, '');
    expect(result.isRepresentative, false);
    expect(result.source, '');
    expect(result.tourContentId, isNull);
    expect(result.overview, isNull);
  });
}
