import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/core/network/token_storage.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/signup_request.dart';
import 'package:chaerok/data/remote/auth_api.dart';
import 'package:chaerok/features/auth/data/current_account_sync.dart';
import 'package:chaerok/features/auth/presentation/signup_navigation.dart';
import 'package:chaerok/features/location/data/location_permission_service.dart';
import 'package:chaerok/shared/widgets/chaerok_appbar.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

/// 회원가입 2단계 — 닉네임 입력 화면.
///
/// 1단계 [SignupScreen]에서 필수 약관 동의를 마친 뒤 진입한다. 닉네임을 입력하고
/// "시작하기"를 누르면 [SignupRequest]로 회원가입을 완료하고, 토큰 저장·위치 권한
/// 요청을 거쳐 위치 인증 화면으로 이동한다.
class NicknameScreen extends StatefulWidget {
  const NicknameScreen({
    super.key,
    required this.signupToken,
    required this.termsAgreed,
    required this.privacyAgreed,
  });

  final String signupToken;
  final bool termsAgreed;
  final bool privacyAgreed;

  @override
  State<NicknameScreen> createState() => _NicknameScreenState();
}

class _NicknameScreenState extends State<NicknameScreen> {
  static const _tag = 'NicknameScreen';
  static const int _maxNicknameLength = 20;

  /// 입력 필드·CTA에 쓰는 짙은 올리브 색. 디자인 전용 값이라 토큰 대신 사용한다.
  static const Color _accent = Color(0xFF45523D);

  final _nicknameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  bool get _canSubmit =>
      _nicknameController.text.trim().isNotEmpty && !_isLoading;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  /// 기본 글자 수 카운터를 숨기는 빌더. 카운터는 입력 필드 아래에 직접 그린다.
  static Widget? _hideCounter(
    BuildContext context, {
    required int currentLength,
    required bool isFocused,
    required int? maxLength,
  }) => null;

  /// 에러 객체를 사용자에게 보여줄 수 있는 메시지로 변환하는 함수
  String _toErrorMessage(Object e) {
    if (e is DioException && e.error is ApiError) {
      return (e.error as ApiError).message;
    }
    return e.toString();
  }

  /// "시작하기" 버튼 클릭 시 회원가입을 완료하는 함수
  Future<void> _onStartTap() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final tokens = await AuthApi.signUp(
        SignupRequest(
          signupToken: widget.signupToken,
          nickname: _nicknameController.text.trim(),
          termsAgreed: widget.termsAgreed,
          privacyAgreed: widget.privacyAgreed,
        ),
      );
      if (tokens.accessToken.isEmpty || tokens.refreshToken.isEmpty) {
        log('회원가입 실패 - 토큰 발급 실패(빈 응답)', name: _tag);
        if (mounted) {
          setState(() => _errorMessage = '회원가입에 실패했습니다. 다시 시도해주세요.');
        }
        return;
      }
      log('회원가입 성공', name: _tag);
      await TokenStorage.instance.saveTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );
      if (!mounted) return;
      await CurrentAccountSync.sync();
      try {
        await LocationPermissionService.requestPermission();
      } catch (e, st) {
        log('위치 권한 요청 실패 - ${_toErrorMessage(e)}', name: _tag, stackTrace: st);
      }
      if (!mounted) return;
      await SignupNavigation.toMainViaLocationVerification(context);
    } catch (e, st) {
      log('회원가입 실패 - ${_toErrorMessage(e)}', name: _tag, stackTrace: st);
      if (mounted) setState(() => _errorMessage = _toErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final length = _nicknameController.text.characters.length;
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: const ChaerokAppbar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ChaerokSpacing.xl,
            ChaerokSpacing.xs,
            ChaerokSpacing.xl,
            ChaerokSpacing.xl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '닉네임',
                style: ChaerokTypography.displayLarge.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: ChaerokColors.textPrimary,
                ),
              ),
              const SizedBox(height: ChaerokSpacing.xxl),
              TextField(
                controller: _nicknameController,
                onChanged: (_) => setState(() {}),
                maxLength: _maxNicknameLength,
                textInputAction: TextInputAction.done,
                buildCounter: _hideCounter,
                style: ChaerokTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ChaerokColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '여행자님의 이름을 알려주세요',
                  hintStyle: ChaerokTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF858585),
                  ),
                  filled: true,
                  fillColor: const Color(0x1945523D),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: ChaerokSpacing.md,
                    vertical: 14,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      width: 1.5,
                      color: Color(0x4C45523D),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(width: 1.5, color: _accent),
                  ),
                ),
              ),
              const SizedBox(height: ChaerokSpacing.xs),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$length/$_maxNicknameLength',
                  style: ChaerokTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ChaerokColors.textPrimary.withValues(alpha: 0.5),
                  ),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: ChaerokSpacing.md),
                Text(
                  _errorMessage!,
                  style: ChaerokTypography.caption.copyWith(
                    color: ChaerokColors.error,
                  ),
                ),
              ],
              const Spacer(),
              ChaerokButton(
                text: '시작하기',
                onPressed: _canSubmit ? _onStartTap : null,
                isEnabled: _canSubmit,
                isLoading: _isLoading,
                backgroundColor: _accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
