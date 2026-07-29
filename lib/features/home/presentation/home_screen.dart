import 'dart:async';
import 'dart:developer';

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
import 'package:chaerok/features/location/presentation/location_verification_screen.dart';
import 'package:chaerok/features/settings/presentation/settings_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _tag = 'HomeScreen';

  UserResponse? _user;
  bool _isLoading = true;
  String? _errorMessage;
  LocationVerificationResult? _locationResult;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchUserInfo());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_ensureLocationVerified());
    });
  }

  /// 위치 인증(권한 확인 → 좌표 획득 → 지역 판별 → 관광지 조회)이 이번 세션에
  /// 아직 완료되지 않았다면 위치 인증 화면을 진입시킨다.
  /// 조회된 지역·관광지 정보를 지도/코스 추천/방문 인증 기능으로 전달하는 것은
  /// 이번 작업 범위 밖이며, 여기서는 상태 보관까지만 담당한다.
  Future<void> _ensureLocationVerified() async {
    final cached = LocationVerificationResult.sessionCache;
    if (cached != null) {
      setState(() => _locationResult = cached);
      return;
    }

    final result = await Navigator.of(context).push<LocationVerificationResult>(
      MaterialPageRoute(builder: (_) => const LocationVerificationScreen()),
    );
    if (!mounted) return;
    setState(() => _locationResult = result);
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

  Future<void> _onSettingsTap(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
    if (!mounted) return;
    await _fetchUserInfo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text('홈', style: ChaerokTypography.titleMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _onSettingsTap(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(ChaerokSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildUserCard(),
            if (kDebugMode && _locationResult != null) ...[
              const SizedBox(height: ChaerokSpacing.md),
              _buildLocationDebugCard(_locationResult!),
            ],
          ],
        ),
      ),
    );
  }

  /// 위치 인증 결과 디버그 표시 (QA 검증용, 릴리즈 빌드에서는 노출되지 않음).
  Widget _buildLocationDebugCard(LocationVerificationResult result) {
    return _buildCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('위치 인증 결과 (디버그)', style: ChaerokTypography.labelLarge),
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
    }
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
