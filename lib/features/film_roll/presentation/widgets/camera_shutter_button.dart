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

  /// Figma 셔터 버튼 바깥 링 색(#7d8a6b).
  static const _ringColor = Color(0xFF7D8A6B);

  /// Figma 셔터 버튼 안쪽 원 색(#c8d5b4).
  static const _innerColor = Color(0xFFC8D5B4);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: 72,
        height: 72,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: _ringColor,
          boxShadow: [
            BoxShadow(
              color: Color(0x40000000),
              offset: Offset(0, 3),
              blurRadius: 6,
            ),
          ],
        ),
        child: isLoading
            ? const ChaerokLoadingIndicator(
                color: Colors.white,
                size: 28,
                strokeWidth: 2.5,
              )
            : Container(
                width: 65,
                height: 65,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _innerColor,
                ),
              ),
      ),
    );
  }
}
