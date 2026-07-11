import 'package:chaerok/core/design_system/chaerok_colors.dart';

import 'package:flutter/material.dart';

class ChaerokLoadingIndicator extends StatelessWidget {
  const ChaerokLoadingIndicator({
    super.key,
    this.color = ChaerokColors.primary,
    this.size,
    this.strokeWidth = 4.0,
  });

  final Color color;
  final double? size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final indicator = CircularProgressIndicator(
      color: color,
      strokeWidth: strokeWidth,
    );

    if (size == null) return indicator;

    return SizedBox(width: size, height: size, child: indicator);
  }
}
