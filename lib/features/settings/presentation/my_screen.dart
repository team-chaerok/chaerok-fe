import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/config/app_flavor.dart';
import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/o_auth_login_request.dart';
import 'package:chaerok/data/models/user_response.dart';
import 'package:chaerok/data/remote/users_api.dart';
import 'package:chaerok/features/settings/presentation/settings_screen.dart';
import 'package:chaerok/features/test_mode/presentation/test_mode_panel_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 마이 탭: 프로필 요약, 설정 진입점, 그리고(비공개 테스트/디버그 빌드이거나
/// 서버가 테스트 계정으로 내려준 경우) Test Mode(QA) 패널 진입점을 보여준다.
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
  bool _isTester = false;

  /// 비공개 테스트 빌드이거나 디버그 빌드이거나 서버 테스트 계정일 때만 Test Mode
  /// 패널 진입점을 노출한다. 실제 위치 우회 허용 여부는 `MockLocationGate.isAllowed()`
  /// 가 별도로 판단한다(release 일반 사용자는 항상 실제 GPS).
  bool get _showTestMode => AppFlavor.isTestMode || kDebugMode || _isTester;

  @override
  void initState() {
    super.initState();
    unawaited(_fetchUserInfo());
  }

  Future<void> _fetchUserInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await UsersApi.getMyInformation();
      await AppPreferences.instance.setTester(user.isTester);
      if (!mounted) return;
      setState(() {
        _user = user;
        _isTester = user.isTester;
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

  Future<void> _onTestModeTap() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TestModePanelScreen()));
  }

  @override
  Widget build(BuildContext context) {
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
            if (_showTestMode) ...[
              const SizedBox(height: ChaerokSpacing.md),
              _buildCardContainer(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Test Mode (QA)',
                    style: ChaerokTypography.bodyLarge,
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _onTestModeTap,
                ),
              ),
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
