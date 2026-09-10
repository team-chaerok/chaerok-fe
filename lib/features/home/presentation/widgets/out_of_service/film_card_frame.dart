import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:flutter/material.dart';

/// 필름롤 카드의 장식 크롬. 크림색 카드 바탕 + 드롭 섀도우에 우측 세로 스프로킷
/// 천공을 얹는다. [folderTop]이면 상단을 "폴더 탭" 실루엣(왼쪽 탭이 위로
/// 튀어나오고 본문 상단이 오목하게 이어짐)으로 클리핑한다.
class FilmCardFrame extends StatelessWidget {
  const FilmCardFrame({
    super.key,
    required this.child,
    this.elevated = true,
    this.folderTop = false,
  });

  final Widget child;

  /// 열린 카드는 진한 그림자로 앞으로 떠 보이게, 그 외는 옅게.
  final bool elevated;

  /// 상단을 폴더 탭 모양으로 자를지. 보통 열린(맨 앞) 카드에만 쓴다.
  final bool folderTop;

  /// Figma 근사. 토큰 없음.
  static const double _topRadius = ChaerokRadius.xl;

  /// 우측 스프로킷 천공이 차지하는 폭. 본문이 이 영역을 침범하지 않게 패딩한다.
  static const double _sprocketColumnWidth = 16;

  @override
  Widget build(BuildContext context) {
    final content = CustomPaint(
      foregroundPainter: const _SprocketColumnPainter(),
      child: Padding(
        padding: const EdgeInsets.only(right: _sprocketColumnWidth),
        child: child,
      ),
    );

    if (folderTop) {
      // PhysicalShape 대신 ClipPath + 별도 그림자. PhysicalShape를 애니메이션
      // 중인 Stack/Positioned/Transform 안에 두면 semantics parentData 관련
      // 프레임워크 assertion이 간헐적으로 터진다.
      return CustomPaint(
        painter: _FolderShadowPainter(elevation: elevated ? 10 : 3),
        child: ClipPath(
          clipper: const _FolderTabClipper(),
          clipBehavior: Clip.antiAlias,
          child: ColoredBox(color: ChaerokColors.primaryLight, child: content),
        ),
      );
    }

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
      child: content,
    );
  }
}

/// 카드 상단을 파일 폴더 탭 모양으로 자른다. 왼쪽 절반쯤이 [_tabHeight]만큼
/// 위로 튀어나오고, 그 오른쪽은 오목한 필렛으로 본문 상단에 이어진다.
class _FolderTabClipper extends CustomClipper<Path> {
  const _FolderTabClipper();

  /// = FilmTab.tabHeight. 탭이 본문 위로 튀어나오는 높이.
  static const double _tabHeight = 36;

  /// 일반 모서리 반경.
  static const double _corner = ChaerokRadius.lg;

  /// 본문 상단 오른쪽 모서리 반경.
  static const double _bodyTopCorner = ChaerokRadius.xl;

  /// 탭 오른쪽 → 본문 상단 오목 이음 반경.
  static const double _fillet = 14;

  @override
  Path getClip(Size size) {
    final w = size.width;
    final h = size.height;
    final tabW = (w * 0.52).clamp(
      _corner * 4,
      w - _bodyTopCorner - _fillet - 8,
    );

    return Path()
      ..moveTo(0, _corner)
      ..arcToPoint(
        const Offset(_corner, 0),
        radius: const Radius.circular(_corner),
      ) // 탭 좌상
      ..lineTo(tabW - _corner, 0)
      ..arcToPoint(
        Offset(tabW, _corner),
        radius: const Radius.circular(_corner),
      ) // 탭 우상
      ..lineTo(tabW, _tabHeight - _fillet)
      ..arcToPoint(
        Offset(tabW + _fillet, _tabHeight),
        radius: const Radius.circular(_fillet),
        clockwise: false,
      ) // 탭 → 본문 오목 이음
      ..lineTo(w - _bodyTopCorner, _tabHeight)
      ..arcToPoint(
        Offset(w, _tabHeight + _bodyTopCorner),
        radius: const Radius.circular(_bodyTopCorner),
      ) // 본문 우상
      ..lineTo(w, h - _corner)
      ..arcToPoint(
        Offset(w - _corner, h),
        radius: const Radius.circular(_corner),
      ) // 우하
      ..lineTo(_corner, h)
      ..arcToPoint(
        Offset(0, h - _corner),
        radius: const Radius.circular(_corner),
      ) // 좌하
      ..close();
  }

  @override
  bool shouldReclip(_FolderTabClipper oldClipper) => false;
}

/// 폴더 탭 외곽선을 따라 머티리얼식 드롭 섀도우를 그린다([ClipPath]는 그림자를
/// 만들지 않으므로 별도로 얹는다).
class _FolderShadowPainter extends CustomPainter {
  const _FolderShadowPainter({required this.elevation});

  final double elevation;

  @override
  void paint(Canvas canvas, Size size) {
    final path = const _FolderTabClipper().getClip(size);
    canvas.drawShadow(path, Colors.black, elevation, false);
  }

  @override
  bool shouldRepaint(_FolderShadowPainter oldDelegate) =>
      oldDelegate.elevation != elevation;
}

/// 우측 세로 스프로킷 천공을 배경색으로 "뚫어" 근사한다.
class _SprocketColumnPainter extends CustomPainter {
  const _SprocketColumnPainter();

  static const double _columnWidth = 16;
  static const double _holeWidth = 5;
  static const double _holeHeight = 8;
  static const double _holeGap = 9;
  static const double _edgeInset = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = ChaerokColors.background;
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
  }

  @override
  bool shouldRepaint(_SprocketColumnPainter oldDelegate) => false;
}
