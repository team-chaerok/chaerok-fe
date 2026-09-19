import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:flutter/material.dart';

/// 촬영 화면 중앙의 필름 카메라 뷰파인더 프레임. [child]로 전달된 카메라
/// 프리뷰를 둥근 모서리의 올리브색 베젤로 감싼다.
class FilmViewfinderFrame extends StatelessWidget {
  const FilmViewfinderFrame({super.key, required this.child});

  final Widget child;

  /// Figma 뷰파인더 베젤 색(#52523d).
  static const _frameColor = Color(0xFF52523D);

  /// Figma 뷰파인더 내부 화면 색(#111).
  static const _screenColor = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _frameColor,
        borderRadius: BorderRadius.circular(ChaerokRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            offset: Offset(0, 3),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ChaerokRadius.lg),
        child: ColoredBox(color: _screenColor, child: child),
      ),
    );
  }
}
