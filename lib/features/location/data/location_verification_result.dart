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

  /// Test Mode(QA) 패널에서 "충남 외 지역 홈 강제" 토글이나 mock 위치(지역/지점/
  /// 임의 좌표)를 바꿨을 때 세팅한다. 세팅 시 위 두 캐시는 함께 비워지고, 홈
  /// 대시보드는 다음 [HomeDashboardScreenState.refresh] 에서 자동 네비게이션 없이
  /// 위치 판정만 다시 수행한 뒤 이 플래그를 내린다.
  static bool qaLocationDirty = false;
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

/// 위치 인증 절차가 사용자 안내가 필요한 실패로 끝난 경우.
/// (서비스 지역 외는 안내가 아닌 별도 홈으로 가므로 [LocationOutOfService]로 구분한다.)
class LocationVerificationFailed extends LocationVerificationOutcome {
  const LocationVerificationFailed(
    this.reason, {
    this.isLocationServiceEnabled = true,
  });

  final LocationVerificationFailureReason reason;

  /// [LocationVerificationFailureReason.locationUnavailable] 안내에서 기기 위치
  /// 서비스(GPS)가 꺼져 있는지 여부에 따라 문구를 분기하기 위한 값. 그 외 사유에선 의미 없다.
  final bool isLocationServiceEnabled;
}

/// [LocationVerificationFailed]의 세부 사유. 위치 인증 화면의 안내 스텝과 1:1 대응한다.
enum LocationVerificationFailureReason {
  permissionDenied,
  permissionPermanentlyDenied,
  locationUnavailable,
  regionVerificationFailed,
  placesFailed,
}
