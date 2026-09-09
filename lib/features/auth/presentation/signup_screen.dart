import 'dart:async';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/auth/presentation/nickname_screen.dart';
import 'package:chaerok/shared/widgets/chaerok_appbar.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:flutter/material.dart';

/// 회원가입 1단계 — 서비스 이용 약관 동의 화면.
///
/// 필수 약관(서비스 이용·개인정보 이용·위치기반 서비스) 3가지에 모두 동의해야
/// 2단계인 [NicknameScreen]으로 진행할 수 있다. 선택 약관(마케팅 정보 수신)은
/// 진행 조건에 영향을 주지 않는다.
///
/// 현재 signup API는 `termsAgreed`(서비스 이용 약관), `privacyAgreed`(개인정보
/// 이용 약관) 두 값만 받으므로 위치기반·마케팅 동의는 이 화면 단계에서만
/// 수집한다.
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key, required this.signupToken});

  final String signupToken;

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // TODO(#101): 아래 약관 전문은 요약 플레이스홀더다. 확정된 정식 약관 문구로 교체한다.
  static const String _serviceTerms =
      '본 약관은 채록이 제공하는 서비스의 이용 조건과 절차, 회사와 회원의 권리·의무 및 '
      '책임 사항을 규정합니다. 회원은 서비스를 이용함으로써 본 약관에 동의한 것으로 봅니다. '
      '회사는 관련 법령을 위반하지 않는 범위에서 약관을 개정할 수 있으며, 개정 시 적용 '
      '일자와 사유를 사전에 공지합니다.';
  static const String _privacyTerms =
      '채록은 회원가입, 서비스 제공, 문의 대응을 위해 닉네임, 기기 정보, 위치 정보를 '
      '수집·이용합니다. 수집한 개인정보는 이용 목적이 달성되면 지체 없이 파기하며, 회원은 '
      '언제든지 자신의 개인정보 조회·수정·삭제를 요청할 수 있습니다. 자세한 항목과 보유 '
      '기간은 개인정보처리방침에서 확인할 수 있습니다.';
  static const String _locationTerms =
      '채록은 방문 인증과 주변 코스 추천을 위해 단말기의 위치 정보를 이용합니다. 위치 '
      '정보는 서비스 제공 목적 외로 사용되지 않으며, 회원은 언제든지 기기 설정에서 위치 '
      '권한을 해제할 수 있습니다. 권한을 해제하면 위치 기반 기능 이용이 제한될 수 있습니다.';
  static const String _marketingTerms =
      '이벤트, 혜택, 신규 기능 소식을 앱 푸시 또는 이메일로 안내받습니다. 마케팅 정보 '
      '수신에 동의하지 않아도 서비스 이용에는 제한이 없으며, 수신 동의는 언제든지 철회할 '
      '수 있습니다.';

  bool _serviceAgreed = false;
  bool _privacyAgreed = false;
  bool _locationAgreed = false;
  bool _marketingAgreed = false;

  bool get _allRequiredAgreed =>
      _serviceAgreed && _privacyAgreed && _locationAgreed;

  bool get _allAgreed =>
      _serviceAgreed && _privacyAgreed && _locationAgreed && _marketingAgreed;

  /// "모두 동의" 토글. 현재 전체 동의 상태의 반대값으로 4개 항목을 한 번에 맞춘다.
  void _toggleAll() {
    final next = !_allAgreed;
    setState(() {
      _serviceAgreed = next;
      _privacyAgreed = next;
      _locationAgreed = next;
      _marketingAgreed = next;
    });
  }

  /// 닉네임 입력(2단계) 화면으로 이동한다.
  void _goToNickname() {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => NicknameScreen(
            signupToken: widget.signupToken,
            termsAgreed: _serviceAgreed,
            privacyAgreed: _privacyAgreed,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                '서비스 이용 약관',
                style: ChaerokTypography.displayLarge.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  height: 1,
                  color: ChaerokColors.textPrimary,
                ),
              ),
              const SizedBox(height: ChaerokSpacing.xs),
              Text(
                '채록 이용을 위해 동의가 필요해요',
                style: ChaerokTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: ChaerokColors.textPrimary,
                ),
              ),
              const SizedBox(height: ChaerokSpacing.xxl),
              _SelectAllRow(
                value: _allAgreed,
                accent: ChaerokColors.primaryGreen,
                onToggle: _toggleAll,
              ),
              const Divider(height: 1, color: ChaerokColors.border),
              _AgreementRow(
                tag: '[필수]',
                label: ' 서비스 이용 약관',
                detail: _serviceTerms,
                value: _serviceAgreed,
                accent: ChaerokColors.primaryGreen,
                onToggle: () =>
                    setState(() => _serviceAgreed = !_serviceAgreed),
              ),
              _AgreementRow(
                tag: '[필수]',
                label: ' 개인정보 이용 약관',
                detail: _privacyTerms,
                value: _privacyAgreed,
                accent: ChaerokColors.primaryGreen,
                onToggle: () =>
                    setState(() => _privacyAgreed = !_privacyAgreed),
              ),
              _AgreementRow(
                tag: '[필수]',
                label: ' 위치기반 서비스 이용 약관',
                detail: _locationTerms,
                value: _locationAgreed,
                accent: ChaerokColors.primaryGreen,
                onToggle: () =>
                    setState(() => _locationAgreed = !_locationAgreed),
              ),
              _AgreementRow(
                tag: '[선택]',
                label: ' 마케팅 정보 수신',
                detail: _marketingTerms,
                value: _marketingAgreed,
                accent: ChaerokColors.primaryGreen,
                onToggle: () =>
                    setState(() => _marketingAgreed = !_marketingAgreed),
              ),
              const Spacer(),
              // 버튼 위치를 nickname_screen과 맞추기 위해 안내 문구는 버튼 위에 둔다.
              SizedBox(
                height: 18,
                child: _allRequiredAgreed
                    ? null
                    : Center(
                        child: Text(
                          '필수 약관 동의 후 활성화됩니다.',
                          style: ChaerokTypography.caption.copyWith(
                            fontSize: 13,
                            color: const Color(0xFF44483D),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: ChaerokSpacing.sm),
              ChaerokButton(
                text: '동의하고 계속하기',
                onPressed: _allRequiredAgreed ? _goToNickname : null,
                isEnabled: _allRequiredAgreed,
                backgroundColor: ChaerokColors.primaryGreen,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 약관 한 줄. 체크박스 + `[필수]/[선택]` 라벨 + 펼침 화살표로 구성된다.
///
/// 줄(체크박스·라벨 영역)을 탭하면 동의 상태가 토글되고, 우측 화살표 아이콘을
/// 탭하면 약관 전문이 아래로 아코디언처럼 펼쳐진다(별도 상세 화면으로 이동하지
/// 않는다).
class _AgreementRow extends StatefulWidget {
  const _AgreementRow({
    required this.tag,
    required this.label,
    required this.detail,
    required this.value,
    required this.accent,
    required this.onToggle,
  });

  final String tag;
  final String label;
  final String detail;
  final bool value;
  final Color accent;
  final VoidCallback onToggle;

  @override
  State<_AgreementRow> createState() => _AgreementRowState();
}

class _AgreementRowState extends State<_AgreementRow> {
  bool _expanded = false;

  void _toggleExpanded() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final tagStyle = ChaerokTypography.bodyLarge.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
      color: widget.accent,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: widget.onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              children: [
                _AgreementCheckbox(value: widget.value, accent: widget.accent),
                const SizedBox(width: ChaerokSpacing.xs),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: widget.tag, style: tagStyle),
                        TextSpan(
                          text: widget.label,
                          style: tagStyle.copyWith(
                            color: const Color(0xFF18191A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggleExpanded,
                  child: Padding(
                    padding: const EdgeInsets.only(left: ChaerokSpacing.xs),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 150),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 22,
                        color: Color(0xFFAEB0B6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.topCenter,
          child: _expanded
              ? _AgreementDetailPanel(text: widget.detail)
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// 펼쳐진 약관 전문을 감싸는 surface 카드. 내용이 길면 내부에서 스크롤된다.
class _AgreementDetailPanel extends StatelessWidget {
  const _AgreementDetailPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: ChaerokSpacing.sm),
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.sm),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 160),
        child: SingleChildScrollView(
          child: Text(
            text,
            style: ChaerokTypography.caption.copyWith(
              fontSize: 13,
              height: 1.6,
              color: ChaerokColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// 약관 목록 맨 위의 "전체 동의" 줄. 탭하면 필수·선택 약관을 한 번에 토글한다.
class _SelectAllRow extends StatelessWidget {
  const _SelectAllRow({
    required this.value,
    required this.accent,
    required this.onToggle,
  });

  final bool value;
  final Color accent;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            _AgreementCheckbox(value: value, accent: accent),
            const SizedBox(width: ChaerokSpacing.xs),
            Text(
              '전체 동의',
              style: ChaerokTypography.bodyLarge.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF18191A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 약관 동의용 사각 체크박스. 체크 시 [accent] 배경 + 흰 체크, 미체크 시 회색 테두리.
class _AgreementCheckbox extends StatelessWidget {
  const _AgreementCheckbox({required this.value, required this.accent});

  final bool value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: value ? accent : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: value
            ? null
            : Border.all(width: 2, color: const Color(0xFFAEB0B6)),
      ),
      child: value
          ? const Icon(
              Icons.check_rounded,
              size: 14,
              color: ChaerokColors.background,
            )
          : null,
    );
  }
}
