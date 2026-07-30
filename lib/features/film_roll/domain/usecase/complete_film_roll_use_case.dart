import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';

/// 완료 조건(코스 선택 + 전체 장소 방문)을 검증하고 필름롤을 완료 처리한다.
/// 조건을 충족하지 못하면 [FilmRollNotCompletableException]을 던진다.
class CompleteFilmRollUseCase {
  const CompleteFilmRollUseCase(this._filmRollRepository);

  final FilmRollRepository _filmRollRepository;

  Future<void> call(String filmRollId) {
    return _filmRollRepository.completeFilmRoll(filmRollId);
  }
}
