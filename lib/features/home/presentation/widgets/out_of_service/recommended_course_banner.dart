import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';

/// "OO 추천 채록길" CTA 배너. 탭하면 채록길 탭으로 이동한다(부모가 처리).
class RecommendedCourseBanner extends StatelessWidget {
  const RecommendedCourseBanner({
    super.key,
    required this.region,
    required this.onTap,
  });

  final RegionCode region;
  final VoidCallback onTap;

  /// Figma 배너 배경(sage 계열). ChaerokColors에 없어 리터럴 사용.
  static const Color _bg = Color(0xFFEBEEE3);

  /// Figma 배너 제목 색(딥 올리브). ChaerokColors에 없어 리터럴 사용.
  static const Color _title = Color(0xFF3C3F2F);

  @override
  Widget build(BuildContext context) {
    final name = region.displayName;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
      child: Material(
        color: _bg,
        borderRadius: BorderRadius.circular(ChaerokRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ChaerokRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ChaerokSpacing.md,
              vertical: ChaerokSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.map_outlined,
                  size: ChaerokSpacing.xl,
                  color: ChaerokColors.primaryDark,
                ),
                const SizedBox(width: ChaerokSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$name 추천 채록길',
                        style: ChaerokTypography.caption.copyWith(
                          color: _title,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: ChaerokSpacing.xxs),
                      Text(
                        '$name의 매력을 담은 코스를 확인해보세요',
                        style: ChaerokTypography.caption.copyWith(
                          color: ChaerokColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: ChaerokColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
