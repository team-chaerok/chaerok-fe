import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/film_roll/domain/visit_verification.dart';
import 'package:flutter/material.dart';

/// [VisitGateResult.message]를 인증 가능 여부에 따라 색을 달리해 보여주는
/// 상태 문구. 채록길 탭·홈 화면의 인증 안내 카드가 공유한다.
class VisitGateMessage extends StatelessWidget {
  const VisitGateMessage({super.key, required this.gate});

  final VisitGateResult gate;

  @override
  Widget build(BuildContext context) {
    return Text(
      gate.message,
      style: ChaerokTypography.caption.copyWith(
        color: gate.canVerify
            ? ChaerokColors.primaryDark
            : ChaerokColors.textSecondary,
      ),
    );
  }
}
