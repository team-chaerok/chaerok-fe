import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/film_roll_result_response.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/develop_film_roll_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/watch_film_roll_result_use_case.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_result_screen.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:flutter/material.dart';

/// 채록길 탭의 현상 대기 모드 본문.
///
/// 지역 이탈이 확정돼 [FilmRollStatus.developing]으로 전환된 필름롤을 두고,
/// 진입 즉시 현상(릴스 생성)을 요청하고([DevelopFilmRollUseCase]) 결과를
/// 폴링해([WatchFilmRollResultUseCase]) 완료되면 현상 결과 화면으로
/// 넘어간다. `reviewMode` 계정은 서버가 1시간 대기 검사를 면제해주므로
/// 이 즉시 요청만으로 개발 단계의 "즉시 릴스 생성"이 성립하고, 일반
/// 계정은 서버가 그대로 1시간 대기를 강제한다(FE 쪽 분기 불필요).
class FilmRollDevelopingView extends StatefulWidget {
  const FilmRollDevelopingView({
    super.key,
    required this.filmRoll,
    FilmRollRepository? filmRollRepository,
    DevelopFilmRollUseCase? developFilmRoll,
    WatchFilmRollResultUseCase? watchFilmRollResult,
  }) : _filmRollRepository = filmRollRepository,
       _developFilmRoll = developFilmRoll,
       _watchFilmRollResult = watchFilmRollResult;

  final FilmRoll filmRoll;
  final FilmRollRepository? _filmRollRepository;
  final DevelopFilmRollUseCase? _developFilmRoll;
  final WatchFilmRollResultUseCase? _watchFilmRollResult;

  @override
  State<FilmRollDevelopingView> createState() => _FilmRollDevelopingViewState();
}

enum _DevelopingPhase { waiting, failed, expired, pollError }

class _FilmRollDevelopingViewState extends State<FilmRollDevelopingView> {
  static const _tag = 'FilmRollDevelopingView';

  late final FilmRollRepository _filmRollRepository =
      widget._filmRollRepository ?? FilmRollModule.instance.filmRollRepository;
  late final DevelopFilmRollUseCase _developFilmRoll =
      widget._developFilmRoll ?? FilmRollModule.instance.developFilmRoll;
  late final WatchFilmRollResultUseCase _watchFilmRollResult =
      widget._watchFilmRollResult ??
      FilmRollModule.instance.watchFilmRollResult;

  StreamSubscription<FilmRollResultResponse>? _resultSubscription;
  _DevelopingPhase _phase = _DevelopingPhase.waiting;
  FailureResponse? _failure;

  @override
  void initState() {
    super.initState();
    unawaited(_startDevelopment());
  }

  @override
  void dispose() {
    unawaited(_resultSubscription?.cancel());
    super.dispose();
  }

  Future<void> _startDevelopment() async {
    final serverFilmRollId = widget.filmRoll.serverFilmRollId;
    if (serverFilmRollId == null) {
      log('서버 필름롤 ID가 없어 현상 요청을 건너뜁니다', name: _tag);
      return;
    }

    try {
      await _developFilmRoll(serverFilmRollId);
    } catch (e, st) {
      // 실패해도 로컬 상태는 바꾸지 않는다 — 이미 QUEUED/PROCESSING 상태라
      // 재요청이 거부된 경우일 수도 있으므로, 결과 폴링에서 그대로 진행 상태를
      // 확인한다.
      log('즉시 현상 요청 실패', name: _tag, error: e, stackTrace: st);
    }

    // 위 await 중 위젯이 dispose됐을 수 있다 — 이미 dispose()가 실행돼
    // 기존 구독을 정리한 뒤이므로, 여기서 만드는 새 구독은 아무도 취소하지
    // 않아 leak된다.
    if (!mounted) return;

    _resultSubscription = _watchFilmRollResult(serverFilmRollId).listen(
      _onResult,
      onError: (Object e, StackTrace st) {
        log('현상 결과 폴링 실패', name: _tag, error: e, stackTrace: st);
        if (!mounted) return;
        setState(() {
          _phase = _DevelopingPhase.pollError;
          _failure = null;
        });
      },
    );
  }

  /// 폴링 실패 후 "다시 시도"를 누르면 대기 상태로 되돌리고 처음부터 다시
  /// 현상 요청 + 결과 폴링을 시작한다.
  void _retryAfterPollError() {
    setState(() {
      _phase = _DevelopingPhase.waiting;
      _failure = null;
    });
    unawaited(_startDevelopment());
  }

  Future<void> _onResult(FilmRollResultResponse result) async {
    if (!mounted) return;

    if (result.isCompleted) {
      try {
        final completedAt = result.completedAt ?? DateTime.now();
        await _filmRollRepository.markCompleted(
          clientFilmRollId: widget.filmRoll.id,
          completedAt: completedAt,
        );
        if (!mounted) return;
        // 임베드된 탭(채록길)의 Navigator까지 교체하면 하단 탭이 사라지므로
        // push로 결과 화면을 쌓는다(뒤로 가면 이 화면으로 돌아오지만, 이미
        // completed로 갱신된 상태라 재진입 시 자연히 컬렉션 흐름으로 이어진다).
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FilmRollResultScreen(
              filmRoll: widget.filmRoll.copyWith(completedAt: completedAt),
              initialResult: result,
            ),
          ),
        );
      } catch (e, st) {
        // markCompleted 실패 시 아무 처리도 없으면 화면이 "현상 중" 상태로
        // 영원히 멈춘다 — 재시도할 수 있게 오류 상태로 전환한다.
        log('현상 완료 처리 실패', name: _tag, error: e, stackTrace: st);
        if (!mounted) return;
        setState(() {
          _phase = _DevelopingPhase.pollError;
          _failure = null;
        });
      }
      return;
    }

    if (result.isFailed || result.isExpired) {
      setState(() {
        _phase = result.isFailed
            ? _DevelopingPhase.failed
            : _DevelopingPhase.expired;
        _failure = result.failure;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ChaerokSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${widget.filmRoll.title} · 현상 중',
            style: ChaerokTypography.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ChaerokSpacing.xxl),
          _buildStatusCard(),
          const SizedBox(height: ChaerokSpacing.lg),
          Text(
            switch (_phase) {
              _DevelopingPhase.waiting => '서로 다른 관광 유형 방문과 촬영한 사진으로 현상이 진행돼요.',
              _DevelopingPhase.pollError => '네트워크 상태를 확인하고 다시 시도해 주세요.',
              _DevelopingPhase.failed ||
              _DevelopingPhase.expired => '현상 결과를 다시 확인하려면 필름 컬렉션에서 확인해 주세요.',
            },
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (_phase == _DevelopingPhase.pollError) ...[
            const SizedBox(height: ChaerokSpacing.md),
            ChaerokButton(text: '다시 시도', onPressed: _retryAfterPollError),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChaerokSpacing.xl),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
        border: Border.all(color: ChaerokColors.border),
      ),
      child: Column(
        children: [
          Icon(_statusIcon(), size: 40, color: ChaerokColors.primary),
          const SizedBox(height: ChaerokSpacing.md),
          Text(_statusTitle(), style: ChaerokTypography.titleMedium),
          if (_failure != null) ...[
            const SizedBox(height: ChaerokSpacing.xs),
            Text(
              _failure!.message,
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  IconData _statusIcon() {
    return switch (_phase) {
      _DevelopingPhase.waiting => Icons.hourglass_bottom,
      _DevelopingPhase.failed => Icons.error_outline,
      _DevelopingPhase.expired => Icons.cancel_outlined,
      _DevelopingPhase.pollError => Icons.wifi_off_outlined,
    };
  }

  String _statusTitle() {
    return switch (_phase) {
      _DevelopingPhase.waiting => '현상 진행 중이에요',
      _DevelopingPhase.failed => '릴스 생성에 실패했어요',
      _DevelopingPhase.expired => '결과 보관 기간이 지났어요',
      _DevelopingPhase.pollError => '결과를 불러오지 못했어요',
    };
  }
}
