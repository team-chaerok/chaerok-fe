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
  static const double _photoAspectRatio = 3 / 4;
  static const double _edgeHeight = 20;
  static const double _frameGap = 6;

  final List<FilmRollResultPhoto> photos;
  final ValueChanged<int> onPhotoTap;

  /// 스트립 양 끝 여백. 화면 가장자리까지 필름이 이어지도록 스크롤 안쪽에 둔다.
  final EdgeInsets padding;

  static final TextStyle _labelStyle = ChaerokTypography.caption.copyWith(
    color: Colors.white,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 1,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    const photoHeight = (_frameWidth - _frameGap) / _photoAspectRatio;
    return SizedBox(
      height: photoHeight + _edgeHeight * 2,
      child: ListView.builder(
        padding: padding,
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        itemBuilder: (context, index) => _buildFrame(photos[index], index),
      ),
    );
  }

  Widget _buildFrame(FilmRollResultPhoto photo, int index) {
    const holes = FilmRollResultSprocketHoles(
      holeWidth: 6,
      holeHeight: 7,
      pitch: 13,
    );
    return GestureDetector(
      onTap: () => onPhotoTap(index),
      child: Container(
        width: _frameWidth,
        color: ChaerokColors.cameraBlack,
        padding: const EdgeInsets.symmetric(horizontal: _frameGap / 2),
        child: Column(
          children: [
            const SizedBox(
              height: _edgeHeight,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: ChaerokSpacing.xxs),
                child: holes,
              ),
            ),
            Expanded(child: FilmRollResultPhotoImage(photo: photo)),
            SizedBox(
              height: _edgeHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChaerokSpacing.xxs,
                ),
                child: Row(
                  children: [
                    const Expanded(child: holes),
                    const SizedBox(width: ChaerokSpacing.xs),
                    Text(
                      photo.sequence.toString().padLeft(2, '0'),
                      style: _labelStyle,
                    ),
                    const SizedBox(width: ChaerokSpacing.xs),
                    const Expanded(flex: 2, child: holes),
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
