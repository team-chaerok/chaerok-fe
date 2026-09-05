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

  /// 이번 세션에서 위치 인증이 "서비스 지역 외"로 끝났는지 여부.
  /// 홈 탭 재진입 시 인증 흐름을 다시 타지 않기 위한 캐시.
  static bool outOfServiceSessionCache = false;
}

/// 위치 인증 화면의 종료 결과.
sealed class LocationVerificationOutcome {
  const LocationVerificationOutcome();
}

/// 인증 성공 — 서비스 지역(충남) 내부.
class LocationVerified extends LocationVerificationOutcome {
  const LocationVerified(this.result);
  final LocationVerificationResult result;
}

/// 서비스 지역 외 — 지역별 둘러보기(충남 외 지역 홈)로 진입한다.
/// 시·도 판별 단계에서 끊기므로 regionId 등 payload는 없다.
class LocationOutOfService extends LocationVerificationOutcome {
  const LocationOutOfService();
}
