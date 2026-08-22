import 'package:chaerok/features/film_roll/domain/repository/photo_repository.dart';

/// 필름롤 전체에서 촬영된 사진 수를 조회한다.
class GetFilmRollPhotoCountUseCase {
  const GetFilmRollPhotoCountUseCase(this._photoRepository);

  final PhotoRepository _photoRepository;

  Future<int> call(String filmRollId) {
    return _photoRepository.countByFilmRoll(filmRollId);
  }
}
