import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/update_nickname_request.dart';
import 'package:chaerok/data/remote/users_api.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:flutter/material.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const _tag = 'ProfileEditScreen';

  final _nicknameController = TextEditingController();

  bool _isLoadingInitial = true;
  bool _isSaving = false;
  String? _loadErrorMessage;
  String? _fieldErrorMessage;

  @override
  void initState() {
    super.initState();
    unawaited(_loadCurrentNickname());
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentNickname() async {
    setState(() {
      _isLoadingInitial = true;
      _loadErrorMessage = null;
    });

    try {
      final user = await UsersApi.getMyInformation();
      if (!mounted) return;
      setState(() {
        _nicknameController.text = user.nickname;
        _isLoadingInitial = false;
      });
    } catch (e, st) {
      log('내 정보 조회 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _loadErrorMessage = apiErrorMessage(e);
        _isLoadingInitial = false;
      });
    }
  }

  Future<void> _onSaveTap() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      setState(() => _fieldErrorMessage = '닉네임을 입력해주세요.');
      return;
    }

    setState(() {
      _isSaving = true;
      _fieldErrorMessage = null;
    });

    try {
      await UsersApi.updateNickname(UpdateNicknameRequest(nickname: nickname));
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('닉네임이 변경되었습니다.')));
      Navigator.of(context).pop();
    } catch (e, st) {
      log('닉네임 수정 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _fieldErrorMessage = apiErrorMessage(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text('프로필 수정', style: ChaerokTypography.titleMedium),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ChaerokSpacing.xxl,
          vertical: ChaerokSpacing.lg,
        ),
        child: _isLoadingInitial
            ? const Center(child: CircularProgressIndicator())
            : _loadErrorMessage != null
            ? _buildLoadError()
            : _buildForm(),
      ),
    );
  }

  Widget _buildLoadError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _loadErrorMessage!,
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ChaerokSpacing.md),
          TextButton(
            onPressed: _loadCurrentNickname,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('닉네임', style: ChaerokTypography.bodyMedium),
        const SizedBox(height: ChaerokSpacing.xs),
        TextField(
          controller: _nicknameController,
          enabled: !_isSaving,
          style: ChaerokTypography.bodyLarge,
          decoration: InputDecoration(
            errorText: _fieldErrorMessage,
            filled: true,
            fillColor: ChaerokColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ChaerokSpacing.md,
              vertical: ChaerokSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ChaerokRadius.md),
              borderSide: const BorderSide(color: ChaerokColors.border),
            ),
          ),
          onChanged: (_) {
            if (_fieldErrorMessage != null) {
              setState(() => _fieldErrorMessage = null);
            }
          },
        ),
        const SizedBox(height: ChaerokSpacing.xl),
        ChaerokButton(
          text: _isSaving ? '저장 중...' : '저장',
          isEnabled: !_isSaving,
          onPressed: _onSaveTap,
        ),
      ],
    );
  }
}
