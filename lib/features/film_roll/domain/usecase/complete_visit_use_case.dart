import 'package:chaerok/features/film_roll/domain/repository/film_roll_place_repository.dart';

/// 장소 방문 인증을 기록한다. 이미 방문 처리된 장소를 다시 호출해도
/// 방문 횟수는 1회로 유지된다(리포지토리 구현에서 멱등 처리).
class CompleteVisitUseCase {
  const CompleteVisitUseCase(this._filmRollPlaceRepository);

  final FilmRollPlaceRepository _filmRollPlaceRepository;

  Future<void> call(String filmRollPlaceId) {
    return _filmRollPlaceRepository.markVisited(filmRollPlaceId);
  }
}
