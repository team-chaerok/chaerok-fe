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

/// 지역 이탈을 확정한다(`FilmRollsApi.exitFilmRoll`). 서버 필름롤이 없으면 먼저
/// 생성하고, 있어도 미전송 방문을 exit 직전에 한 번 더 반영해(동기화 실패 시
/// 이탈 확정을 보류) 서버가 최신 방문 현황으로 현상 조건을 판정하게 한 뒤,
/// 응답에 따라 로컬 필름롤을 [FilmRollStatus.developing] 또는
/// [FilmRollStatus.expired]로 전환한다.
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

  /// 서버 필름롤을 확보하고 미전송 방문을 반영한다. 지역 검사는 건너뛴다(현재
  /// 위치가 이미 필름롤 지역 밖일 수 있으므로). 서버 필름롤이 이미 있어도 매번
  /// 동기화를 시도하는 이유: 방문 인증 후 다음 동기화 전에 바로 이탈하면
  /// 서버가 그 방문을 모른 채 현상 조건을 판정할 수 있기 때문이다.
  ///
  /// 동기화가 실패하면(`hasError`) 서버가 불완전한 정보로 판정할 위험이 있어
  /// null을 반환해 이탈 확정 자체를 보류시킨다(호출부가 [ExitNotSyncedException]
  /// 으로 변환). 반면 `visitsSkipped`(서버 `placeId`가 없어 애초에 전송할 수
  /// 없는 방문)는 재시도로도 해결되지 않는 구조적 상태이므로 막지 않는다 —
  /// 여기서 막으면 정상적으로 완료 가능한 필름롤도 영구히 이탈 확정이 막힌다.
  Future<int?> _ensureServerFilmRollId(FilmRoll filmRoll) async {
    final syncResult = await _syncService.syncFilmRoll(
      filmRoll.id,
      skipRegionCheck: true,
    );
    if (syncResult.hasError) return null;

    final existing = filmRoll.serverFilmRollId;
    if (existing != null) return existing;

    final refreshed = await _filmRollRepository.findById(filmRoll.id);
    return refreshed?.serverFilmRollId;
  }
}
