import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_shadows.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:flutter/material.dart';

class HomeCameraAction extends StatelessWidget {
  const HomeCameraAction({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: ChaerokShadows.floating,
      ),
      child: Material(
        color: ChaerokColors.primary,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const Icon(
            Icons.camera_alt_outlined,
            color: ChaerokColors.surface,
            size: ChaerokSpacing.lg,
          ),
        ),
      ),
    );
  }
}
