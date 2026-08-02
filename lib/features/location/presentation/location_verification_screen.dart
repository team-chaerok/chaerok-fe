import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/core/location/location_provider_factory.dart';
import 'package:chaerok/core/location/mock_location_provider.dart';
import 'package:chaerok/data/models/region_response.dart';
import 'package:chaerok/data/models/resolve_region_request.dart';
import 'package:chaerok/data/remote/places_api.dart';
import 'package:chaerok/data/remote/regions_api.dart';
import 'package:chaerok/features/location/data/kakao_local_api_service.dart';
import 'package:chaerok/features/location/data/location_permission_service.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

const _serviceProvinceName = '충청남도';

/// 디버그 빌드에서 서비스 지역 외 좌표로도 지역 검증 이후 흐름(관광지 조회 등)을
/// 테스트할 수 있도록 백엔드에 전달하는 지역명만 대체하는 값.
/// 실제 좌표(위도/경도)는 그대로 사용하므로 관광지 조회는 실제 위치 기준으로 동작한다.
const _debugFallbackProvinceName = '충청남도';
const _debugFallbackCityCountyName = '공주시';

enum _Step {
  checking,
  permissionDenied,
  permissionPermanentlyDenied,
  locationFailed,
  outOfServiceArea,
  regionVerificationFailed,
  placesFailed,
}

/// 위치 권한 확인 → 좌표 획득 → 행정구역 판별 → 서비스 지역 검증 → 관광지 조회를
/// 하나의 흐름으로 오케스트레이션하는 실제 위치 인증 화면.
/// 성공 시 [LocationVerificationResult]를 반환하며 `Navigator.pop`으로 닫힌다.
class LocationVerificationScreen extends StatefulWidget {
  const LocationVerificationScreen({super.key});

  @override
  State<LocationVerificationScreen> createState() =>
      _LocationVerificationScreenState();
}

class _LocationVerificationScreenState
    extends State<LocationVerificationScreen> {
  static const _tag = 'LocationVerificationScreen';

  _Step _step = _Step.checking;
  bool _isLocationServiceEnabled = true;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    setState(() => _step = _Step.checking);

    final cached = LocationVerificationResult.sessionCache;
    if (cached != null) {
      log('세션 캐시된 위치 인증 결과 재사용', name: _tag);
      if (!mounted) return;
      Navigator.of(context).pop(cached);
      return;
    }

    final locationProvider = await LocationProviderFactory.create();

    if (locationProvider is! MockLocationProvider) {
      var status = await LocationPermissionService.checkStatus();
      if (!status.isGranted) {
        status = await LocationPermissionService.requestPermission();
      }
      if (!mounted) return;

      if (status.isPermanentlyDenied) {
        setState(() => _step = _Step.permissionPermanentlyDenied);
        return;
      }
      if (!status.isGranted) {
        setState(() => _step = _Step.permissionDenied);
        return;
      }
    }

    final position = await locationProvider.getCurrentPosition();
    if (!mounted) return;
    if (position == null) {
      final serviceEnabled =
          await LocationPermissionService.isLocationServiceEnabled();
      if (!mounted) return;
      setState(() {
        _isLocationServiceEnabled = serviceEnabled;
        _step = _Step.locationFailed;
      });
      return;
    }

    final administrativeRegion =
        await KakaoLocalApiService.resolveAdministrativeRegion(
          latitude: position.latitude,
          longitude: position.longitude,
        );
    if (!mounted) return;
    if (administrativeRegion == null) {
      setState(() {
        _isLocationServiceEnabled = true;
        _step = _Step.locationFailed;
      });
      return;
    }

    final isOutOfServiceArea =
        administrativeRegion.provinceName != _serviceProvinceName;
    final useDebugFallbackRegion = kDebugMode && isOutOfServiceArea;
    if (isOutOfServiceArea && !useDebugFallbackRegion) {
      setState(() => _step = _Step.outOfServiceArea);
      return;
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
      if (!mounted) return;
      setState(() => _step = _Step.regionVerificationFailed);
      return;
    }
    if (!mounted) return;

    if (!region.serviceArea) {
      setState(() => _step = _Step.outOfServiceArea);
      return;
    }

    try {
      final places = await PlacesApi.getExternalPlaces(region.regionId);
      if (!mounted) return;

      final result = LocationVerificationResult(
        position: position,
        region: region,
        places: places,
      );
      LocationVerificationResult.sessionCache = result;
      Navigator.of(context).pop(result);
    } catch (e, st) {
      log('관광지 조회 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _step = _Step.placesFailed);
    }
  }

  Future<void> _onOpenSettingsTap() async {
    await LocationPermissionService.openSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text('위치 인증', style: ChaerokTypography.titleMedium),
      ),
      body: Padding(
        padding: const EdgeInsets.all(ChaerokSpacing.xxl),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return switch (_step) {
      _Step.checking => const Center(child: ChaerokLoadingIndicator()),
      _Step.permissionDenied => _buildInfoCard(
        title: '위치 권한이 필요해요',
        description:
            '충청남도 지역 판별과 주변 관광지 추천을 위해 위치 권한이 필요합니다.\n'
            '권한을 허용하지 않으면 현재 위치 기반 기능을 이용할 수 없어요.',
        buttonText: '위치 권한 다시 요청',
        onPressed: _run,
      ),
      _Step.permissionPermanentlyDenied => _buildInfoCard(
        title: '위치 권한이 거부되어 있어요',
        description: '설정 화면에서 위치 권한을 직접 허용해주세요.',
        buttonText: '설정에서 권한 허용하기',
        onPressed: _onOpenSettingsTap,
        secondaryButtonText: '다시 확인',
        onSecondaryPressed: _run,
      ),
      _Step.locationFailed => _buildInfoCard(
        title: '현재 위치를 확인할 수 없어요',
        description: _isLocationServiceEnabled
            ? '네트워크 연결 상태를 확인한 뒤 다시 시도해주세요.'
            : '기기의 위치 서비스(GPS)가 꺼져 있어요. 위치 서비스를 켠 뒤 다시 시도해주세요.',
        buttonText: '다시 시도',
        onPressed: _run,
      ),
      _Step.outOfServiceArea => _buildInfoCard(
        title: '서비스 지역이 아니에요',
        description:
            '채록은 현재 충청남도 지역에서만 이용할 수 있어요.\n'
            '충청남도 전용 기능은 이용이 제한됩니다.',
        buttonText: '메인으로 돌아가기',
        onPressed: () => Navigator.of(context).pop(),
      ),
      _Step.regionVerificationFailed => _buildInfoCard(
        title: '지역 정보를 확인하지 못했어요',
        description: '일시적인 서버 또는 네트워크 오류예요. 잠시 후 다시 시도해주세요.',
        buttonText: '다시 시도',
        onPressed: _run,
      ),
      _Step.placesFailed => _buildInfoCard(
        title: '관광지 정보를 불러오지 못했어요',
        description: '일시적인 서버 또는 네트워크 오류예요. 잠시 후 다시 시도해주세요.',
        buttonText: '다시 시도',
        onPressed: _run,
      ),
    };
  }

  Widget _buildInfoCard({
    required String title,
    required String description,
    required String buttonText,
    required FutureOr<void> Function() onPressed,
    String? secondaryButtonText,
    FutureOr<void> Function()? onSecondaryPressed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(ChaerokSpacing.lg),
          decoration: BoxDecoration(
            color: ChaerokColors.surface,
            borderRadius: BorderRadius.circular(ChaerokRadius.md),
            border: Border.all(color: ChaerokColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: ChaerokTypography.titleMedium),
              const SizedBox(height: ChaerokSpacing.xs),
              Text(
                description,
                style: ChaerokTypography.bodyMedium.copyWith(
                  color: ChaerokColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ChaerokSpacing.xl),
        ChaerokButton(text: buttonText, onPressed: () => onPressed()),
        if (secondaryButtonText != null && onSecondaryPressed != null) ...[
          const SizedBox(height: ChaerokSpacing.sm),
          TextButton(
            onPressed: () => onSecondaryPressed(),
            child: Text(secondaryButtonText),
          ),
        ],
      ],
    );
  }
}
