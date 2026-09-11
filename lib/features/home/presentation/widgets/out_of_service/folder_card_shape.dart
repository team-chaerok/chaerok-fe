import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:flutter/material.dart';

/// `Rectangle 34626670.svg`의 폴더 탭 카드 실루엣.
/// 왼쪽 탭이 [cardTop]만큼 위로 튀어나오고, 탭 오른쪽은 경사(대각선) →
/// 오목 이음으로 본문 상단에 붙는다. 모서리는 모두 [_r]. 탭 형상은 절대
/// 픽셀 값이라 카드 폭이 커져도 그대로다.
class FolderCardClipper extends CustomClipper<Path> {
  const FolderCardClipper();

  /// 탭이 본문 위로 튀어나온 높이. 겹친 카드가 아래로 밀리는 y 간격도 이 값을 쓴다.
  static const double cardTop = 32;

  static const double _r = ChaerokRadius.lg; // 16

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;

    return Path()
      ..moveTo(0, _r)
      ..arcToPoint(const Offset(_r, 0), radius: const Radius.circular(_r))
      // 탭 상단 직선
      ..lineTo(147, 0)
      // 탭 오른쪽 위 라운딩
      ..cubicTo(152.36, 0, 157.37, 2.69, 160.33, 7.16)
      // 탭 오른쪽 경사
      ..lineTo(172.01, 24.8)
      // 탭 → 본문 상단 오목 이음
      ..cubicTo(174.98, 29.27, 179.99, cardTop, 185.35, cardTop)
      // 본문 상단
      ..lineTo(w - _r, cardTop)
      ..arcToPoint(Offset(w, cardTop + _r), radius: const Radius.circular(_r))
      // 오른쪽 변
      ..lineTo(w, h - _r)
      ..arcToPoint(Offset(w - _r, h), radius: const Radius.circular(_r))
      // 아래 변
      ..lineTo(_r, h)
      ..arcToPoint(Offset(0, h - _r), radius: const Radius.circular(_r))
      ..close();
  }

  @override
  bool shouldReclip(FolderCardClipper oldClipper) => false;
}

/// 폴더 카드 외곽선을 따라 드롭 섀도우를 그린다([ClipPath]는 그림자를
/// 만들지 않으므로 별도로 얹는다). Figma 스펙: Offset(0, -2), Blur 16,
/// black 8%. 모든 카드(열림/겹침)에 동일하게 적용한다.
class FolderCardShadowPainter extends CustomPainter {
  const FolderCardShadowPainter();

  static const Offset _offset = Offset(0, -2);
  static const double _blur = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final path = const FolderCardClipper().getClip(size);
    canvas.drawPath(
      path.shift(_offset),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.08)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          Shadow.convertRadiusToSigma(_blur),
        ),
    );
  }

  @override
  bool shouldRepaint(FolderCardShadowPainter oldDelegate) => false;
}

/// 폴더 카드 안쪽 상단 모서리에 얹는 이너 섀도우.
/// Figma 스펙: Offset(0, 1), Blur 1, white 25%. 카드 형상으로 클립한 뒤
/// "형상 바깥" 영역을 오프셋·블러해 그려 가장자리 안쪽으로만 번지게 한다.
class FolderCardInnerShadowPainter extends CustomPainter {
  const FolderCardInnerShadowPainter();

  static const Offset _offset = Offset(0, 1);
  static const double _blur = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final path = const FolderCardClipper().getClip(size);

    canvas.save();
    canvas.clipPath(path);

    // 큰 사각형 XOR 카드 형상 = 형상 바깥 영역. 이걸 오프셋·블러해 그리면
    // 클립 덕분에 가장자리 안쪽으로 번진 부분만 남아 이너 섀도우가 된다.
    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(
        Rect.fromLTRB(
          -size.width,
          -size.height,
          size.width * 2,
          size.height * 2,
        ),
      )
      ..addPath(path, Offset.zero);

    canvas.drawPath(
      outside.shift(_offset),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          Shadow.convertRadiusToSigma(_blur),
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(FolderCardInnerShadowPainter oldDelegate) => false;
}

/// 사각형(캔버스 전체 크기)에 이너 섀도우를 그리는 범용 페인터.
/// [FolderCardInnerShadowPainter]와 같은 기법(형상 바깥 영역을 오프셋·블러)을
/// 임의의 offset/blur/color로 재사용하려는 작은 사각 요소용. 모서리가 아주
/// 작게 둥근 경우([ClipRRect]로 외부에서 클리핑) 반경 차이는 무시할 만해
/// 내부적으로는 직각 사각형으로 계산한다.
class RectInnerShadowPainter extends CustomPainter {
  const RectInnerShadowPainter({
    required this.offset,
    required this.blur,
    required this.color,
  });

  final Offset offset;
  final double blur;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.save();
    canvas.clipRect(rect);

    final outside = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(
        Rect.fromLTRB(
          -size.width,
          -size.height,
          size.width * 2,
          size.height * 2,
        ),
      )
      ..addRect(rect);

    canvas.drawPath(
      outside.shift(offset),
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          Shadow.convertRadiusToSigma(blur),
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RectInnerShadowPainter oldDelegate) =>
      oldDelegate.offset != offset ||
      oldDelegate.blur != blur ||
      oldDelegate.color != color;
}
