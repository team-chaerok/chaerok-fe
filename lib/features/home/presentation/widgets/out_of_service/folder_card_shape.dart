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
/// 만들지 않으므로 별도로 얹는다).
class FolderCardShadowPainter extends CustomPainter {
  const FolderCardShadowPainter({this.elevation = 3});

  final double elevation;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(
      const FolderCardClipper().getClip(size),
      Colors.black,
      elevation,
      false,
    );
  }

  @override
  bool shouldRepaint(FolderCardShadowPainter oldDelegate) =>
      oldDelegate.elevation != elevation;
}
