import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/features/settings/presentation/my_screen.dart';
import 'package:flutter/material.dart';

/// 홈 화면 우측 상단의 마이페이지 진입 버튼. 하단 네비게이션에서 "마이" 탭을
/// 없앤 뒤, 홈에서 [MyScreen]으로 이동하는 유일한 경로다.
class MyPageButton extends StatelessWidget {
  const MyPageButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => Navigator.of(
        context,
      ).push(MaterialPageRoute<void>(builder: (_) => const MyScreen())),
      icon: const Icon(
        Icons.person_outline_rounded,
        color: ChaerokColors.primaryDark,
      ),
      tooltip: '마이페이지',
      visualDensity: VisualDensity.compact,
    );
  }
}
