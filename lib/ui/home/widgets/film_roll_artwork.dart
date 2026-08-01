import 'package:chaerok/ui/preview_theme.dart';
import 'package:flutter/material.dart';

/// Temporary artwork slot for the future film-roll PNG or SVG asset.
class FilmRollArtwork extends StatelessWidget {
  const FilmRollArtwork({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 84,
      child: Center(
        child: Container(
          width: 58,
          height: 68,
          decoration: BoxDecoration(
            color: UiPreviewColors.surface.withValues(alpha: 0.48),
            border: Border.all(
              color: UiPreviewColors.primary.withValues(alpha: 0.34),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(UiPreviewRadius.md),
          ),
          child: Center(
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: UiPreviewColors.primary.withValues(alpha: 0.68),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
