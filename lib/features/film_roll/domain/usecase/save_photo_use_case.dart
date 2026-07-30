import 'dart:typed_data';

import 'package:chaerok/features/film_roll/domain/entity/film_roll_photo.dart';
import 'package:chaerok/features/film_roll/domain/repository/photo_repository.dart';

/// 촬영한 사진을 앱 내부 파일 시스템에 저장하고 메타데이터를 DB에 기록한다.
class SavePhotoUseCase {
  const SavePhotoUseCase(this._photoRepository);

  final PhotoRepository _photoRepository;

  Future<FilmRollPhoto> call({
    required String filmRollId,
    required String filmRollPlaceId,
    required Uint8List imageBytes,
    double? latitude,
    double? longitude,
  }) {
    return _photoRepository.savePhoto(
      filmRollId: filmRollId,
      filmRollPlaceId: filmRollPlaceId,
      imageBytes: imageBytes,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
