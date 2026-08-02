import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/user_response.dart';
import 'package:chaerok/data/remote/users_api.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_screen.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/active_film_roll_card.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/features/location/presentation/location_verification_screen.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:flutter/material.dart';

/// 홈 탭: 현재 지역, 진행중 필름롤 진행률을 요약해 다음 행동(재개/시작)으로
/// 이끄는 상태 요약 대시보드. `home_screen.dart`(구 홈 화면)의 사용자 조회 ·
/// 위치 인증 게이트 · 필름롤 진입/재개 로직을 이식했다.
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  static const _tag = 'HomeDashboardScreen';

  UserResponse? _user;
  LocationVerificationResult? _locationResult;
  FilmRoll? _recoveredFilmRoll;
  bool _isEnteringFilmRoll = false;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchUserInfo());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_ensureLocationVerified());
    });
    unawaited(_loadRecoveredFilmRoll());
  }

  Future<void> _fetchUserInfo() async {
    try {
      final user = await UsersApi.getMyInformation();
      if (!mounted) return;
      setState(() => _user = user);
    } catch (e, st) {
      log('내 정보 조회 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  /// 위치 인증(권한 확인 → 좌표 획득 → 지역 판별 → 관광지 조회)이 이번 세션에
  /// 아직 완료되지 않았다면 위치 인증 화면을 진입시킨다.
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

  /// 앱 재시작 시 진행중이던 필름롤이 있다면 복구해 "이어하기"로 노출한다.
  Future<void> _loadRecoveredFilmRoll() async {
    try {
      final recovered = await FilmRollModule.instance
          .recoverLastActiveFilmRoll();
      if (!mounted) return;
      setState(() => _recoveredFilmRoll = recovered);
    } catch (e, st) {
      log('필름롤 복구 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> _onResumeFilmRollTap() async {
    final recovered = _recoveredFilmRoll;
    if (recovered == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FilmRollScreen(filmRollId: recovered.id),
      ),
    );
    if (!mounted) return;
    await _loadRecoveredFilmRoll();
  }

  /// 위치 인증으로 확인된 지역에 대한 로컬 필름롤을 찾거나 새로 생성해 진입한다.
  Future<void> _onStartFilmRollTap() async {
    final locationResult = _locationResult;
    if (locationResult == null || _isEnteringFilmRoll) return;

    setState(() => _isEnteringFilmRoll = true);
    try {
      final filmRoll = await FilmRollModule.instance.enterRegion(
        locationResult.region.cityCountyName,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FilmRollScreen(
            filmRollId: filmRoll.id,
            regionId: locationResult.region.regionId,
          ),
        ),
      );
      if (!mounted) return;
      await _loadRecoveredFilmRoll();
    } on UnsupportedRegionException {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아직 필름롤을 지원하지 않는 지역이에요.')));
    } catch (e, st) {
      log('필름롤 진입 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('필름롤을 불러오지 못했어요.')));
    } finally {
      if (mounted) setState(() => _isEnteringFilmRoll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ChaerokSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HomeHeader(
                userNickname: _user?.nickname,
                regionName: _locationResult?.region.cityCountyName,
              ),
              const SizedBox(height: ChaerokSpacing.lg),
              if (_recoveredFilmRoll != null)
                GestureDetector(
                  onTap: _onResumeFilmRollTap,
                  child: ActiveFilmRollCard(
                    data: FilmRollSummaryData(
                      name: _recoveredFilmRoll!.title,
                      capturedCount: _recoveredFilmRoll!.visitedPlaceCount,
                      totalCount: _recoveredFilmRoll!.totalPlaceCount,
                    ),
                  ),
                )
              else
                _buildStartFilmRollCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStartFilmRollCard() {
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
          const Text('필름롤', style: ChaerokTypography.labelLarge),
          const SizedBox(height: ChaerokSpacing.xs),
          Text(
            _locationResult != null
                ? '${_locationResult!.region.cityCountyName}에서 필름롤을 시작해보세요.'
                : '위치 인증이 완료되면 필름롤을 시작할 수 있어요.',
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.sm),
          ChaerokButton(
            text: '필름롤 시작하기',
            isEnabled: _locationResult != null,
            isLoading: _isEnteringFilmRoll,
            onPressed: _onStartFilmRollTap,
          ),
        ],
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.userNickname, required this.regionName});

  final String? userNickname;
  final String? regionName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          userNickname != null ? '안녕하세요, $userNickname님' : '안녕하세요',
          style: ChaerokTypography.bodyMedium.copyWith(
            color: ChaerokColors.textPrimary,
          ),
        ),
        const SizedBox(height: ChaerokSpacing.xs),
        Text(
          '현재 지역',
          style: ChaerokTypography.labelSmall.copyWith(
            color: ChaerokColors.textSecondary,
          ),
        ),
        const SizedBox(height: ChaerokSpacing.xxs),
        Text(
          regionName ?? '확인 중...',
          style: ChaerokTypography.displayMedium.copyWith(
            fontFamily: ChaerokTypography.jeongnimsajiFontFamily,
            color: ChaerokColors.primaryDark,
          ),
        ),
      ],
    );
  }
}
