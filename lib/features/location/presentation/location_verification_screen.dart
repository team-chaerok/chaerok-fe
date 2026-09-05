import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/core/location/location_provider_factory.dart';
import 'package:chaerok/features/explore/presentation/widgets/explore_map_view.dart';
import 'package:chaerok/features/location/data/location_permission_service.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/features/location/data/location_verification_runner.dart';
import 'package:chaerok/features/location/presentation/widgets/location_verification_idle_view.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

enum _Step {
  /// 인증 전 기본 뷰(지도 미리보기 + 안내 + FAQ + CTA).
  idle,
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
/// 종료 시 [LocationVerificationOutcome]를 반환하며 `Navigator.pop`으로 닫힌다.
class LocationVerificationScreen extends StatefulWidget {
  const LocationVerificationScreen({
    super.key,
    this.initialFailure,
    @visibleForTesting this.debugInitialOutOfServiceArea = false,
  });

  /// 홈 진입 시 조용한 위치 확인([LocationVerificationRunner])이 실패해 이 화면으로
  /// 폴백할 때, 온보딩(idle) 뷰 대신 해당 안내 스텝을 바로 렌더하기 위한 값.
  final LocationVerificationFailed? initialFailure;

  /// 테스트에서 outOfServiceArea 스텝을 바로 렌더하기 위한 플래그.
  @visibleForTesting
  final bool debugInitialOutOfServiceArea;

  @override
  State<LocationVerificationScreen> createState() =>
      _LocationVerificationScreenState();
}

class _LocationVerificationScreenState
    extends State<LocationVerificationScreen> {
  static const _tag = 'LocationVerificationScreen';

  _Step _step = _Step.idle;
  bool _isLocationServiceEnabled = true;

  /// 카카오맵 네이티브 뷰는 첫 프레임 이후에 붙인다(탭 진입 전 지연 로드).
  bool _mapEnabled = false;

  /// 인증 전 지도 미리보기에 표시할 현재 좌표(best-effort). 권한이 없으면 null.
  Position? _previewPosition;
  bool _isReloadingPreview = false;

  /// 재조준 시 카메라를 다시 현재 위치로 옮기기 위한 포커스 마커. 매 재조회마다
  /// 새 id를 부여해 [ExploreMapView]가 카메라 이동을 다시 수행하도록 한다.
  ExploreMapMarker? _previewFocus;
  int _previewFocusTick = 0;

  @override
  void initState() {
    super.initState();
    if (widget.debugInitialOutOfServiceArea) {
      LocationVerificationResult.outOfServiceSessionCache = true;
      _step = _Step.outOfServiceArea;
    } else if (widget.initialFailure case final failure?) {
      _isLocationServiceEnabled = failure.isLocationServiceEnabled;
      _step = _stepForFailure(failure.reason);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mapEnabled = true);
    });
    unawaited(_loadPreviewPosition());
  }

  /// 인증 전 지도 미리보기에 쓸 현재 좌표를 조회한다. 권한 다이얼로그를 띄우지
  /// 않고, 실패해도 오류 화면 없이 지도만 비워둔다(인증은 CTA에서 시작).
  Future<void> _loadPreviewPosition() async {
    if (_isReloadingPreview) return;
    setState(() => _isReloadingPreview = true);
    try {
      final locationProvider = await LocationProviderFactory.create();
      final position = await locationProvider.getCurrentPosition();
      if (!mounted) return;
      if (position != null) {
        setState(() {
          _previewPosition = position;
          _previewFocus = ExploreMapMarker(
            id: 'preview-${++_previewFocusTick}',
            latitude: position.latitude,
            longitude: position.longitude,
            label: '',
            state: ExploreMarkerState.currentLocation,
          );
        });
      }
    } catch (e, st) {
      log('위치 미리보기 좌표 조회 실패', name: _tag, error: e, stackTrace: st);
    } finally {
      if (mounted) setState(() => _isReloadingPreview = false);
    }
  }

  Future<void> _run() async {
    setState(() => _step = _Step.checking);

    final outcome = await LocationVerificationRunner.run();
    if (!mounted) return;

    switch (outcome) {
      case LocationVerified(:final result):
        Navigator.of(context).pop(LocationVerified(result));
      case LocationOutOfService():
        setState(() => _step = _Step.outOfServiceArea);
      case LocationVerificationFailed(
        :final reason,
        :final isLocationServiceEnabled,
      ):
        setState(() {
          _isLocationServiceEnabled = isLocationServiceEnabled;
          _step = _stepForFailure(reason);
        });
    }
  }

  static _Step _stepForFailure(LocationVerificationFailureReason reason) {
    return switch (reason) {
      LocationVerificationFailureReason.permissionDenied =>
        _Step.permissionDenied,
      LocationVerificationFailureReason.permissionPermanentlyDenied =>
        _Step.permissionPermanentlyDenied,
      LocationVerificationFailureReason.locationUnavailable =>
        _Step.locationFailed,
      LocationVerificationFailureReason.regionVerificationFailed =>
        _Step.regionVerificationFailed,
      LocationVerificationFailureReason.placesFailed => _Step.placesFailed,
    };
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
      body: _step == _Step.idle
          ? LocationVerificationIdleView(
              mapPreview: _buildMapPreview(),
              isReloading: _isReloadingPreview,
              onVerifyTap: () => unawaited(_run()),
              onReloadTap: () => unawaited(_loadPreviewPosition()),
            )
          : Padding(
              padding: const EdgeInsets.all(ChaerokSpacing.xxl),
              child: _buildContent(),
            ),
    );
  }

  /// 인증 전 상단 지도 미리보기: 현재 좌표에 고정된 원형 도트 마커 + 우하단
  /// 재조준 버튼. 마커는 지도 좌표에 묶여 있어, 지도를 움직여도 실제 위치를
  /// 계속 가리킨다.
  Widget _buildMapPreview() {
    final position = _previewPosition;
    return Stack(
      children: [
        Positioned.fill(
          child: ExploreMapView(
            markers: position == null
                ? const []
                : [
                    ExploreMapMarker(
                      id: 'current-location',
                      latitude: position.latitude,
                      longitude: position.longitude,
                      label: '',
                      state: ExploreMarkerState.currentLocation,
                    ),
                  ],
            focus: _previewFocus,
            enabled: _mapEnabled,
          ),
        ),
        Positioned(
          right: ChaerokSpacing.md,
          bottom: ChaerokSpacing.md,
          child: _RecenterButton(
            onTap: () => unawaited(_loadPreviewPosition()),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    return switch (_step) {
      _Step.idle => const SizedBox.shrink(),
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
            '채록의 필름롤은 현재 충청남도 지역에서만 시작할 수 있어요.\n'
            '대신 공주·부여·서산·예산을 지역별로 둘러볼 수 있어요.',
        buttonText: '지역별로 둘러보기',
        onPressed: () =>
            Navigator.of(context).pop(const LocationOutOfService()),
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

/// 지도 미리보기 우하단의 "현재 위치로 이동(재조준)" 버튼.
class _RecenterButton extends StatelessWidget {
  const _RecenterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChaerokColors.background,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            Icons.my_location_rounded,
            color: ChaerokColors.primaryDark,
            size: 22,
          ),
        ),
      ),
    );
  }
}
