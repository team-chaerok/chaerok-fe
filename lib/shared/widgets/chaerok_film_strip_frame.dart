import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:flutter/material.dart';

/// 검은 필름 띠 위아래에 스프라켓 구멍을 두른 필름 스트립 틀. [child]에는
/// 필름 칸(사진)들을 넣는다. 홈 필름롤 갤러리와 현상 결과 사진에서 같은
/// 필름 모양을 쓰기 위한 공통 틀이다.
class ChaerokFilmStripFrame extends StatelessWidget {
  const ChaerokFilmStripFrame({
    super.key,
    required this.child,
    this.holeColor = ChaerokColors.background,
  });

  static const double _edgeHeight = 4;

  final Widget child;

  /// 스프라켓 구멍 색. 필름 뒤로 비치는 화면 배경색과 맞춘다.
  final Color holeColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ChaerokColors.cameraBlack,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: _edgeHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ChaerokFilmSprocketRow(holeColor: holeColor),
            const SizedBox(height: ChaerokSpacing.xxs),
            child,
            const SizedBox(height: ChaerokSpacing.xxs),
            ChaerokFilmSprocketRow(holeColor: holeColor),
          ],
        ),
      ),
    );
  }
}

/// 필름 가장자리의 스프라켓 구멍 한 줄. 가용 너비에 맞춰 개수를 계산해
/// 고르게 채운다.
class ChaerokFilmSprocketRow extends StatelessWidget {
  const ChaerokFilmSprocketRow({
    super.key,
    this.holeColor = ChaerokColors.background,
  });

  static const double _holeWidth = 8;
  static const double _holeHeight = 4;
  static const double _pitch = 20;

  final Color holeColor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final holeCount = (constraints.maxWidth / _pitch).floor();
        return SizedBox(
          height: _holeHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < holeCount; i++)
                SizedBox(
                  width: _holeWidth,
                  height: _holeHeight,
                  child: ColoredBox(color: holeColor),
                ),
            ],
          ),
        );
      },
    );
  }
}
