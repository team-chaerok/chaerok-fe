import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_result_photo_image.dart';
import 'package:flutter/material.dart';

/// 필름 스트립 안의 한 칸. 사진 위 오른쪽 아래에 필름 롤 안에서의 촬영
/// 순서(01, 02 …)를 작게 표시한다. [photo]가 없으면 아직 감기지 않은 빈 칸이다.
class FilmRollResultFilmFrame extends StatelessWidget {
  const FilmRollResultFilmFrame({super.key, this.photo, this.onTap});

  /// 칸의 가로세로 비율. 휴대폰으로 세워 찍은 사진이 덜 잘리도록 세로형이다.
  static const double aspectRatio = 3 / 4;

  static const double _radius = 2;

  final FilmRollResultPhoto? photo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final photo = this.photo;
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_radius),
        child: photo == null
            ? const ColoredBox(color: ChaerokColors.cameraBlack)
            : GestureDetector(
                onTap: onTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    FilmRollResultPhotoImage(photo: photo),
                    Positioned(
                      right: ChaerokSpacing.xxs,
                      bottom: 2,
                      child: Text(
                        photo.sequence.toString().padLeft(2, '0'),
                        style: ChaerokTypography.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 10,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
