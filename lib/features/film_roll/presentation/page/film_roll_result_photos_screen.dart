import 'dart:async';
import 'dart:math' as math;

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:chaerok/features/film_roll/domain/usecase/save_result_photo_to_gallery_use_case.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_result_photo_viewer_page.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_result_photo_strip.dart';
import 'package:chaerok/shared/widgets/chaerok_appbar.dart';
import 'package:flutter/material.dart';

/// 현상 결과의 촬영 사진 전체를 밀착 인화(contact sheet)처럼 보여주는 화면.
/// 촬영 순서대로 [framesPerStrip]장씩 끊은 필름 스트립을 위에서 아래로
/// 쌓는다. 사진을 누르면 전체 화면 보기([FilmRollResultPhotoViewerPage])로
/// 이동한다.
class FilmRollResultPhotosScreen extends StatelessWidget {
  const FilmRollResultPhotosScreen({
    super.key,
    required this.photos,
    SaveResultPhotoToGalleryUseCase? savePhotoToGallery,
  }) : _savePhotoToGallery = savePhotoToGallery;

  static const framesPerStrip = 3;

  final List<FilmRollResultPhoto> photos;
  final SaveResultPhotoToGalleryUseCase? _savePhotoToGallery;

  void _openViewer(BuildContext context, int index) {
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FilmRollResultPhotoViewerPage(
            photos: photos,
            initialIndex: index,
            savePhotoToGallery: _savePhotoToGallery,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stripCount = (photos.length / framesPerStrip).ceil();
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: const ChaerokAppbar(title: '오늘의 사진'),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: ChaerokSpacing.lg,
          vertical: ChaerokSpacing.md,
        ),
        itemCount: stripCount,
        separatorBuilder: (_, _) => const SizedBox(height: ChaerokSpacing.md),
        itemBuilder: (context, stripIndex) =>
            _buildStrip(context, stripIndex * framesPerStrip),
      ),
    );
  }

  /// [start]번째 사진부터 [framesPerStrip]칸짜리 필름 스트립 한 줄. 결과
  /// 화면의 "오늘의 사진" 스트립과 같은 칸을 이어 붙인다. 마지막 줄이 덜 차면
  /// 남은 칸은 빈 필름으로 둬 칸 크기를 맞춘다.
  Widget _buildStrip(BuildContext context, int start) {
    final end = math.min(start + framesPerStrip, photos.length);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = start; i < start + framesPerStrip; i++)
          Expanded(
            child: FilmRollResultStripFrame(
              photo: i < end ? photos[i] : null,
              onTap: i < end ? () => _openViewer(context, i) : null,
            ),
          ),
      ],
    );
  }
}
