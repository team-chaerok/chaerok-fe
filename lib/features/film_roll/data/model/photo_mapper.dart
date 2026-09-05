import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_photo.dart';

/// Drift Row([Photo]) ↔ 도메인 엔티티([FilmRollPhoto]) 매핑.
extension PhotoMapper on Photo {
  FilmRollPhoto toEntity() {
    return FilmRollPhoto(
      id: id,
      filmRollId: filmRollId,
      filmRollPlaceId: filmRollPlaceId,
      originalPath: originalPath,
      thumbnailPath: thumbnailPath,
      latitude: latitude,
      longitude: longitude,
      takenAt: takenAt,
      sequence: sequence,
      serverPhotoId: serverPhotoId,
      isSynced: isSynced,
    );
  }
}
