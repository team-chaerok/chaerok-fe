import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/core/network/token_storage.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/signup_request.dart';
import 'package:chaerok/data/remote/auth_api.dart';
import 'package:chaerok/features/auth/data/current_account_sync.dart';
import 'package:chaerok/features/home/presentation/main_tab_screen.dart';
import 'package:chaerok/features/location/data/location_permission_service.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.signupToken});

  final String signupToken;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  static const _tag = 'SignupScreen';

  final _nicknameController = TextEditingController();
  bool _termsAgreed = false;
  bool _privacyAgreed = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _canSubmit =>
      _nicknameController.text.trim().isNotEmpty &&
      _termsAgreed &&
      _privacyAgreed &&
      !_isLoading;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  /// 에러 객체를 사용자에게 보여줄 수 있는 메시지로 변환하는 함수
  String _toErrorMessage(Object e) {
    if (e is DioException && e.error is ApiError) {
      return (e.error as ApiError).message;
    }
    return e.toString();
  }

  /// 회원가입 버튼 클릭 시 호출되는 함수
  Future<void> _onSignupTap() async {
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
          termsAgreed: _termsAgreed,
          privacyAgreed: _privacyAgreed,
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
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainTabScreen()),
      );
    } catch (e, st) {
      log('회원가입 실패 - ${_toErrorMessage(e)}', name: _tag, stackTrace: st);
      if (mounted) setState(() => _errorMessage = _toErrorMessage(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text('회원가입', style: ChaerokTypography.titleMedium),
      ),
      body: Padding(
        padding: const EdgeInsets.all(ChaerokSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('닉네임', style: ChaerokTypography.bodyMedium),
            const SizedBox(height: ChaerokSpacing.xs),
            TextField(
              controller: _nicknameController,
              onChanged: (_) => setState(() {}),
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: '닉네임을 입력해주세요',
                hintStyle: ChaerokTypography.bodyMedium.copyWith(
                  color: ChaerokColors.textDisabled,
                ),
                filled: true,
                fillColor: ChaerokColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ChaerokRadius.md),
                  borderSide: const BorderSide(color: ChaerokColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ChaerokRadius.md),
                  borderSide: const BorderSide(color: ChaerokColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(ChaerokRadius.md),
                  borderSide: const BorderSide(color: ChaerokColors.primary),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: ChaerokSpacing.md,
                  vertical: ChaerokSpacing.sm,
                ),
              ),
            ),
            const SizedBox(height: ChaerokSpacing.xl),
            const Text('약관 동의', style: ChaerokTypography.bodyMedium),
            const SizedBox(height: ChaerokSpacing.xs),
            _AgreementCheckbox(
              label: '이용약관에 동의합니다 (필수)',
              value: _termsAgreed,
              onChanged: (v) => setState(() => _termsAgreed = v ?? false),
            ),
            const SizedBox(height: ChaerokSpacing.xxs),
            _AgreementCheckbox(
              label: '개인정보처리방침에 동의합니다 (필수)',
              value: _privacyAgreed,
              onChanged: (v) => setState(() => _privacyAgreed = v ?? false),
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
              text: '가입하기',
              onPressed: _canSubmit ? _onSignupTap : null,
              isEnabled: _canSubmit,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}

class _AgreementCheckbox extends StatelessWidget {
  const _AgreementCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: ChaerokColors.primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: Text(label, style: ChaerokTypography.bodyMedium),
          ),
        ),
      ],
    );
  }
}
