import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_palette.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';

/// 필름롤 카드 상단 오른쪽에 세로로 깔리는 지역 대표 사진.
/// 에셋([RegionCode.filmPhotoAsset])이 아직 없으면 [RegionCode.filmTabColor]
/// 블록으로 폴백하므로, 파일을 나중에 넣어도 레이아웃은 지금 그대로다.
class RegionFilmPhoto extends StatelessWidget {
  const RegionFilmPhoto({super.key, required this.region});

  final RegionCode region;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(ChaerokRadius.xl),
      ),
      child: Image.asset(
        region.filmPhotoAsset,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) =>
            ColoredBox(color: region.filmTabColor),
      ),
    );
  }
}
