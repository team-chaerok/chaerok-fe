import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/o_auth_login_request.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/data/models/user_response.dart';
import 'package:chaerok/data/remote/users_api.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/features/settings/presentation/settings_screen.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift_db_viewer/drift_db_viewer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 마이 탭: 프로필 요약, 설정 진입점, 그리고(디버그 빌드에서만) 테스트용
/// 목업 위치/로컬 DB 도구를 모아 보여준다. 목업 위치·DB 뷰어는 원래
/// `home_screen.dart`(구 홈 화면)에 있던 디버그 카드를 그대로 이식한 것이다.
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  static const _tag = 'MyScreen';

  UserResponse? _user;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isMockLocationEnabled = false;
  RegionCode _mockRegionCode = RegionCode.gongju;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchUserInfo());
    if (kDebugMode) {
      unawaited(_loadMockLocationSettings());
    }
  }

  Future<void> _fetchUserInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await UsersApi.getMyInformation();
      if (!mounted) return;
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e, st) {
      log('내 정보 조회 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _errorMessage = apiErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _onSettingsTap() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    if (!mounted) return;
    await _fetchUserInfo();
  }

  Future<void> _loadMockLocationSettings() async {
    final preferences = AppPreferences.instance;
    final isEnabled = await preferences.isMockLocationEnabled();
    final regionCodeName = await preferences.getMockRegionCodeName();
    if (!mounted) return;
    setState(() {
      _isMockLocationEnabled = isEnabled;
      _mockRegionCode = RegionCode.values.firstWhere(
        (region) => region.name == regionCodeName,
        orElse: () => RegionCode.gongju,
      );
    });
  }

  Future<void> _onMockLocationEnabledChanged(bool enabled) async {
    setState(() => _isMockLocationEnabled = enabled);
    await AppPreferences.instance.setMockLocationEnabled(enabled);
  }

  Future<void> _onMockRegionCodeChanged(RegionCode? regionCode) async {
    if (regionCode == null) return;
    setState(() => _mockRegionCode = regionCode);
    await AppPreferences.instance.setMockRegionCodeName(regionCode.name);
  }

  /// 로컬 DB(필름롤/장소/사진 테이블)를 표로 직접 조회할 수 있는 뷰어를 연다.
  Future<void> _onOpenDbViewerTap() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => DriftDbViewer(AppDatabase.instance)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationResult = LocationVerificationResult.sessionCache;

    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text('마이', style: ChaerokTypography.titleMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ChaerokSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserCard(),
            const SizedBox(height: ChaerokSpacing.md),
            _buildCardContainer(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('설정', style: ChaerokTypography.bodyLarge),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _onSettingsTap,
              ),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: ChaerokSpacing.md),
              _buildMockLocationDebugCard(),
            ],
            if (kDebugMode && locationResult != null) ...[
              const SizedBox(height: ChaerokSpacing.md),
              _buildLocationDebugCard(locationResult),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(ChaerokSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return _buildCardContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _errorMessage!,
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.error,
              ),
            ),
            const SizedBox(height: ChaerokSpacing.sm),
            TextButton(onPressed: _fetchUserInfo, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final user = _user!;
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(user.nickname, style: ChaerokTypography.titleMedium),
          if (user.email != null) ...[
            const SizedBox(height: ChaerokSpacing.xxs),
            Text(
              user.email!,
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(
            _providerLabel(user.provider),
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  String _providerLabel(OAuthProvider provider) {
    switch (provider) {
      case OAuthProvider.kakao:
        return '카카오';
      case OAuthProvider.google:
        return '구글';
      case OAuthProvider.apple:
        return 'Apple';
    }
  }

  /// 개발용 mock 위치 설정 (QA 검증용, 릴리즈 빌드에서는 노출되지 않음).
  Widget _buildMockLocationDebugCard() {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Mock 위치 (디버그)', style: ChaerokTypography.bodyMedium),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(
              'Mock 위치 사용',
              style: ChaerokTypography.bodyMedium,
            ),
            value: _isMockLocationEnabled,
            onChanged: _onMockLocationEnabledChanged,
          ),
          if (_isMockLocationEnabled)
            DropdownButton<RegionCode>(
              value: _mockRegionCode,
              isExpanded: true,
              items: RegionCode.values
                  .map(
                    (region) => DropdownMenuItem(
                      value: region,
                      child: Text(region.filmRollTitle),
                    ),
                  )
                  .toList(),
              onChanged: _onMockRegionCodeChanged,
            ),
          const SizedBox(height: ChaerokSpacing.sm),
          TextButton(
            onPressed: _onOpenDbViewerTap,
            child: const Text('로컬 DB 확인하기'),
          ),
        ],
      ),
    );
  }

  /// 위치 인증 결과 디버그 표시 (QA 검증용, 릴리즈 빌드에서는 노출되지 않음).
  Widget _buildLocationDebugCard(LocationVerificationResult result) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('위치 인증 결과 (디버그)', style: ChaerokTypography.bodyMedium),
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(
            '${result.region.provinceName} ${result.region.cityCountyName} '
            '(regionId: ${result.region.regionId})',
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          Text(
            '주변 관광지 ${result.places.length}건',
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.xs),
          ...result.places.map(_buildPlaceTile),
        ],
      ),
    );
  }

  Widget _buildPlaceTile(PlaceListResponse place) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(place.title, style: ChaerokTypography.bodyMedium),
      subtitle: Text(
        place.address,
        style: ChaerokTypography.caption.copyWith(
          color: ChaerokColors.textSecondary,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${place.categoryGroup} · ${place.categoryDetail}\n'
            '출처: ${place.source}\n'
            '좌표: ${place.latitude}, ${place.longitude}',
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChaerokSpacing.lg),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
        border: Border.all(color: ChaerokColors.border),
      ),
      child: child,
    );
  }
}
