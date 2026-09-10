import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:flutter/material.dart';

class TestCardScreen extends StatefulWidget {
  const TestCardScreen({super.key});

  @override
  State<TestCardScreen> createState() => _TestCardScreenState();
}

class _TestCardScreenState extends State<TestCardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: const Stack(
        clipBehavior: Clip.none,
        // 뒤 → 앞으로 갈수록 32씩 아래로, 좌우 패딩은 4씩 줄어든다.
        children: [
          Positioned.fill(
            child: _FolderCard(
              folderColor: Colors.pink,
              topInset: 0,
              horizontalInset: 12,
            ),
          ),
          Positioned.fill(
            child: _FolderCard(
              folderColor: Colors.yellow,
              topInset: 32,
              horizontalInset: 8,
            ),
          ),
          Positioned.fill(
            child: _FolderCard(
              folderColor: Colors.purpleAccent,
              topInset: 64,
              horizontalInset: 4,
            ),
          ),
          Positioned.fill(
            child: _FolderCard(
              folderColor: Colors.tealAccent,
              topInset: 96,
              isFirst: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  const _FolderCard({
    required this.folderColor,
    required this.topInset,
    this.horizontalInset = 0,
    this.isFirst = false,
  });

  final Color folderColor;
  final double topInset;
  final double horizontalInset;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    // Padding은 음수를 못 받으므로(RenderPadding assert) 위/아래 이동은
    // Transform.translate로 처리한다. topInset<0이면 카드가 위로 올라간다.
    return Transform.translate(
      offset: Offset(0, topInset),
      child: Padding(
        padding: EdgeInsets.only(
          left: horizontalInset,
          right: horizontalInset,
          bottom: 24,
        ),
        // ClipPath + 별도 그림자. PhysicalShape를 Stack/Positioned 안에서 쓰면
        // semantics parentData assertion이 간헐적으로 터진다.
        child: CustomPaint(
          painter: const _FolderCardShadowPainter(),
          child: ClipPath(
            clipper: const _FolderCardClipper(),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: folderColor),
                const Positioned(
                  top: 32,
                  right: 0,
                  width: 150,
                  height: 80,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(ChaerokRadius.lg),
                      ),
                    ),
                  ),
                ),
                isFirst
                    ? Positioned(
                        top: 32,
                        child: Container(
                          // width: double.infinity,
                          width: 393,
                          height: 567,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(ChaerokRadius.lg),
                              topRight: Radius.circular(ChaerokRadius.lg),
                            ),
                          ),
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `Rectangle 34626670.svg`의 폴더 탭 카드 실루엣.
/// 왼쪽 탭이 [_cardTop]만큼 위로 튀어나오고, 탭 오른쪽은 경사(대각선) →
/// 오목 이음으로 본문 상단에 붙는다. 모서리는 모두 [_r]. 탭 형상은 절대
/// 픽셀 값이라 카드 폭이 커져도 그대로다.
class _FolderCardClipper extends CustomClipper<Path> {
  const _FolderCardClipper();

  static const double _r = 16; // 모든 모서리 반경
  static const double _cardTop = 32; // 탭이 본문 위로 튀어나온 높이

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
      ..cubicTo(174.98, 29.27, 179.99, _cardTop, 185.35, _cardTop)
      // 본문 상단
      ..lineTo(w - _r, _cardTop)
      ..arcToPoint(Offset(w, _cardTop + _r), radius: const Radius.circular(_r))
      // 오른쪽 변
      ..lineTo(w, h - _r)
      ..arcToPoint(Offset(w - _r, h), radius: const Radius.circular(_r))
      // 아래 변
      ..lineTo(_r, h)
      ..arcToPoint(Offset(0, h - _r), radius: const Radius.circular(_r))
      ..close();
  }

  @override
  bool shouldReclip(_FolderCardClipper oldClipper) => false;
}

/// 폴더 카드 외곽선을 따라 드롭 섀도우를 그린다([ClipPath]는 그림자를
/// 만들지 않으므로 별도로 얹는다).
class _FolderCardShadowPainter extends CustomPainter {
  const _FolderCardShadowPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawShadow(
      const _FolderCardClipper().getClip(size),
      Colors.black,
      3,
      false,
    );
  }

  @override
  bool shouldRepaint(_FolderCardShadowPainter oldDelegate) => false;
}
