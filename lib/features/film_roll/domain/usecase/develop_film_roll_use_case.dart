import 'package:chaerok/data/models/film_roll_development_response.dart';
import 'package:chaerok/data/remote/film_rolls_api.dart';

/// 필름롤 현상(릴스 생성)을 즉시 요청한다(`FilmRollsApi.developFilmRoll`).
/// 서버가 `reviewMode` 계정에 한해 1시간 대기 검사를 면제해주므로, 지역
/// 이탈 확정 직후 곧바로 호출해도 일반 계정은 서버가 안전하게 대기시킨다.
class DevelopFilmRollUseCase {
  DevelopFilmRollUseCase({
    Future<FilmRollDevelopmentResponse> Function(int filmRollId)?
    developFilmRoll,
  }) : _developFilmRoll = developFilmRoll ?? FilmRollsApi.developFilmRoll;

  final Future<FilmRollDevelopmentResponse> Function(int filmRollId)
  _developFilmRoll;

  Future<FilmRollDevelopmentResponse> call(int serverFilmRollId) {
    return _developFilmRoll(serverFilmRollId);
  }
}
