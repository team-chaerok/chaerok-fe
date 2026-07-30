import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';

/// 필름롤을 삭제한다(연관 장소/사진 DB 레코드 및 사진 파일 함께 정리).
/// 삭제 대상이 마지막 진행중 필름롤로 저장되어 있었다면 해당 저장값도 함께 정리한다.
class DeleteFilmRollUseCase {
  const DeleteFilmRollUseCase({
    required FilmRollRepository filmRollRepository,
    AppPreferences? appPreferences,
  }) : _filmRollRepository = filmRollRepository,
       _appPreferences = appPreferences;

  final FilmRollRepository _filmRollRepository;
  final AppPreferences? _appPreferences;

  Future<void> call(String filmRollId) async {
    await _filmRollRepository.deleteFilmRoll(filmRollId);

    final preferences = _appPreferences ?? AppPreferences.instance;
    final lastActiveFilmRollId = await preferences.getLastActiveFilmRollId();
    if (lastActiveFilmRollId == filmRollId) {
      await preferences.setLastActiveFilmRollId(null);
    }
  }
}
