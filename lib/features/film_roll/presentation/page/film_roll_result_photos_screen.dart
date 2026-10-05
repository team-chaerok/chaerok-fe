import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_result_photo_image.dart';
import 'package:chaerok/shared/widgets/chaerok_appbar.dart';
import 'package:flutter/material.dart';

/// 현상 결과의 촬영 사진 전체를 그리드로 보여주는 화면.
class FilmRollResultPhotosScreen extends StatelessWidget {
  const FilmRollResultPhotosScreen({super.key, required this.photos});

  final List<FilmRollResultPhoto> photos;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: const ChaerokAppbar(title: '오늘의 사진'),
      body: GridView.builder(
        padding: const EdgeInsets.all(ChaerokSpacing.md),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: ChaerokSpacing.xxs,
          mainAxisSpacing: ChaerokSpacing.xxs,
        ),
        itemCount: photos.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(ChaerokRadius.sm),
            child: FilmRollResultPhotoImage(photo: photos[index]),
          );
        },
      ),
    );
  }
}
