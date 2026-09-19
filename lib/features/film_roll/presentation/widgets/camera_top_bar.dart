import 'package:camera/camera.dart';
import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// Figma 촬영 매수 배지 배경 색(rgba(215,220,196,0.56)).
const _kCounterBackground = Color(0x8FD7DCC4);

/// Figma 닫기 버튼 배경 색(rgba(215,220,196,0.56)) · 테두리 색(#dadada).
const _kCloseBackground = Color(0x8FD7DCC4);
const _kCloseBorder = Color(0xFFDADADA);

/// 촬영 화면 상단 바. 플래시 토글, 필름 타입 라벨, 촬영 매수 카운터,
/// 닫기 버튼을 한 줄에 배치한다.
class CameraTopBar extends StatelessWidget {
  const CameraTopBar({
    super.key,
    required this.flashMode,
    required this.isFlashSupported,
    required this.filmTypeLabel,
    required this.photoCount,
    required this.maxPhotoCount,
    required this.onFlashToggle,
    required this.onClose,
  });

  final FlashMode flashMode;

  /// 현재 렌즈가 플래시를 지원하는지 여부. 전면 카메라 등 미지원 시 토글을
  /// 렌더링하지 않는다.
  final bool isFlashSupported;
  final String filmTypeLabel;
  final int photoCount;
  final int maxPhotoCount;
  final VoidCallback onFlashToggle;
  final VoidCallback onClose;

  bool get _isFlashOn => flashMode != FlashMode.off;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildFlashAndLabel()),
        const SizedBox(width: ChaerokSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: ChaerokSpacing.sm,
            vertical: ChaerokSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: _kCounterBackground,
            borderRadius: BorderRadius.circular(ChaerokRadius.full),
          ),
          child: Text(
            '$photoCount/$maxPhotoCount',
            style: ChaerokTypography.progress.copyWith(
              color: ChaerokColors.sageDark,
            ),
          ),
        ),
        const SizedBox(width: ChaerokSpacing.sm),
        GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: _kCloseBackground,
              shape: BoxShape.circle,
              border: Border.fromBorderSide(BorderSide(color: _kCloseBorder)),
            ),
            child: SvgPicture.asset(
              'assets/images/chaerok-camera-icon-cancel.svg',
              width: 16,
              height: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFlashAndLabel() {
    final label = Text(
      filmTypeLabel,
      style: ChaerokTypography.displayMedium.copyWith(
        color: ChaerokColors.sageDark,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (!isFlashSupported) {
      return Align(alignment: Alignment.centerLeft, child: label);
    }

    return GestureDetector(
      onTap: onFlashToggle,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Opacity(
                opacity: _isFlashOn ? 1 : 0.5,
                child: SvgPicture.asset(
                  'assets/images/chaerok-camera-icon-flash.svg',
                  width: 20,
                  height: 20,
                ),
              ),
              Text(
                _isFlashOn ? 'ON' : 'OFF',
                style: ChaerokTypography.caption.copyWith(
                  color: ChaerokColors.sageDark,
                ),
              ),
            ],
          ),
          const SizedBox(width: ChaerokSpacing.sm),
          Expanded(child: label),
        ],
      ),
    );
  }
}
