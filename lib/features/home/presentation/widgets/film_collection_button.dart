import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_collection_screen.dart';
import 'package:flutter/material.dart';

/// 홈 화면 우측 상단의 필름(모아보기) 진입 버튼. 하단 네비게이션에서 "필름" 탭을
/// 없앤 뒤, 홈에서 [FilmRollCollectionScreen]으로 이동하는 유일한 경로다.
class FilmCollectionButton extends StatelessWidget {
  const FilmCollectionButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const FilmRollCollectionScreen(),
        ),
      ),
      icon: const Icon(
        Icons.photo_library_outlined,
        color: ChaerokColors.primaryDark,
      ),
      tooltip: '필름',
      visualDensity: VisualDensity.compact,
    );
  }
}
