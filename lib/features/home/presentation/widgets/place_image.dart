import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:flutter/material.dart';

/// 관광지 대표 사진을 채워 넣되, URL이 없거나 로딩에 실패하면
/// [mood] 기반 일러스트([PlaceImagePlaceholder])로 폴백한다.
class PlaceImage extends StatelessWidget {
  const PlaceImage({super.key, required this.imageUrl, required this.mood});

  final String? imageUrl;
  final PlacePlaceholderMood mood;

  /// TourAPI가 내려주는 `http://tong.visitkorea.or.kr/...` 는 cleartext라
  /// Android 9+ 기본 설정에서 차단된다. 동일 호스트가 https도 제공하므로
  /// 스킴을 올려서 로드한다. 빈 문자열/null 은 null 로 정규화한다.
  static String? _normalized(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://')) {
      return 'https://${trimmed.substring('http://'.length)}';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = PlaceImagePlaceholder(mood: mood);
    final url = _normalized(imageUrl);
    if (url == null) return placeholder;

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      semanticLabel: '관광지 대표 사진',
      errorBuilder: (context, error, stackTrace) => placeholder,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: ChaerokColors.sageLight,
          child: Center(
            child: SizedBox(
              width: ChaerokSpacing.lg,
              height: ChaerokSpacing.lg,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ChaerokColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class PlaceImagePlaceholder extends StatelessWidget {
  const PlaceImagePlaceholder({super.key, required this.mood});

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
      ..color = ChaerokColors.primary.withValues(alpha: 0.78);
    final deepGreenPaint = Paint()
      ..color = ChaerokColors.primaryDark.withValues(alpha: 0.82);
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
