import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:flutter/material.dart';

/// 필름롤 카드의 장식 크롬. 크림색 카드 바탕 + 드롭 섀도우 위에, 우측 세로
/// 스프로킷 천공과 상단의 찢긴 결(deckle)을 [CustomPainter]로 근사한다.
/// 실제 필름 프레임 에셋(PNG/SVG)이 나오면 이 위젯만 교체하면 된다.
class FilmCardFrame extends StatelessWidget {
  const FilmCardFrame({super.key, required this.child, this.elevated = true});

  final Widget child;

  /// 열린 카드는 진한 그림자로 앞으로 떠 보이게, 그 외는 옅게.
  final bool elevated;

  /// Figma 근사. 토큰 없음.
  static const double _topRadius = ChaerokRadius.xl;

  /// 우측 스프로킷 천공이 차지하는 폭. 본문이 이 영역을 침범하지 않게 패딩한다.
  static const double _sprocketColumnWidth = 16;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ChaerokColors.primaryLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(_topRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: elevated ? 0.12 : 0.06),
            blurRadius: elevated ? 16 : 6, // Figma 근사. 토큰 없음.
            offset: Offset(0, elevated ? -2 : 2), // Figma 근사. 토큰 없음.
          ),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: const _FilmEdgePainter(),
        child: Padding(
          padding: const EdgeInsets.only(right: _sprocketColumnWidth),
          child: child,
        ),
      ),
    );
  }
}

/// 우측 세로 스프로킷 천공 + 상단 찢긴 결을 배경색으로 "뚫어" 근사한다.
class _FilmEdgePainter extends CustomPainter {
  const _FilmEdgePainter();

  static const double _columnWidth = 16;
  static const double _holeWidth = 5;
  static const double _holeHeight = 8;
  static const double _holeGap = 9;
  static const double _edgeInset = 12;
  static const double _notchWidth = 12;
  static const double _notchDepth = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = ChaerokColors.background;

    // 우측 세로 스프로킷 천공.
    final holeX = size.width - _columnWidth + (_columnWidth - _holeWidth) / 2;
    for (
      var y = _edgeInset;
      y + _holeHeight <= size.height - _edgeInset;
      y += _holeHeight + _holeGap
    ) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(holeX, y, _holeWidth, _holeHeight),
          const Radius.circular(1.5),
        ),
        paint,
      );
    }

    // 상단 찢긴 결 — 얕은 삼각 노치를 배경색으로 덮는다.
    final notches = Path()..moveTo(0, 0);
    for (var x = 0.0; x < size.width; x += _notchWidth) {
      notches
        ..lineTo(x + _notchWidth / 2, _notchDepth)
        ..lineTo(x + _notchWidth, 0);
    }
    notches
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(notches, paint);
  }

  @override
  bool shouldRepaint(_FilmEdgePainter oldDelegate) => false;
}
