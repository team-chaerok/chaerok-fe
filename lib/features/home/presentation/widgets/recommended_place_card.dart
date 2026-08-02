import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_shadows.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:flutter/material.dart';

class RecommendedPlaceCard extends StatelessWidget {
  const RecommendedPlaceCard({
    super.key,
    required this.data,
    required this.onTap,
    this.isFeatured = false,
  });

  final RecommendedPlaceSummaryData data;
  final VoidCallback onTap;
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ChaerokColors.surface,
      borderRadius: BorderRadius.circular(ChaerokRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ChaerokRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: ChaerokColors.surface,
            border: Border.all(color: ChaerokColors.border),
            borderRadius: BorderRadius.circular(ChaerokRadius.lg),
            boxShadow: isFeatured ? ChaerokShadows.card : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(ChaerokRadius.lg),
            child: isFeatured ? _buildFeatured() : _buildCompact(),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatured() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 2,
          child: _PlaceImagePlaceholder(mood: data.placeholderMood),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ChaerokSpacing.sm,
            ChaerokSpacing.xs,
            ChaerokSpacing.sm,
            ChaerokSpacing.sm,
          ),
          child: _PlaceInformation(data: data),
        ),
      ],
    );
  }

  Widget _buildCompact() {
    return SizedBox(
      height: 76,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: _PlaceImagePlaceholder(mood: data.placeholderMood),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: ChaerokSpacing.sm,
                vertical: ChaerokSpacing.xs,
              ),
              child: _PlaceInformation(data: data),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: ChaerokSpacing.sm),
            child: Icon(
              Icons.chevron_right_rounded,
              color: ChaerokColors.textSecondary,
              size: ChaerokSpacing.lg,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceInformation extends StatelessWidget {
  const _PlaceInformation({required this.data});

  final RecommendedPlaceSummaryData data;

  @override
  Widget build(BuildContext context) {
    final distance = data.distance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ChaerokTypography.headingMedium,
        ),
        const SizedBox(height: ChaerokSpacing.xxs),
        Row(
          children: [
            Flexible(
              child: Text(
                data.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ChaerokTypography.labelSmall.copyWith(
                  color: ChaerokColors.textSecondary,
                ),
              ),
            ),
            if (distance != null) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: ChaerokSpacing.xs),
                child: SizedBox(
                  width: 2,
                  height: 2,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: ChaerokColors.textSecondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Text(
                distance,
                style: ChaerokTypography.labelSmall.copyWith(
                  color: ChaerokColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PlaceImagePlaceholder extends StatelessWidget {
  const _PlaceImagePlaceholder({required this.mood});

  final PlacePlaceholderMood mood;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '여행 사진이 들어갈 자리',
      image: true,
      child: CustomPaint(painter: _SummerTownPainter(mood)),
    );
  }
}

class _SummerTownPainter extends CustomPainter {
  const _SummerTownPainter(this.mood);

  final PlacePlaceholderMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final skyPaint = Paint()..color = ChaerokColors.skyBlue;
    final sunlightPaint = Paint()
      ..color = ChaerokColors.surface.withValues(alpha: 0.72);
    final distantGreenPaint = Paint()
      ..color = ChaerokColors.sage.withValues(alpha: 0.78);
    final deepGreenPaint = Paint()
      ..color = ChaerokColors.primary.withValues(alpha: 0.82);
    final groundPaint = Paint()..color = ChaerokColors.sageLight;
    final pathPaint = Paint()
      ..color = ChaerokColors.surface.withValues(alpha: 0.82);
    final waterPaint = Paint()
      ..color = ChaerokColors.skyBlue.withValues(alpha: 0.72);
    final wallPaint = Paint()
      ..color = ChaerokColors.surface.withValues(alpha: 0.92);

    canvas.drawRect(Offset.zero & size, skyPaint);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      size.shortestSide * 0.09,
      sunlightPaint,
    );

    final hill = Path()
      ..moveTo(0, size.height * 0.52)
      ..quadraticBezierTo(
        size.width * 0.22,
        size.height * 0.34,
        size.width * 0.48,
        size.height * 0.5,
      )
      ..quadraticBezierTo(
        size.width * 0.74,
        size.height * 0.3,
        size.width,
        size.height * 0.48,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hill, distantGreenPaint);

    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.62, size.width, size.height * 0.38),
      groundPaint,
    );

    switch (mood) {
      case PlacePlaceholderMood.stream:
        final stream = Path()
          ..moveTo(size.width * 0.3, size.height)
          ..quadraticBezierTo(
            size.width * 0.54,
            size.height * 0.73,
            size.width * 0.44,
            size.height * 0.58,
          )
          ..lineTo(size.width * 0.58, size.height * 0.58)
          ..quadraticBezierTo(
            size.width * 0.7,
            size.height * 0.76,
            size.width * 0.68,
            size.height,
          )
          ..close();
        canvas.drawPath(stream, waterPaint);
        break;
      case PlacePlaceholderMood.wall:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              size.width * 0.18,
              size.height * 0.56,
              size.width * 0.64,
              size.height * 0.22,
            ),
            const Radius.circular(ChaerokRadius.sm),
          ),
          wallPaint,
        );
        canvas.drawRect(
          Rect.fromLTWH(
            size.width * 0.48,
            size.height * 0.43,
            size.width * 0.13,
            size.height * 0.17,
          ),
          deepGreenPaint,
        );
        break;
      case PlacePlaceholderMood.forest:
        final trail = Path()
          ..moveTo(size.width * 0.35, size.height)
          ..lineTo(size.width * 0.48, size.height * 0.58)
          ..lineTo(size.width * 0.58, size.height * 0.58)
          ..lineTo(size.width * 0.72, size.height)
          ..close();
        canvas.drawPath(trail, pathPaint);
        break;
    }

    _drawTree(canvas, size, size.width * 0.12, 0.52, deepGreenPaint);
    _drawTree(canvas, size, size.width * 0.88, 0.48, deepGreenPaint);
    _drawTree(canvas, size, size.width * 0.77, 0.61, distantGreenPaint);
  }

  void _drawTree(
    Canvas canvas,
    Size size,
    double x,
    double baseHeight,
    Paint foliagePaint,
  ) {
    final trunkPaint = Paint()
      ..color = ChaerokColors.primaryDark.withValues(alpha: 0.46);
    canvas.drawRect(
      Rect.fromLTWH(x - 2, size.height * baseHeight, 4, size.height * 0.24),
      trunkPaint,
    );
    canvas.drawCircle(
      Offset(x, size.height * baseHeight),
      size.shortestSide * 0.14,
      foliagePaint,
    );
    canvas.drawCircle(
      Offset(x + size.width * 0.05, size.height * (baseHeight + 0.04)),
      size.shortestSide * 0.1,
      foliagePaint,
    );
  }

  @override
  bool shouldRepaint(_SummerTownPainter oldDelegate) {
    return oldDelegate.mood != mood;
  }
}
