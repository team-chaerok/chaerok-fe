import 'package:flutter/material.dart';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';

class ChaerokButton extends StatelessWidget {
  const ChaerokButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = true,
    this.isEnabled = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: 52,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ChaerokColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ChaerokColors.border,
          disabledForegroundColor: ChaerokColors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ChaerokRadius.md),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: ChaerokSpacing.lg,
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
              ),
        ),
      ),
    );

    return button;
  }
}