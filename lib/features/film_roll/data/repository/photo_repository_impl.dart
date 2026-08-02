import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/file/local_photo_storage.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/model/photo_mapper.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_photo.dart';
import 'package:chaerok/features/film_roll/domain/repository/photo_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// [PhotoRepository]의 Drift + 파일 시스템 기반 구현체.
class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl({
    required PhotoLocalDataSource photoDataSource,
    required LocalPhotoStorage photoStorage,
    Uuid? uuid,
  }) : _photoDs = photoDataSource,
       _photoStorage = photoStorage,
       _uuid = uuid ?? const Uuid();

  final PhotoLocalDataSource _photoDs;
  final LocalPhotoStorage _photoStorage;
  final Uuid _uuid;

  @override
  Future<FilmRollPhoto> savePhoto({
    required String filmRollId,
    required String filmRollPlaceId,
    required Uint8List imageBytes,
    double? latitude,
    double? longitude,
  }) async {
    final photoId = _uuid.v4();
    final paths = await _photoStorage.save(
      filmRollId: filmRollId,
      filmRollPlaceId: filmRollPlaceId,
      photoId: photoId,
      imageBytes: imageBytes,
    );

    final now = DateTime.now();
    try {
      await _photoDs.insert(
        PhotosCompanion.insert(
          id: photoId,
          filmRollId: filmRollId,
          filmRollPlaceId: filmRollPlaceId,
          originalPath: paths.originalPath,
          thumbnailPath: paths.thumbnailPath,
          takenAt: now,
          latitude: Value(latitude),
          longitude: Value(longitude),
        ),
      );
    } catch (_) {
      // DB insert 실패 시 이미 저장된 파일이 고아로 남지 않도록 정리한 뒤
      // 원래 실패를 그대로 전파한다.
      await _photoStorage.delete(
        originalPath: paths.originalPath,
        thumbnailPath: paths.thumbnailPath,
      );
      rethrow;
    }

    return FilmRollPhoto(
      id: photoId,
      filmRollId: filmRollId,
      filmRollPlaceId: filmRollPlaceId,
      originalPath: paths.originalPath,
      thumbnailPath: paths.thumbnailPath,
      latitude: latitude,
      longitude: longitude,
      takenAt: now,
      isSynced: false,
    );
  }

  @override
  Future<void> deletePhoto(String photoId) async {
    final row = await _photoDs.findById(photoId);
    if (row == null) return;

    await _photoDs.deleteById(photoId);
    await _photoStorage.delete(
      originalPath: row.originalPath,
      thumbnailPath: row.thumbnailPath,
    );
  }

  @override
  Future<List<FilmRollPhoto>> findByPlace(String filmRollPlaceId) async {
    final rows = await _photoDs.findByPlace(filmRollPlaceId);
    return rows.map((row) => row.toEntity()).toList();
  }
}
