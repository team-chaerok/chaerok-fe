import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:flutter/material.dart';

class PlaceCategoryMenu extends StatelessWidget {
  const PlaceCategoryMenu({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _items = [
    _PlaceCategoryItem(
      categoryName: '전체',
      displayLabel: '전체',
      icon: Icons.grid_view_rounded,
    ),
    _PlaceCategoryItem(
      categoryName: '유적·역사',
      displayLabel: '유적·역사',
      icon: Icons.fort_outlined,
    ),
    _PlaceCategoryItem(
      categoryName: '음식',
      displayLabel: '음식',
      icon: Icons.restaurant_outlined,
    ),
    _PlaceCategoryItem(
      categoryName: '카페·디저트',
      displayLabel: '카페',
      icon: Icons.local_cafe_outlined,
    ),
    _PlaceCategoryItem(
      categoryName: '자연·산책',
      displayLabel: '자연·산책',
      icon: Icons.park_outlined,
    ),
    _PlaceCategoryItem(
      categoryName: '문화·전시',
      displayLabel: '문화·전시',
      icon: Icons.account_balance_outlined,
    ),
    _PlaceCategoryItem(
      categoryName: '시장·상권',
      displayLabel: '시장',
      icon: Icons.storefront_outlined,
    ),
    _PlaceCategoryItem(
      categoryName: '소품샵',
      displayLabel: '소품샵',
      icon: Icons.shopping_bag_outlined,
    ),
  ];

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: ChaerokSpacing.xs),
        itemBuilder: (context, index) {
          return _CategoryMenuItem(
            item: _items[index],
            isSelected: selectedIndex == index,
            onTap: () => onSelected(index),
          );
        },
      ),
    );
  }
}

class _CategoryMenuItem extends StatefulWidget {
  const _CategoryMenuItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _PlaceCategoryItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_CategoryMenuItem> createState() => _CategoryMenuItemState();
}

class _CategoryMenuItemState extends State<_CategoryMenuItem> {
  bool _isHovered = false;
  bool _isPressed = false;

  Color get _backgroundColor {
    if (widget.isSelected) {
      if (_isPressed) {
        return Color.lerp(
          ChaerokColors.primary,
          ChaerokColors.primaryDark,
          0.18,
        )!;
      }
      return ChaerokColors.primary;
    }

    if (_isPressed) {
      return Color.alphaBlend(
        ChaerokColors.primaryDark.withValues(alpha: 0.06),
        ChaerokColors.sageLight,
      );
    }
    if (_isHovered) return ChaerokColors.categoryHover;
    return ChaerokColors.sageLight;
  }

  @override
  Widget build(BuildContext context) {
    final foregroundColor = widget.isSelected
        ? ChaerokColors.surface
        : ChaerokColors.primaryDark;

    return Semantics(
      label: widget.item.categoryName,
      button: true,
      selected: widget.isSelected,
      child: SizedBox(
        width: 60,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() {
            _isHovered = false;
            _isPressed = false;
          }),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _backgroundColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.item.icon,
                    color: foregroundColor,
                    size: 20,
                  ),
                ),
                const SizedBox(height: ChaerokSpacing.xs),
                SizedBox(
                  width: 60,
                  height: 15,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.item.displayLabel,
                      maxLines: 1,
                      style: ChaerokTypography.caption.copyWith(
                        color: widget.isSelected
                            ? ChaerokColors.primaryDark
                            : ChaerokColors.textSecondary,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceCategoryItem {
  const _PlaceCategoryItem({
    required this.categoryName,
    required this.displayLabel,
    required this.icon,
  });

  final String categoryName;
  final String displayLabel;
  final IconData icon;
}
