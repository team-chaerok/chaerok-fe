import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/core/network/token_storage.dart';
import 'package:chaerok/data/models/refresh_token_request.dart';
import 'package:chaerok/data/remote/auth_api.dart';
import 'package:chaerok/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _tag = 'HomeScreen';

  Future<void> _onLogoutTap(BuildContext context) async {
    // 로그아웃 로직 구현
    // 예: 토큰 삭제, 로그인 화면으로 이동 등
    log('로그아웃 버튼 탭', name: _tag);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text('홈', style: ChaerokTypography.titleMedium),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(ChaerokSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: ChaerokColors.primary,
                size: 64,
              ),
              const SizedBox(height: ChaerokSpacing.lg),
              const Text('로그인 성공', style: ChaerokTypography.titleMedium),
              TextButton(
                onPressed: () => _onLogoutTap(context),
                style: TextButton.styleFrom(
                  foregroundColor: ChaerokColors.primary,
                ),
                child: const Text('로그아웃'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
