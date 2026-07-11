import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/network/token_storage.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/o_auth_login_request.dart';
import 'package:chaerok/data/models/o_auth_login_response.dart';
import 'package:chaerok/data/remote/auth_api.dart';
import 'package:chaerok/features/auth/data/google_auth_service.dart';
import 'package:chaerok/features/auth/data/kakao_auth_service.dart';
import 'package:chaerok/features/auth/presentation/signup_screen.dart';
import 'package:chaerok/features/home/presentation/home_screen.dart';
import 'package:chaerok/shared/widgets/social_login_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const _tag = 'LoginScreen';

  Future<void> _onKakaoLoginTap(BuildContext context) async {
    log('카카오 로그인 버튼 탭', name: _tag);
    try {
      final idToken = await KakaoAuthService().signIn();
      final response = await AuthApi.login(
        OAuthLoginRequest(provider: OAuthProvider.kakao, idToken: idToken),
      );
      log('카카오 로그인 응답: $response', name: _tag);
      if (!context.mounted) return;
      await _handleLoginResponse(context, response);
    } catch (e, st) {
      log('카카오 로그인 실패 - ${_errorMessage(e)}', name: _tag, stackTrace: st);
    }
  }

  Future<void> _onGoogleLoginTap(BuildContext context) async {
    log('구글 로그인 버튼 탭', name: _tag);
    try {
      final idToken = await GoogleAuthService().signIn();
      final response = await AuthApi.login(
        OAuthLoginRequest(provider: OAuthProvider.google, idToken: idToken),
      );
      log('구글 로그인 응답: $response', name: _tag);
      if (!context.mounted) return;
      await _handleLoginResponse(context, response);
    } catch (e, st) {
      log('구글 로그인 실패 - ${_errorMessage(e)}', name: _tag, stackTrace: st);
    }
  }

  String _errorMessage(Object e) {
    if (e is DioException && e.error is ApiError) {
      return (e.error as ApiError).toString();
    }
    return e.toString();
  }

  Future<void> _handleLoginResponse(
    BuildContext context,
    OAuthLoginResponse response,
  ) async {
    if (response.signupToken != null) {
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SignupScreen(signupToken: response.signupToken!),
        ),
      );
    } else if (response.tokens != null) {
      final tokens = response.tokens!;
      if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
        log('로그인 실패 - 토큰 발급 실패(빈 응답)', name: _tag);
        return;
      }
      await TokenStorage.instance.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      if (!context.mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
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
              SocialLoginButton(
                label: '카카오로 계속하기',
                onTap: () => _onKakaoLoginTap(context),
                backgroundColor: const Color(0xFFFEE500),
                foregroundColor: const Color(0xFF191919),
              ),
              const SizedBox(height: ChaerokSpacing.md),
              SocialLoginButton(
                label: '구글로 계속하기',
                onTap: () => _onGoogleLoginTap(context),
                backgroundColor: ChaerokColors.surface,
                foregroundColor: ChaerokColors.textPrimary,
                side: const BorderSide(color: ChaerokColors.border),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
