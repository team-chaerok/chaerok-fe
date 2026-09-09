import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:flutter/material.dart';

/// 앱 전역 공통 AppBar. 배경색·elevation·타이틀 스타일과 **뒤로가기 아이콘**을
/// 한 곳에서 통일한다. 화면에서는 `AppBar(...)` 대신 이 위젯을 사용한다.
///
/// 뒤로가기 아이콘은 현재 라우트를 pop 할 수 있을 때만 [Icons.arrow_back_ios_new]
/// 로 노출된다. [leading] 을 넘기면 그 위젯이 우선하고, [showBackButton] 을
/// `false` 로 두면 자동 뒤로가기 버튼을 숨긴다.
class ChaerokAppbar extends StatelessWidget implements PreferredSizeWidget {
  const ChaerokAppbar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.showBackButton = true,
    this.bottom,
  });

  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    final effectiveLeading =
        leading ??
        (showBackButton && canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                color: ChaerokColors.textPrimary,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null);

    return AppBar(
      backgroundColor: ChaerokColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: effectiveLeading,
      title: title == null
          ? null
          : Text(title!, style: ChaerokTypography.titleMedium),
      actions: actions,
      bottom: bottom,
    );
  }
}
