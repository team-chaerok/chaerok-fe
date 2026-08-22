import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';

/// 원형 셔터 버튼. [isLoading]이면 저장 중 상태를 스피너로 표시하고 비활성화된다.
class CameraShutterButton extends StatelessWidget {
  const CameraShutterButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  final VoidCallback onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: ChaerokColors.surface,
          border: Border.all(color: ChaerokColors.primary, width: 4),
        ),
        child: isLoading
            ? const ChaerokLoadingIndicator(
                color: ChaerokColors.primary,
                size: 28,
                strokeWidth: 2.5,
              )
            : Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ChaerokColors.primaryLight,
                ),
              ),
      ),
    );
  }
}
