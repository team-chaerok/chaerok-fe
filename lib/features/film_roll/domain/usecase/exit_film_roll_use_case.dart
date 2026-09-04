import 'package:chaerok/data/models/film_roll_exit_response.dart';
import 'package:chaerok/data/remote/film_rolls_api.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_service.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/exit_film_roll_result.dart';

/// exit 성공 + 현상 조건 충족 시 서버가 내려주는 status 값.
const _readyToRenderStatus = 'READY_TO_RENDER';

/// 서버가 `developAvailableAt`을 내려주지 않을 때 쓰는 대체 현상 소요 시간.
const _fallbackDevelopDuration = Duration(hours: 1);

/// 지역 이탈을 확정한다(`FilmRollsApi.exitFilmRoll`). 서버 필름롤이 아직 없으면
/// 먼저 동기화를 시도해 확보하고, 응답에 따라 로컬 필름롤을 [FilmRollStatus.developing]
/// 또는 [FilmRollStatus.expired]로 전환한다.
class ExitFilmRollUseCase {
  ExitFilmRollUseCase({
    required FilmRollRepository filmRollRepository,
    required FilmRollSyncService syncService,
    Future<FilmRollExitResponse> Function(int filmRollId)? exitFilmRoll,
  }) : _filmRollRepository = filmRollRepository,
       _syncService = syncService,
       _exitFilmRoll = exitFilmRoll ?? FilmRollsApi.exitFilmRoll;

  final FilmRollRepository _filmRollRepository;
  final FilmRollSyncService _syncService;
  final Future<FilmRollExitResponse> Function(int) _exitFilmRoll;

  /// 서버 필름롤 ID가 없으면 [ExitNotSyncedException]을 던진다.
  Future<ExitFilmRollResult> call(FilmRoll filmRoll) async {
    final serverFilmRollId = await _ensureServerFilmRollId(filmRoll);
    if (serverFilmRollId == null) {
      throw const ExitNotSyncedException();
    }

    final response = await _exitFilmRoll(serverFilmRollId);
    // developAvailable과 status 문자열 둘 중 하나라도 충족을 가리키면
    // 현상 예약으로 처리한다(서버 스펙 확정 전 방어적 이중 판정).
    final isReadyToRender =
        response.developAvailable ||
        response.status.toUpperCase() == _readyToRenderStatus;

    if (!isReadyToRender) {
      await _filmRollRepository.markExpired(
        clientFilmRollId: filmRoll.id,
        serverStatus: response.status,
      );
      return const ExitFilmRollResult.expired();
    }

    final developAvailableAt =
        response.developAvailableAt ??
        response.exitedAt.add(_fallbackDevelopDuration);
    await _filmRollRepository.markDeveloping(
      clientFilmRollId: filmRoll.id,
      developAvailableAt: developAvailableAt,
      serverStatus: response.status,
    );
    return ExitFilmRollResult.developing(developAvailableAt);
  }

  /// 이미 서버 필름롤이 있으면 그대로 반환하고, 없으면 지역 검사를 건너뛴
  /// 동기화를 1회 시도해 확보한다(현재 위치가 이미 필름롤 지역 밖일 수 있으므로).
  Future<int?> _ensureServerFilmRollId(FilmRoll filmRoll) async {
    final existing = filmRoll.serverFilmRollId;
    if (existing != null) return existing;

    await _syncService.syncFilmRoll(filmRoll.id, skipRegionCheck: true);
    final refreshed = await _filmRollRepository.findById(filmRoll.id);
    return refreshed?.serverFilmRollId;
  }
}
