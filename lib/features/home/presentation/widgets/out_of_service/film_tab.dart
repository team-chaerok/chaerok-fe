import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:flutter/material.dart';

/// 필름롤 스택의 헤더 탭. 열린 카드의 탭([opened] == true)은 진하게 강조하고
/// 펼침 아이콘을 붙인다. 겹쳐 쌓인 탭은 [onTap]으로 전환을 요청한다.
/// [color]는 지역별 배경색으로, 겹친 탭은 같은 색을 흐리게 쓴다.
class FilmTab extends StatelessWidget {
  const FilmTab({
    super.key,
    required this.label,
    required this.opened,
    required this.color,
    this.onTap,
  });

  final String label;
  final bool opened;
  final Color color;
  final VoidCallback? onTap;

  /// 탭 높이 겸 스택에서 겹친 탭이 아래로 밀리는 y 간격(프로토타입 peek=36).
  /// 토큰 없음.
  static const double tabHeight = 36;

  /// Figma 근사. 토큰 없음.
  static const double _labelSize = 16;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: tabHeight,
        padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
        decoration: BoxDecoration(
          color: opened ? color : color.withValues(alpha: 0.72),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(ChaerokRadius.lg),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            if (opened) ...[
              const Icon(
                Icons.keyboard_double_arrow_down_rounded,
                size: 18, // Figma 근사. 토큰 없음.
                color: Colors.white,
              ),
              const SizedBox(width: ChaerokSpacing.xs),
            ],
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: ChaerokTypography.jeongnimsajiFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: _labelSize,
                  color: opened ? Colors.white : Colors.white70,
                ),
              ),
            ),
            const _SprocketHoles(),
          ],
        ),
      ),
    );
  }
}

/// 필름 스트립의 스프로킷 구멍 3개(Figma 근사).
class _SprocketHoles extends StatelessWidget {
  const _SprocketHoles();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(left: ChaerokSpacing.xxs),
          width: 6, // Figma 6px 스프로킷. 토큰 없음.
          height: 6,
          decoration: BoxDecoration(
            color: ChaerokColors.background,
            borderRadius: BorderRadius.circular(1), // Figma 근사. 토큰 없음.
          ),
        ),
      ),
    );
  }
}
