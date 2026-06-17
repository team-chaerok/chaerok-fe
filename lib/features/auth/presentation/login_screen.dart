import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
              _KakaoLoginButton(
                onTap: () {
                  // TODO: 카카오 로그인 처리
                },
              ),
              const SizedBox(height: ChaerokSpacing.md),
              _GoogleLoginButton(
                onTap: () {
                  // TODO: 구글 로그인 처리
                },
              ),
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
