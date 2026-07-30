import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';

/// 앱 재시작 시 마지막으로 진행 중이던 필름롤을 복구한다.
/// 저장된 ID가 없거나, 해당 필름롤이 삭제/완료되었다면 저장값을 정리하고 null을 반환한다.
class RecoverLastActiveFilmRollUseCase {
  const RecoverLastActiveFilmRollUseCase({
    required FilmRollRepository filmRollRepository,
    AppPreferences? appPreferences,
  }) : _filmRollRepository = filmRollRepository,
       _appPreferences = appPreferences;

  final FilmRollRepository _filmRollRepository;
  final AppPreferences? _appPreferences;

  Future<FilmRoll?> call() async {
    final preferences = _appPreferences ?? AppPreferences.instance;
    final lastActiveFilmRollId = await preferences.getLastActiveFilmRollId();
    if (lastActiveFilmRollId == null) return null;

    final filmRoll = await _filmRollRepository.findById(lastActiveFilmRollId);
    if (filmRoll == null || filmRoll.status != FilmRollStatus.inProgress) {
      await preferences.setLastActiveFilmRollId(null);
      return null;
    }

    return filmRoll;
  }
}
