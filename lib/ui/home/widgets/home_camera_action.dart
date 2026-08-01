import 'package:chaerok/ui/preview_theme.dart';
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
        boxShadow: UiPreviewShadows.floating,
      ),
      child: Material(
        color: UiPreviewColors.primary,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: const Icon(
            Icons.camera_alt_outlined,
            color: UiPreviewColors.surface,
            size: UiPreviewSpacing.lg,
          ),
        ),
      ),
    );
  }
}
