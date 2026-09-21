import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('지역별 필름 타입 라벨을 반환한다', () {
    expect(RegionCode.gongju.filmTypeLabel, '공주:공주의 잔(殘)');
    expect(RegionCode.buyeo.filmTypeLabel, '부여:백제의 연(戀)');
    expect(RegionCode.seosan.filmTypeLabel, '서산:서산의 낙(落)');
    expect(RegionCode.yesan.filmTypeLabel, '예산:윤(潤)');
  });
}
