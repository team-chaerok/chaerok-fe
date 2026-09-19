import 'package:chaerok/data/models/film_roll_result_response.dart';
import 'package:chaerok/data/remote/film_rolls_api.dart';

/// 현상 결과(`FilmRollsApi.getFilmRollResult`)를 일정 간격으로 폴링해 진행
/// 상태를 스트림으로 발행한다. `COMPLETED`/`FAILED`/`EXPIRED`처럼 더 이상
/// 진행되지 않는 상태를 받으면 그 값을 마지막으로 발행하고 스트림을 닫는다.
class WatchFilmRollResultUseCase {
  WatchFilmRollResultUseCase({
    Future<FilmRollResultResponse> Function(int filmRollId)? getFilmRollResult,
    Duration pollInterval = const Duration(seconds: 2),
  }) : _getFilmRollResult = getFilmRollResult ?? FilmRollsApi.getFilmRollResult,
       _pollInterval = pollInterval;

  final Future<FilmRollResultResponse> Function(int filmRollId)
  _getFilmRollResult;
  final Duration _pollInterval;

  Stream<FilmRollResultResponse> call(int serverFilmRollId) async* {
    while (true) {
      final result = await _getFilmRollResult(serverFilmRollId);
      yield result;
      if (!result.isInProgress) return;
      await Future.delayed(_pollInterval);
    }
  }
}
