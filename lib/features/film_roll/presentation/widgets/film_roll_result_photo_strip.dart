import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_result_featured_frame.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_result_photo_image.dart';
import 'package:flutter/material.dart';

/// 현상 결과의 "오늘의 사진" 필름 스트립. 칸들이 끊김 없이 한 줄의 필름처럼
/// 이어지고, 각 칸 아래 띠에 촬영 순서(01, 02 …)를 새긴다. 칸을 누르면
/// [onPhotoTap]에 그 칸의 인덱스를 넘긴다.
class FilmRollResultPhotoStrip extends StatelessWidget {
  const FilmRollResultPhotoStrip({
    super.key,
    required this.photos,
    required this.onPhotoTap,
    this.padding = EdgeInsets.zero,
  });

  static const double _frameWidth = 132;

  final List<FilmRollResultPhoto> photos;
  final ValueChanged<int> onPhotoTap;

  /// 스트립 양 끝 여백. 화면 가장자리까지 필름이 이어지도록 스크롤 안쪽에 둔다.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: FilmRollResultStripFrame.heightFor(_frameWidth),
      child: ListView.builder(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (context, index) => SizedBox(
          width: _frameWidth,
          child: FilmRollResultStripFrame(
            photo: photos[index],
            onTap: () => onPhotoTap(index),
          ),
        ),
      ),
    );
  }
}

/// 필름 스트립의 한 칸. 위아래 띠에 스프라켓 구멍을 두르고 아래 띠에 촬영
/// 순서를 새긴다. 칸을 나란히 붙이면 끊김 없는 한 줄의 필름이 된다.
/// [photo]가 없으면 아직 감기지 않은 빈 칸이다.
class FilmRollResultStripFrame extends StatelessWidget {
  const FilmRollResultStripFrame({super.key, this.photo, this.onTap});

  static const double _photoAspectRatio = 3 / 4;
  static const double _edgeHeight = 20;
  static const double _frameGap = 6;

  /// 칸 너비가 [width]일 때의 칸 전체 높이(위아래 띠 포함).
  static double heightFor(double width) =>
      (width - _frameGap) / _photoAspectRatio + _edgeHeight * 2;

  final FilmRollResultPhoto? photo;
  final VoidCallback? onTap;

  static final TextStyle _labelStyle = ChaerokTypography.caption.copyWith(
    color: Colors.white,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static const _holes = FilmRollResultSprocketHoles(
    holeWidth: 6,
    holeHeight: 7,
    pitch: 13,
  );

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: ChaerokColors.cameraBlack,
        padding: const EdgeInsets.symmetric(horizontal: _frameGap / 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: _edgeHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: ChaerokSpacing.xxs),
                child: _holes,
              ),
            ),
            AspectRatio(
              aspectRatio: _photoAspectRatio,
              child: photo == null
                  ? const SizedBox.shrink()
                  : FilmRollResultPhotoImage(photo: photo),
            ),
            SizedBox(
              height: _edgeHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChaerokSpacing.xxs,
                ),
                child: photo == null
                    ? _holes
                    : Row(
                        children: [
                          const Expanded(child: _holes),
                          const SizedBox(width: ChaerokSpacing.xs),
                          Text(
                            photo.sequence.toString().padLeft(2, '0'),
                            style: _labelStyle,
                          ),
                          const SizedBox(width: ChaerokSpacing.xs),
                          const Expanded(flex: 2, child: _holes),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
