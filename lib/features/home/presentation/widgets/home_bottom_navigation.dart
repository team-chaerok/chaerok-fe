import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_shadows.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/home/presentation/widgets/home_camera_action.dart';
import 'package:flutter/material.dart';

class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onCameraTap,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onCameraTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        border: const Border(top: BorderSide(color: ChaerokColors.border)),
        boxShadow: ChaerokShadows.card,
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(
          top: ChaerokSpacing.xs,
          bottom: ChaerokSpacing.xs,
        ),
        child: Row(
          children: [
            _NavigationItem(
              label: '홈',
              icon: Icons.home_outlined,
              selectedIcon: Icons.home_rounded,
              isSelected: selectedIndex == 0,
              onTap: () => onItemSelected(0),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HomeCameraAction(onPressed: onCameraTap),
                  const SizedBox(height: 2),
                  Text(
                    '카메라',
                    style: ChaerokTypography.caption.copyWith(
                      color: ChaerokColors.primaryDark,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            _NavigationItem(
              label: '채록길',
              icon: Icons.explore_outlined,
              selectedIcon: Icons.explore,
              isSelected: selectedIndex == 1,
              onTap: () => onItemSelected(1),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? ChaerokColors.primary
        : ChaerokColors.textSecondary;

    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: ChaerokSpacing.xl,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ChaerokSpacing.xxs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? selectedIcon : icon, color: color, size: 19),
              const SizedBox(height: 2),
              Text(
                label,
                style: ChaerokTypography.caption.copyWith(
                  color: color,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
