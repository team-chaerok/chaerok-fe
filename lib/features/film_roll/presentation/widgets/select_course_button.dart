import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:flutter/material.dart';

/// 코스 미선택 필름롤의 "추천 코스 선택하기" 버튼.
///
/// 이미 방문/촬영 기록이 있는 필름롤은 코스를 새로 고를 수 없다(코스 변경 차단
/// 정책). 눌러 봐야 실패하는 버튼을 그대로 두지 않도록, 그 경우 버튼을 비활성화하고
/// 이유를 안내한다. 기록 조회가 끝나기 전이나 조회에 실패했을 때는 기존처럼
/// 활성 상태를 유지한다 — 실제 차단 판정은 선택 확정 시점에 다시 이뤄진다.
class SelectCourseButton extends StatefulWidget {
  const SelectCourseButton({
    super.key,
    required this.filmRollId,
    required this.onPressed,
    this.isLoading = false,
    this.debugHasRecords,
  });

  final String filmRollId;
  final VoidCallback onPressed;
  final bool isLoading;

  /// 테스트용: 지정하면 방문/촬영 기록 조회를 저장소 대신 이 함수로 대체한다.
  final Future<bool> Function()? debugHasRecords;

  static const blockedMessage = '이미 방문/촬영 기록이 있어 코스를 선택할 수 없어요.';

  @override
  State<SelectCourseButton> createState() => _SelectCourseButtonState();
}

class _SelectCourseButtonState extends State<SelectCourseButton> {
  static const _tag = 'SelectCourseButton';

  bool _isBlocked = false;

  @override
  void initState() {
    super.initState();
    unawaited(_checkRecords());
  }

  @override
  void didUpdateWidget(SelectCourseButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filmRollId != widget.filmRollId) {
      unawaited(_checkRecords());
    }
  }

  Future<void> _checkRecords() async {
    final filmRollId = widget.filmRollId;
    try {
      final debugHasRecords = widget.debugHasRecords;
      final hasRecords = debugHasRecords != null
          ? await debugHasRecords()
          : await FilmRollModule.instance.filmRollRepository
                .hasVisitOrPhotoRecords(filmRollId);
      if (!mounted || filmRollId != widget.filmRollId) return;
      setState(() => _isBlocked = hasRecords);
    } catch (e, st) {
      log('방문/촬영 기록 조회 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ChaerokButton(
          text: '추천 코스 선택하기',
          isEnabled: !_isBlocked,
          isLoading: widget.isLoading,
          onPressed: widget.onPressed,
        ),
        if (_isBlocked) ...[
          const SizedBox(height: ChaerokSpacing.xs),
          Text(
            SelectCourseButton.blockedMessage,
            textAlign: TextAlign.center,
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
