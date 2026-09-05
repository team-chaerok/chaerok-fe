import 'dart:developer';

import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/location/location_provider_factory.dart';
import 'package:chaerok/core/location/mock_location_gate.dart';
import 'package:chaerok/core/location/mock_location_provider.dart';
import 'package:chaerok/data/models/region_response.dart';
import 'package:chaerok/data/models/resolve_region_request.dart';
import 'package:chaerok/data/remote/places_api.dart';
import 'package:chaerok/data/remote/regions_api.dart';
import 'package:chaerok/features/location/data/kakao_local_api_service.dart';
import 'package:chaerok/features/location/data/location_permission_service.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

const _serviceProvinceName = '충청남도';

/// 디버그 빌드에서 서비스 지역 외 좌표로도 지역 검증 이후 흐름(관광지 조회 등)을
/// 테스트할 수 있도록 백엔드에 전달하는 지역명만 대체하는 값.
/// 실제 좌표(위도/경도)는 그대로 사용하므로 관광지 조회는 실제 위치 기준으로 동작한다.
///
/// 반대로 "충남 외 지역 홈"([OutOfServiceHomeView]) 자체를 확인하려면 마이 탭의
/// "충남 외 지역 홈 강제 (QA)" 스위치([AppPreferences.isDebugOutOfServiceArea])를
/// 켠다 — 이 대체가 비활성화되고 실제 서비스 지역 외 경로가 실행된다.
const _debugFallbackProvinceName = '충청남도';
const _debugFallbackCityCountyName = '공주시';

/// 위치 권한 확인 → 좌표 획득 → 행정구역 판별 → 서비스 지역 검증 → 관광지 조회를
/// 하나의 흐름으로 오케스트레이션하는 UI 없는 러너.
///
/// 회원가입 직후의 [LocationVerificationScreen]과 기존 회원의 홈 진입 시 조용한
/// 위치 확인이 이 러너를 공유해, 결과([LocationVerificationResult.sessionCache])와
/// 부작용([LocationVerificationResult.outOfServiceSessionCache]), mock/디버그
/// 분기가 두 경로에서 어긋나지 않게 한다.
class LocationVerificationRunner {
  const LocationVerificationRunner._();

  static const _tag = 'LocationVerificationRunner';

  /// 위치 인증 절차를 수행하고 [LocationVerificationOutcome]을 반환한다.
  ///
  /// [requestPermissionIfNeeded]가 false면 권한이 없을 때 OS 권한 다이얼로그를
  /// 띄우지 않고 즉시 [LocationVerificationFailureReason.permissionDenied]로 끝낸다.
  static Future<LocationVerificationOutcome> run({
    bool requestPermissionIfNeeded = true,
  }) async {
    final cached = LocationVerificationResult.sessionCache;
    if (cached != null) {
      log('세션 캐시된 위치 인증 결과 재사용', name: _tag);
      return LocationVerified(cached);
    }

    final locationProvider = await LocationProviderFactory.create();

    if (locationProvider is! MockLocationProvider) {
      var status = await LocationPermissionService.checkStatus();
      if (!status.isGranted && requestPermissionIfNeeded) {
        status = await LocationPermissionService.requestPermission();
      }

      if (status.isPermanentlyDenied) {
        return const LocationVerificationFailed(
          LocationVerificationFailureReason.permissionPermanentlyDenied,
        );
      }
      if (!status.isGranted) {
        return const LocationVerificationFailed(
          LocationVerificationFailureReason.permissionDenied,
        );
      }
    }

    final position = await locationProvider.getCurrentPosition();
    if (position == null) {
      final serviceEnabled =
          await LocationPermissionService.isLocationServiceEnabled();
      return LocationVerificationFailed(
        LocationVerificationFailureReason.locationUnavailable,
        isLocationServiceEnabled: serviceEnabled,
      );
    }

    final administrativeRegion =
        await KakaoLocalApiService.resolveAdministrativeRegion(
          latitude: position.latitude,
          longitude: position.longitude,
        );
    if (administrativeRegion == null) {
      return const LocationVerificationFailed(
        LocationVerificationFailureReason.locationUnavailable,
      );
    }

    // QA 토글: 마이 탭에서 "충남 외 지역 홈 강제"를 켜면 실제 좌표와 무관하게
    // 서비스 지역 외로 판정하고, 아래 디버그 지역 대체도 건너뛴다.
    final forceOutOfServiceArea =
        await MockLocationGate.isAllowed() &&
        await AppPreferences.instance.isDebugOutOfServiceArea();

    final isOutOfServiceArea =
        forceOutOfServiceArea ||
        administrativeRegion.provinceName != _serviceProvinceName;
    final useDebugFallbackRegion =
        kDebugMode && isOutOfServiceArea && !forceOutOfServiceArea;
    if (isOutOfServiceArea && !useDebugFallbackRegion) {
      LocationVerificationResult.outOfServiceSessionCache = true;
      return const LocationOutOfService();
    }
    if (useDebugFallbackRegion) {
      log(
        '디버그 모드 - 서비스 지역 외 좌표를 테스트 지역'
        '($_debugFallbackProvinceName $_debugFallbackCityCountyName)으로 대체',
        name: _tag,
      );
    }

    final RegionResponse region;
    try {
      region = await RegionsApi.resolveRegion(
        ResolveRegionRequest(
          provinceName: useDebugFallbackRegion
              ? _debugFallbackProvinceName
              : administrativeRegion.provinceName,
          cityCountyName: useDebugFallbackRegion
              ? _debugFallbackCityCountyName
              : administrativeRegion.cityCountyName,
        ),
      );
    } catch (e, st) {
      log('지역 검증 실패', name: _tag, error: e, stackTrace: st);
      return const LocationVerificationFailed(
        LocationVerificationFailureReason.regionVerificationFailed,
      );
    }

    if (!region.serviceArea) {
      LocationVerificationResult.outOfServiceSessionCache = true;
      return const LocationOutOfService();
    }

    try {
      final places = await PlacesApi.getExternalPlaces(region.regionId);
      final result = LocationVerificationResult(
        position: position,
        region: region,
        places: places,
      );
      LocationVerificationResult.sessionCache = result;
      return LocationVerified(result);
    } catch (e, st) {
      log('관광지 조회 실패', name: _tag, error: e, stackTrace: st);
      return const LocationVerificationFailed(
        LocationVerificationFailureReason.placesFailed,
      );
    }
  }
}
