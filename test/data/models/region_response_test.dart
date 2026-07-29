import 'dart:convert';

import 'package:chaerok/data/models/region_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('서비스 지역인 경우(Swagger 예시 응답)를 정상 파싱한다', () {
    final json =
        jsonDecode('''
    {
      "serviceArea": true,
      "regionId": 1,
      "provinceName": "충청남도",
      "cityCountyName": "천안시"
    }
    ''')
            as Map<String, dynamic>;

    final result = RegionResponse.fromJson(json);

    expect(result.serviceArea, true);
    expect(result.regionId, 1);
    expect(result.provinceName, '충청남도');
    expect(result.cityCountyName, '천안시');
  });

  test('서비스 지역이 아닌 경우도 정상 파싱한다', () {
    final json =
        jsonDecode('''
    {
      "serviceArea": false,
      "regionId": 0,
      "provinceName": "서울특별시",
      "cityCountyName": "종로구"
    }
    ''')
            as Map<String, dynamic>;

    final result = RegionResponse.fromJson(json);

    expect(result.serviceArea, false);
    expect(result.provinceName, '서울특별시');
  });

  test('필수 필드(serviceArea)가 없으면 예외를 던진다', () {
    final json =
        jsonDecode('''
    {
      "regionId": 1,
      "provinceName": "충청남도",
      "cityCountyName": "천안시"
    }
    ''')
            as Map<String, dynamic>;

    expect(() => RegionResponse.fromJson(json), throwsA(isA<TypeError>()));
  });
}
