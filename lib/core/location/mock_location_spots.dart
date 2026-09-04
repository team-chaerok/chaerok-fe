import 'package:chaerok/shared/region/region_code.dart';

/// 개발/QA용 mock 위치 지점 하나. [label]은 QA 화면 선택지에 그대로 노출된다.
typedef MockLocationSpot = ({String label, double latitude, double longitude});

/// mock 위치가 반환하는 GPS 정확도(m). `evaluateVisitGate`의 정확도 게이트
/// (`kVisitMinGpsAccuracyMeters` = 50m)를 실제처럼 통과하되 우회하지 않도록,
/// 0이 아닌 현실적인 값(50m 미만, 경계 여유 포함)을 쓴다.
const double kMockGpsAccuracyMeters = 12;

/// 지역별 mock 위치 지점 세트. Play 심사(테스트 계정)에서 실제 이동 없이
/// 코스의 여러 스팟(각 100m 이내)을 순차 인증하기 위한 좌표다.
///
/// 방문 성공을 강제하지 않고 좌표만 바꿔 실제 `evaluateVisitGate`
/// (100m 거리 + 50m 정확도)를 그대로 통과시킨다.
///
/// ⚠️ 확인 필요: 아래 좌표는 각 지역 대표 관광지 기준의 **후보값**이다.
/// 방문 인증 대상은 `CoursesApi.getRecommendedCourses`가 내려준
/// `CourseResponse.places`(선택 시 `FilmRollPlace`로 저장)의 좌표이므로,
/// 병합 전 반드시 그 좌표와 `Geolocator.distanceBetween`으로 대조해
/// `kVisitVerifiableRadiusMeters`(100m, 권장 60m) 이내인지 확인하고, 어긋나면
/// 코스 스팟 좌표에 맞춰 조정한다. 코스 데이터가 개편되면 대조를 다시 한다.
const Map<RegionCode, List<MockLocationSpot>> mockLocationSpots = {
  RegionCode.gongju: [
    (label: '공산성 금서루', latitude: 36.46574, longitude: 127.12376),
    (label: '무령왕릉과 왕릉원', latitude: 36.45949, longitude: 127.11447),
    (label: '국립공주박물관', latitude: 36.46312, longitude: 127.11832),
    (label: '공주 산성시장', latitude: 36.45153, longitude: 127.11923),
  ],
  RegionCode.buyeo: [
    (label: '부소산성', latitude: 36.28468, longitude: 126.91208),
    (label: '정림사지', latitude: 36.27906, longitude: 126.91215),
    (label: '궁남지', latitude: 36.26861, longitude: 126.90945),
    (label: '국립부여박물관', latitude: 36.27540, longitude: 126.92053),
  ],
  RegionCode.seosan: [
    (label: '해미읍성', latitude: 36.70527, longitude: 126.54968),
    (label: '서산 용현리 마애여래삼존상', latitude: 36.77935, longitude: 126.55836),
    (label: '개심사', latitude: 36.73676, longitude: 126.53052),
    (label: '간월암', latitude: 36.64834, longitude: 126.35201),
  ],
  RegionCode.yesan: [
    (label: '수덕사', latitude: 36.66313, longitude: 126.61826),
    (label: '예당호 출렁다리', latitude: 36.67873, longitude: 126.76604),
    (label: '윤봉길 의사 사적지(충의사)', latitude: 36.60318, longitude: 126.85606),
    (label: '예산상설시장', latitude: 36.68053, longitude: 126.84490),
  ],
};
