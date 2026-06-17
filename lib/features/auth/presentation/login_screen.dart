import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/auth/data/google_auth_service.dart';
import 'package:chaerok/features/auth/data/kakao_auth_service.dart';
import 'package:chaerok/features/home/presentation/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const _tag = 'LoginScreen';

  Future<void> _onKakaoLoginTap(BuildContext context) async {
    log('카카오 로그인 버튼 탭', name: _tag);
    try {
      await KakaoAuthService().signIn();

      final user = await UserApi.instance.me();
      if (!context.mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            provider: '카카오',
            email: user.kakaoAccount?.email,
            nickname: user.kakaoAccount?.profile?.nickname,
          ),
        ),
      );
    } catch (e, st) {
      log('카카오 로그인 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> _onGoogleLoginTap(BuildContext context) async {
    log('구글 로그인 버튼 탭', name: _tag);
    try {
      final account = await GoogleAuthService().signIn();

      if (!context.mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(
            provider: '구글',
            email: account.email,
            nickname: account.displayName,
          ),
        ),
      );
    } catch (e, st) {
      log('구글 로그인 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _KakaoLoginButton(onTap: () => _onKakaoLoginTap(context)),
              const SizedBox(height: ChaerokSpacing.md),
              _GoogleLoginButton(onTap: () => _onGoogleLoginTap(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _KakaoLoginButton extends StatelessWidget {
  const _KakaoLoginButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEE500),
          foregroundColor: const Color(0xFF191919),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ChaerokRadius.md),
          ),
        ),
        child: const Text('카카오로 계속하기', style: ChaerokTypography.labelLarge),
      ),
    );
  }
}

class _GoogleLoginButton extends StatelessWidget {
  const _GoogleLoginButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: ChaerokColors.surface,
          foregroundColor: ChaerokColors.textPrimary,
          side: const BorderSide(color: ChaerokColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ChaerokRadius.md),
          ),
        ),
        child: const Text('구글로 계속하기', style: ChaerokTypography.labelLarge),
      ),
    );
  }
}
