import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/usecase/enter_region_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/recover_last_active_film_roll_use_case.dart';

/// [ResolveFilmRollEntryUseCase]의 판정 결과. 화면은 이 값에 따라 다음 화면을 결정한다.
enum FilmRollEntryAction {
  /// 코스가 아직 선택되지 않았다. 코스 선택 화면으로 이어줘야 한다.
  needsCourseSelection,

  /// 이미 코스가 선택된 진행중 필름롤이 있다. 진행 화면으로 바로 이동한다.
  resumeInProgress,

  /// 지역 이탈이 확정돼 현상 대기중이다. 현상 대기 화면으로 이동한다.
  showDeveloping,
}

/// [ResolveFilmRollEntryUseCase.call] 결과.
class FilmRollEntryDecision {
  const FilmRollEntryDecision({required this.action, required this.filmRoll});

  final FilmRollEntryAction action;
  final FilmRoll filmRoll;
}

/// 위치 인증/지역 선택 직후 "다음에 어떤 화면으로 이어야 하는지"를 판정한다.
/// 활성 필름롤이 없으면 [EnterRegionUseCase]로 새로 진입하고, 있으면 상태
/// (진행중/코스 미선택/현상 대기)에 따라 분기한다. Home·Explore 두 진입점이
/// 이 판정 로직을 공유해 중복된 `enterRegion` 호출/분기를 제거한다.
class ResolveFilmRollEntryUseCase {
  const ResolveFilmRollEntryUseCase({
    required RecoverLastActiveFilmRollUseCase recoverLastActiveFilmRoll,
    required EnterRegionUseCase enterRegion,
  }) : _recoverLastActiveFilmRoll = recoverLastActiveFilmRoll,
       _enterRegion = enterRegion;

  final RecoverLastActiveFilmRollUseCase _recoverLastActiveFilmRoll;
  final EnterRegionUseCase _enterRegion;

  Future<FilmRollEntryDecision> call(
    String cityCountyName, {
    required int regionId,
  }) async {
    final active = await _recoverLastActiveFilmRoll();
    if (active != null) {
      return FilmRollEntryDecision(
        action: _resolveActionFor(active),
        filmRoll: active,
      );
    }

    final entered = await _enterRegion(cityCountyName, regionId: regionId);
    return FilmRollEntryDecision(
      action: _resolveActionFor(entered),
      filmRoll: entered,
    );
  }

  FilmRollEntryAction _resolveActionFor(FilmRoll filmRoll) {
    if (filmRoll.status == FilmRollStatus.developing) {
      return FilmRollEntryAction.showDeveloping;
    }
    if (filmRoll.selectedCourseId == null) {
      return FilmRollEntryAction.needsCourseSelection;
    }
    return FilmRollEntryAction.resumeInProgress;
  }
}
