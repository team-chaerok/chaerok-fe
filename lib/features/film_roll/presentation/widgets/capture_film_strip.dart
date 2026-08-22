import 'package:camera/camera.dart';
import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:flutter/material.dart';

/// 화면 최하단의 라이브 프리뷰 필름 스트립.
/// 과거에 촬영한 사진 목록이 아니라, 지금 카메라가 보고 있는 화면을
/// 필름 프레임 형태로 이어 붙여 보여준다.
class CaptureFilmStrip extends StatelessWidget {
  const CaptureFilmStrip({super.key, required this.controller});

  final CameraController controller;

  static const _frameCount = 5;

  @override
  Widget build(BuildContext context) {
    final previewSize = controller.value.previewSize;

    return SizedBox(
      width: 356,
      child: Row(
        children: [
          for (var i = 0; i < _frameCount; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ChaerokRadius.sm),
                child: ColoredBox(
                  color: ChaerokColors.cameraBlack,
                  child: previewSize == null
                      ? null
                      : FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: previewSize.height,
                            height: previewSize.width,
                            child: CameraPreview(controller),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
