import 'package:chaerok/features/film_roll/domain/repository/photo_repository.dart';

/// 사진 파일과 메타데이터를 함께 삭제한다.
class DeletePhotoUseCase {
  const DeletePhotoUseCase(this._photoRepository);

  final PhotoRepository _photoRepository;

  Future<void> call(String photoId) {
    return _photoRepository.deletePhoto(photoId);
  }
}
