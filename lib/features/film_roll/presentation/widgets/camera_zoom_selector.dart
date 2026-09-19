import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:flutter/material.dart';

/// Figma 셀렉터 배경 색(#e5e7d8).
const _kSelectorBackground = Color(0xFFE5E7D8);

/// Figma 선택 배율 강조 원 색(#d7dcc4).
const _kSelectedZoomBackground = Color(0xFFD7DCC4);

/// 촬영 화면 우측의 줌 배율 선택 UI. [availableZoomLevels]에 담긴 배율만
/// 선택 가능하며(기기가 지원하지 않는 배율은 상위에서 제외한다),
/// [selectedZoomLevel]이 현재 활성 배율을 표시한다.
class CameraZoomSelector extends StatelessWidget {
  const CameraZoomSelector({
    super.key,
    required this.availableZoomLevels,
    required this.selectedZoomLevel,
    required this.onZoomSelected,
  });

  final List<double> availableZoomLevels;
  final double selectedZoomLevel;
  final ValueChanged<double> onZoomSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: ChaerokSpacing.xs),
      decoration: BoxDecoration(
        color: _kSelectorBackground,
        borderRadius: BorderRadius.circular(ChaerokRadius.full),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final zoom in availableZoomLevels)
            _ZoomOption(
              zoom: zoom,
              isSelected: zoom == selectedZoomLevel,
              onTap: () => onZoomSelected(zoom),
            ),
        ],
      ),
    );
  }
}

class _ZoomOption extends StatelessWidget {
  const _ZoomOption({
    required this.zoom,
    required this.isSelected,
    required this.onTap,
  });

  final double zoom;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: ChaerokSpacing.xs,
          vertical: ChaerokSpacing.xxs,
        ),
        padding: const EdgeInsets.all(ChaerokSpacing.xs),
        decoration: BoxDecoration(
          color: isSelected ? _kSelectedZoomBackground : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          '${_formatZoom(zoom)}x',
          style: ChaerokTypography.caption.copyWith(
            color: ChaerokColors.sageDark,
          ),
        ),
      ),
    );
  }

  String _formatZoom(double zoom) {
    return zoom == zoom.roundToDouble()
        ? zoom.toStringAsFixed(0)
        : zoom.toStringAsFixed(1);
  }
}
