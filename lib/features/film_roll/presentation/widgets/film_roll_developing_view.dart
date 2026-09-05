import 'dart:async';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:flutter/material.dart';

/// 채록길 탭의 현상 대기 모드 본문.
///
/// 지역 이탈이 확정돼 [FilmRollStatus.developing]으로 전환된 필름롤의 남은
/// 시간과 완료 예정 시각을 보여준다. 현상 완료 감지·자동 전환은 이번 범위
/// 밖(후속 이슈) — BE 결과 조회 API가 아직 없다. 완료되면 사용자가 필름
/// 컬렉션 탭에서 직접 확인해야 한다.
class FilmRollDevelopingView extends StatefulWidget {
  const FilmRollDevelopingView({super.key, required this.filmRoll});

  final FilmRoll filmRoll;

  @override
  State<FilmRollDevelopingView> createState() => _FilmRollDevelopingViewState();
}

class _FilmRollDevelopingViewState extends State<FilmRollDevelopingView> {
  Timer? _ticker;
  Duration _remaining = Duration.zero;

  DateTime? get _developAvailableAt => widget.filmRoll.developAvailableAt;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemaining();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _updateRemaining() {
    final developAvailableAt = _developAvailableAt;
    final remaining = developAvailableAt == null
        ? Duration.zero
        : developAvailableAt.difference(DateTime.now());
    if (!mounted) return;
    setState(() {
      _remaining = remaining.isNegative ? Duration.zero : remaining;
    });
    if (remaining <= Duration.zero) {
      _ticker?.cancel();
    }
  }

  String _formatRemaining(Duration remaining) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(remaining.inHours);
    final minutes = twoDigits(remaining.inMinutes.remainder(60));
    final seconds = twoDigits(remaining.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  String _formatAvailableAt(DateTime at) {
    final twoDigitMinute = at.minute.toString().padLeft(2, '0');
    return '${at.month}월 ${at.day}일 ${at.hour}시 $twoDigitMinute분';
  }

  @override
  Widget build(BuildContext context) {
    final filmRoll = widget.filmRoll;
    final developAvailableAt = _developAvailableAt;
    final isFinishingUp = _remaining <= Duration.zero;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ChaerokSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${filmRoll.title} · 현상 중',
            style: ChaerokTypography.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ChaerokSpacing.xxl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(ChaerokSpacing.xl),
            decoration: BoxDecoration(
              color: ChaerokColors.surface,
              borderRadius: BorderRadius.circular(ChaerokRadius.md),
              border: Border.all(color: ChaerokColors.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.hourglass_bottom,
                  size: 40,
                  color: ChaerokColors.primary,
                ),
                const SizedBox(height: ChaerokSpacing.md),
                Text(
                  isFinishingUp ? '곧 현상이 완료돼요' : _formatRemaining(_remaining),
                  style: ChaerokTypography.titleMedium,
                ),
                const SizedBox(height: ChaerokSpacing.xs),
                if (developAvailableAt != null)
                  Text(
                    '완료 예정: ${_formatAvailableAt(developAvailableAt)}',
                    style: ChaerokTypography.bodyMedium.copyWith(
                      color: ChaerokColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: ChaerokSpacing.lg),
          Text(
            '서로 다른 관광 유형 방문과 촬영한 사진으로 현상이 진행돼요.',
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ChaerokSpacing.xs),
          Text(
            '현상이 완료되면 필름 컬렉션에서 확인할 수 있어요.',
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
