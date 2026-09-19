import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:flutter/material.dart';

/// 방문 인증 안내(다음 장소 · 자유 촬영)에 공통으로 쓰이는 테두리 카드
/// 컨테이너. 채록길 탭·홈 화면이 공유한다.
class GuidanceCard extends StatelessWidget {
  const GuidanceCard({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChaerokSpacing.lg),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
        border: Border.all(color: ChaerokColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: ChaerokTypography.caption),
          const SizedBox(height: ChaerokSpacing.xxs),
          child,
        ],
      ),
    );
  }
}
