import 'dart:io';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:flutter/material.dart';

/// 현상 결과 사진 한 장을 그린다. 기기 파일이 있으면 파일을, 없으면 서버 URL을
/// 쓰고, 촬영 원본으로 대체된 사진에는 "필터 미적용" 라벨을 얹는다.
class FilmRollResultPhotoImage extends StatelessWidget {
  const FilmRollResultPhotoImage({
    super.key,
    required this.photo,
    this.placeholderColor = ChaerokColors.sageLight,
    this.showUnfilteredLabel = true,
  });

  static const unfilteredLabel = '필터 미적용';

  final FilmRollResultPhoto photo;

  /// 사진을 불러오지 못했을 때 대신 채우는 색.
  final Color placeholderColor;

  /// 릴스 썸네일처럼 사진이 배경으로만 쓰이는 곳에서는 라벨을 끈다.
  final bool showUnfilteredLabel;

  @override
  Widget build(BuildContext context) {
    final image = _buildImage();
    if (photo.isFiltered || !showUnfilteredLabel) return image;

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        Positioned(
          left: ChaerokSpacing.xs,
          top: ChaerokSpacing.xs,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ChaerokSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(ChaerokRadius.sm),
            ),
            child: Text(
              unfilteredLabel,
              style: ChaerokTypography.caption.copyWith(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    Widget placeholder(BuildContext _, Object _, StackTrace? _) =>
        ColoredBox(color: placeholderColor);

    final localPath = photo.localPath;
    if (localPath != null) {
      return Image.file(
        File(localPath),
        fit: BoxFit.cover,
        errorBuilder: placeholder,
      );
    }
    return Image.network(
      photo.remoteUrl!,
      fit: BoxFit.cover,
      errorBuilder: placeholder,
    );
  }
}
