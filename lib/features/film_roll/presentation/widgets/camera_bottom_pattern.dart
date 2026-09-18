import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// 촬영 화면 하단 좌우에 깔리는 장식용 블롭 패턴.
/// 실제 화면 좌표계(회전 전) 기준으로 배치되므로 [RotatedBox] 바깥,
/// 즉 [Scaffold.body]의 최하단 레이어에 둬야 한다.
class CameraBottomPattern extends StatelessWidget {
  const CameraBottomPattern({super.key});

  /// Figma 원본 뷰박스 비율 (852 x 249).
  static const double _aspectRatio = 852 / 249;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AspectRatio(
          aspectRatio: _aspectRatio,
          child: SvgPicture.asset(
            'assets/images/camera_bottom_pattern.svg',
            fit: BoxFit.fitWidth,
            alignment: Alignment.bottomCenter,
          ),
        ),
      ),
    );
  }
}
