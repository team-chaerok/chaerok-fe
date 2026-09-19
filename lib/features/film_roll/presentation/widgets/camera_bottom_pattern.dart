import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// 촬영 화면 좌측 가장자리를 따라 깔리는 장식용 블롭 패턴.
/// 실제 화면 좌표계(회전 전) 기준으로 배치되므로 [RotatedBox] 바깥,
/// 즉 [Scaffold.body]의 최하단 레이어에 둬야 한다.
class CameraBottomPattern extends StatelessWidget {
  const CameraBottomPattern({super.key});

  /// Figma 원본 뷰박스 비율 (239 x 852). 화면 왼쪽 가장자리에 전체 높이로 붙는다.
  static const double _aspectRatio = 239 / 852;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.centerLeft,
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: SvgPicture.asset(
            'assets/images/chaerok-camera-bottom-pattern.svg',
            fit: BoxFit.fitHeight,
            alignment: Alignment.centerLeft,
          ),
        ),
      ),
    );
  }
}
