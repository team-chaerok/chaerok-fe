import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';

/// 충남 외 지역 홈 상단의 "필름롤" 아코디언. 4개 지역 헤더를 필름 스트립처럼
/// 살짝 겹쳐 쌓고, 접힌 헤더를 탭하면 [onSelect]로 전환을 요청한다.
/// 상세 패널은 이 위젯이 아니라 부모가 그린다.
class RegionFilmStrip extends StatelessWidget {
  const RegionFilmStrip({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final RegionCode selected;
  final ValueChanged<RegionCode> onSelect;

  /// 겹쳐 쌓이는 느낌을 주는 헤더 간 음수 오버랩(Figma 근사). 토큰이 없어 raw 사용.
  static const double _overlap = 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, region) in RegionCode.values.indexed)
          Transform.translate(
            offset: Offset(0, index == 0 ? 0 : -_overlap * index),
            child: _FilmRollHeader(
              label: region.filmRollTitle,
              isSelected: region == selected,
              onTap: () => onSelect(region),
            ),
          ),
      ],
    );
  }
}

class _FilmRollHeader extends StatelessWidget {
  const _FilmRollHeader({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? ChaerokColors.primaryDark
              : ChaerokColors.primaryDark.withValues(alpha: 0.72),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(ChaerokRadius.lg),
            topRight: Radius.circular(ChaerokRadius.lg),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: ChaerokTypography.jeongnimsajiFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: isSelected ? Colors.white : Colors.white70,
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
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
