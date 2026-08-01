import 'package:chaerok/ui/home/widgets/home_camera_action.dart';
import 'package:chaerok/ui/preview_theme.dart';
import 'package:flutter/material.dart';

class HomeBottomNavigation extends StatelessWidget {
  const HomeBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: UiPreviewColors.surface,
        border: Border(top: BorderSide(color: UiPreviewColors.border)),
        boxShadow: UiPreviewShadows.card,
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(
          top: UiPreviewSpacing.xs,
          bottom: UiPreviewSpacing.xs,
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
            _NavigationItem(
              label: '지도',
              icon: Icons.location_on_outlined,
              selectedIcon: Icons.location_on_rounded,
              isSelected: selectedIndex == 1,
              onTap: () => onItemSelected(1),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HomeCameraAction(onPressed: () => onItemSelected(2)),
                  const SizedBox(height: 2),
                  Text(
                    '카메라',
                    style: UiPreviewTypography.labelSmall.copyWith(
                      color: UiPreviewColors.primaryDark,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            _NavigationItem(
              label: '필름 롤',
              icon: Icons.photo_library_outlined,
              selectedIcon: Icons.photo_library_rounded,
              isSelected: selectedIndex == 3,
              onTap: () => onItemSelected(3),
            ),
            _NavigationItem(
              label: '마이',
              icon: Icons.person_outline_rounded,
              selectedIcon: Icons.person_rounded,
              isSelected: selectedIndex == 4,
              onTap: () => onItemSelected(4),
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
        ? UiPreviewColors.primary
        : UiPreviewColors.textSecondary;

    return Expanded(
      child: InkResponse(
        onTap: onTap,
        radius: UiPreviewSpacing.xl,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: UiPreviewSpacing.xxs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isSelected ? selectedIcon : icon, color: color, size: 19),
              const SizedBox(height: 2),
              Text(
                label,
                style: UiPreviewTypography.labelSmall.copyWith(
                  color: color,
                  fontSize: 9,
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
