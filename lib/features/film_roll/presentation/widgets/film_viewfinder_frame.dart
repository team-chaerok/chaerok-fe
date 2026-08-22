import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:flutter/material.dart';

/// 촬영 화면 중앙의 필름 카메라 뷰파인더 프레임. [child]로 전달된 카메라
/// 프리뷰를 둥근 모서리의 검은 베젤로 감싼다.
class FilmViewfinderFrame extends StatelessWidget {
  const FilmViewfinderFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ChaerokColors.cameraBlack,
        borderRadius: BorderRadius.circular(ChaerokRadius.lg),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
        child: child,
      ),
    );
  }
}
