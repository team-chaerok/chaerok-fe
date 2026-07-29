import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/data/models/region_response.dart';
import 'package:geolocator/geolocator.dart';

/// 위치 인증 플로우(권한 확인 → 좌표 획득 → 지역 판별 → 관광지 조회) 성공 결과.
class LocationVerificationResult {
  const LocationVerificationResult({
    required this.position,
    required this.region,
    required this.places,
  });

  final Position position;
  final RegionResponse region;
  final List<PlaceListResponse> places;

  /// 이번 앱 세션에서 마지막으로 성공한 위치 인증 결과.
  /// 세션 내 재진입 시 불필요한 재검증(Kakao/백엔드 재호출)을 피하기 위해 캐싱한다.
  static LocationVerificationResult? sessionCache;
}
