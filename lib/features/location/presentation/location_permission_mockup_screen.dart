import 'dart:async';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/location/data/location_permission_service.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// 실제 디자인 확정 전, 위치 권한 요청 → 승인/거부/영구거부 흐름을 검증하기 위한 Mockup 화면.
/// 디자인이 확정되면 실제 화면으로 교체되어야 한다.
class LocationPermissionMockupScreen extends StatefulWidget {
  const LocationPermissionMockupScreen({super.key});

  @override
  State<LocationPermissionMockupScreen> createState() =>
      _LocationPermissionMockupScreenState();
}

class _LocationPermissionMockupScreenState
    extends State<LocationPermissionMockupScreen> {
  PermissionStatus? _status;
  Position? _position;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    unawaited(_refreshStatus());
  }

  Future<void> _refreshStatus() async {
    setState(() => _isChecking = true);

    final status = await LocationPermissionService.checkStatus();
    final position = status.isGranted
        ? await LocationPermissionService.getCurrentPosition()
        : null;

    if (!mounted) return;
    setState(() {
      _status = status;
      _position = position;
      _isChecking = false;
    });
  }

  Future<void> _onRequestTap() async {
    setState(() => _isChecking = true);
    await LocationPermissionService.requestPermission();
    if (!mounted) return;
    await _refreshStatus();
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
        title: const Text(
          '위치 인증 (Mockup)',
          style: ChaerokTypography.titleMedium,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(ChaerokSpacing.xxl),
        child: _isChecking
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final status = _status ?? PermissionStatus.denied;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatusCard(status),
        const SizedBox(height: ChaerokSpacing.xl),
        if (status.isPermanentlyDenied)
          ChaerokButton(text: '설정에서 권한 허용하기', onPressed: _onOpenSettingsTap)
        else if (!status.isGranted)
          ChaerokButton(text: '위치 권한 요청', onPressed: _onRequestTap)
        else
          ChaerokButton(text: '다시 확인', onPressed: _refreshStatus),
      ],
    );
  }

  Widget _buildStatusCard(PermissionStatus status) {
    return Container(
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
          const Text('권한 상태', style: ChaerokTypography.labelLarge),
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(_statusLabel(status), style: ChaerokTypography.bodyMedium),
          if (_position != null) ...[
            const SizedBox(height: ChaerokSpacing.md),
            const Text('현재 좌표', style: ChaerokTypography.labelLarge),
            const SizedBox(height: ChaerokSpacing.xxs),
            Text(
              'lat: ${_position!.latitude}, lng: ${_position!.longitude}',
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _statusLabel(PermissionStatus status) {
    if (status.isGranted) return '승인됨';
    if (status.isPermanentlyDenied) return '영구 거부됨 (설정에서 직접 허용 필요)';
    if (status.isDenied) return '거부됨 (재요청 가능)';
    if (status.isRestricted) return '제한됨 (기기 정책)';
    return status.toString();
  }
}
