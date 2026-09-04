import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';

/// 위치 인증 화면의 인증 전(idle) 기본 뷰.
///
/// 상단 지도 미리보기, 안내 타이틀/문구, 접이식 FAQ 2개, 하단 고정 CTA로 구성된다.
/// 실제 좌표 획득·행정구역 판별 등 인증 로직은 갖지 않고, 상호작용을 콜백으로
/// 위임하므로 위젯 테스트에서 지도/위치 플러그인 없이 단독으로 검증할 수 있다.
class LocationVerificationIdleView extends StatefulWidget {
  const LocationVerificationIdleView({
    super.key,
    required this.mapPreview,
    required this.onVerifyTap,
    required this.onReloadTap,
    this.isReloading = false,
  });

  /// 상단에 고정 높이로 노출할 지도 미리보기 위젯(재조준 버튼 포함).
  final Widget mapPreview;

  /// 하단 "위치 인증하기" CTA를 눌렀을 때 호출된다.
  final VoidCallback onVerifyTap;

  /// "위치 인증이 잘 안 되나요?" 패널의 "현재 위치 다시 불러오기"를 눌렀을 때 호출된다.
  final VoidCallback onReloadTap;

  /// 좌표 재조회가 진행 중인지 여부. true면 재조회 버튼에 로딩 인디케이터를 표시한다.
  final bool isReloading;

  @override
  State<LocationVerificationIdleView> createState() =>
      _LocationVerificationIdleViewState();
}

class _LocationVerificationIdleViewState
    extends State<LocationVerificationIdleView> {
  static const double _mapPreviewHeight = 300;

  bool _whyExpanded = false;
  bool _troubleExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: _mapPreviewHeight, child: widget.mapPreview),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              ChaerokSpacing.xl,
              ChaerokSpacing.xl,
              ChaerokSpacing.xl,
              ChaerokSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '현재 여행 중인 지역을 확인해주세요.',
                  style: ChaerokTypography.titleLarge,
                ),
                const SizedBox(height: ChaerokSpacing.xs),
                Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(text: '위치를 인증하면 해당 지역의 '),
                      TextSpan(
                        text: '필름롤',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: '과 '),
                      TextSpan(
                        text: '채록 장소',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(text: '를 만나볼 수 있어요.'),
                    ],
                  ),
                  style: ChaerokTypography.bodyMedium.copyWith(
                    color: ChaerokColors.textSecondary,
                  ),
                ),
                const SizedBox(height: ChaerokSpacing.xl),
                _FaqAccordion(
                  question: '왜 위치 인증이 필요한가요?',
                  expanded: _whyExpanded,
                  onToggle: () => setState(() => _whyExpanded = !_whyExpanded),
                  child: const _FaqPanel(
                    child: Text(
                      '채록은 실제 여행 중인 지역을 기준으로 필름롤을 만들어요. '
                      '현재 위치를 확인하면 해당 지역의 필름롤과 채록장소를 이용할 수 있어요.',
                      style: ChaerokTypography.bodyMedium,
                    ),
                  ),
                ),
                const Divider(height: 1, color: ChaerokColors.border),
                _FaqAccordion(
                  question: '위치 인증이 잘 안 되나요?',
                  expanded: _troubleExpanded,
                  onToggle: () =>
                      setState(() => _troubleExpanded = !_troubleExpanded),
                  child: _FaqPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '아래 항목을 확인해주세요.',
                          style: ChaerokTypography.bodyMedium,
                        ),
                        const SizedBox(height: ChaerokSpacing.xs),
                        ..._troubleCheckItems.map(_buildCheckItem),
                        const SizedBox(height: ChaerokSpacing.sm),
                        _ReloadCurrentLocationButton(
                          isLoading: widget.isReloading,
                          onPressed: widget.onReloadTap,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ChaerokSpacing.xl,
            ChaerokSpacing.md,
            ChaerokSpacing.xl,
            ChaerokSpacing.xl,
          ),
          child: ChaerokButton(
            text: '위치 인증하기',
            backgroundColor: ChaerokColors.primaryDark,
            onPressed: widget.onVerifyTap,
          ),
        ),
      ],
    );
  }

  static const List<String> _troubleCheckItems = [
    '휴대폰의 위치 서비스가 켜져 있는지 확인해주세요.',
    '채록의 위치 권한이 허용되어 있는지 확인해주세요.',
    '실내나 지하에서는 위치가 정확하지 않을 수 있어요.',
    '현재 위치가 채록 지원 지역인지 확인해주세요.',
  ];

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ChaerokSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// FAQ 한 줄. 질문 행을 탭하면 [onToggle]이 호출되고, [expanded]가 true면
/// [child]가 아래에 펼쳐진다.
class _FaqAccordion extends StatelessWidget {
  const _FaqAccordion({
    required this.question,
    required this.expanded,
    required this.onToggle,
    required this.child,
  });

  final String question;
  final bool expanded;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: ChaerokSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    question,
                    style: ChaerokTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 150),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: ChaerokColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          alignment: Alignment.topCenter,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(bottom: ChaerokSpacing.md),
                  child: child,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// 펼쳐진 FAQ 본문을 감싸는 surface 카드.
class _FaqPanel extends StatelessWidget {
  const _FaqPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: ChaerokColors.textSecondary),
        child: child,
      ),
    );
  }
}

/// "위치 인증이 잘 안 되나요?" 패널 안의 좌표 재조회 액션 버튼.
class _ReloadCurrentLocationButton extends StatelessWidget {
  const _ReloadCurrentLocationButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: ChaerokColors.textPrimary,
          backgroundColor: ChaerokColors.background,
          side: const BorderSide(color: ChaerokColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ChaerokRadius.sm),
          ),
        ),
        child: isLoading
            ? const ChaerokLoadingIndicator(size: 18, strokeWidth: 2)
            : const Text('현재 위치 다시 불러오기', style: ChaerokTypography.bodyMedium),
      ),
    );
  }
}
