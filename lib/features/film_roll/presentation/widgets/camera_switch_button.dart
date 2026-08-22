import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:flutter/material.dart';

/// 전/후면 카메라 전환 버튼.
class CameraSwitchButton extends StatelessWidget {
  const CameraSwitchButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChaerokColors.surface,
      shape: const CircleBorder(side: BorderSide(color: ChaerokColors.border)),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(
            Icons.cameraswitch_outlined,
            color: ChaerokColors.primaryDark,
            size: 22,
          ),
        ),
      ),
    );
  }
}
