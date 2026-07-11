import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/core/network/token_storage.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/refresh_token_request.dart';
import 'package:chaerok/data/remote/auth_api.dart';
import 'package:chaerok/data/remote/users_api.dart';
import 'package:chaerok/features/auth/data/google_auth_service.dart';
import 'package:chaerok/features/auth/data/kakao_auth_service.dart';
import 'package:chaerok/features/auth/presentation/login_screen.dart';
import 'package:chaerok/features/settings/presentation/profile_edit_screen.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';

enum _SettingsAction { logout, withdraw }

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _tag = 'SettingsScreen';

  _SettingsAction? _loadingAction;

  Future<void> _onLogoutTap(BuildContext context) async {
    if (_loadingAction != null) return;
    log('로그아웃 버튼 탭', name: _tag);
    setState(() => _loadingAction = _SettingsAction.logout);
    final refreshToken = await TokenStorage.instance.getRefreshToken();

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await AuthApi.logout(RefreshTokenRequest(refreshToken: refreshToken));
      }
    } catch (e, st) {
      log('로그아웃 API 실패 - 로컬 토큰 삭제 진행', name: _tag, stackTrace: st);
    } finally {
      await TokenStorage.instance.clear();
    }

    if (!context.mounted) return;
    await Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<void> _onWithdrawTap(BuildContext context) async {
    if (_loadingAction != null) return;
    log('회원탈퇴 버튼 탭', name: _tag);
    final confirmed = await _showWithdrawConfirmDialog(context);
    if (confirmed != true) return;
    if (!context.mounted) return;

    setState(() => _loadingAction = _SettingsAction.withdraw);

    try {
      await UsersApi.withdraw();
    } catch (e, st) {
      log('회원탈퇴 API 실패', name: _tag, error: e, stackTrace: st);
      if (!context.mounted) return;
      setState(() => _loadingAction = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
      return;
    }

    // 탈퇴 API가 이미 성공했으므로 소셜 연동 해제가 실패하거나 응답이 없어도
    // 탈퇴 흐름(토큰 삭제·화면 전환)은 계속 진행한다.
    log('회원탈퇴 성공 - 소셜 계정 연동 해제 진행', name: _tag);
    await Future.wait([
      GoogleAuthService().disconnect().timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      ),
      KakaoAuthService().unlink().timeout(
        const Duration(seconds: 5),
        onTimeout: () {},
      ),
    ]);
    try {
      await TokenStorage.instance.clear();
    } catch (e, st) {
      log('토큰 삭제 실패', name: _tag, error: e, stackTrace: st);
    }

    if (!context.mounted) return;
    await Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  Future<bool?> _showWithdrawConfirmDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('회원탈퇴', style: ChaerokTypography.titleMedium),
        content: const Text(
          '정말 탈퇴하시겠어요?\n탈퇴 시 계정 정보가 삭제되며 복구할 수 없습니다.',
          style: ChaerokTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: ChaerokColors.error),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }

  void _onProfileEditTap(BuildContext context) {
    unawaited(
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ProfileEditScreen())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text('설정', style: ChaerokTypography.titleMedium),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ChaerokSpacing.xxl,
          vertical: ChaerokSpacing.lg,
        ),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('프로필 수정', style: ChaerokTypography.bodyLarge),
              onTap: () => _onProfileEditTap(context),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('로그아웃', style: ChaerokTypography.bodyLarge),
              trailing: _loadingAction == _SettingsAction.logout
                  ? const ChaerokLoadingIndicator(size: 20, strokeWidth: 2)
                  : null,
              onTap: _loadingAction == null
                  ? () => _onLogoutTap(context)
                  : null,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '회원탈퇴',
                style: ChaerokTypography.bodyLarge.copyWith(
                  color: ChaerokColors.error,
                ),
              ),
              trailing: _loadingAction == _SettingsAction.withdraw
                  ? const ChaerokLoadingIndicator(
                      color: ChaerokColors.error,
                      size: 20,
                      strokeWidth: 2,
                    )
                  : null,
              onTap: _loadingAction == null
                  ? () => _onWithdrawTap(context)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
