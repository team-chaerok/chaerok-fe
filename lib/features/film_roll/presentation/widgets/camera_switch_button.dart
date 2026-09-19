import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// 전/후면 카메라 전환 버튼.
class CameraSwitchButton extends StatelessWidget {
  const CameraSwitchButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  /// Figma 버튼 배경 색(#e8ebde) · 테두리 색(#dadada).
  static const _backgroundColor = Color(0xFFE8EBDE);
  static const _borderColor = Color(0xFFDADADA);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _backgroundColor,
      shape: const CircleBorder(side: BorderSide(color: _borderColor)),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: SizedBox(
            width: 22,
            height: 22,
            child: SvgPicture.asset(
              'assets/images/chaerok-camera-icon-exchange.svg',
            ),
          ),
        ),
      ),
    );
  }
}
