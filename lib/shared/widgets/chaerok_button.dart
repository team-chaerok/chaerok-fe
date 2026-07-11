import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';

import 'package:flutter/material.dart';

class ChaerokButton extends StatelessWidget {
  const ChaerokButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isFullWidth = true,
    this.isEnabled = true,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isFullWidth;
  final bool isEnabled;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final button = SizedBox(
      height: 52,
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isEnabled && !isLoading ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: ChaerokColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: isLoading
              ? ChaerokColors.primary
              : ChaerokColors.border,
          disabledForegroundColor: isLoading
              ? Colors.white
              : ChaerokColors.textDisabled,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ChaerokRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.lg),
        ),
        child: isLoading
            ? const ChaerokLoadingIndicator(
                color: Colors.white,
                size: 20,
                strokeWidth: 2,
              )
            : Text(
                text,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
      ),
    );

    return button;
  }
}
