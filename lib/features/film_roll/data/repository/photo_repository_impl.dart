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
      // DB에는 문서 디렉터리 기준 상대 경로만 저장한다. 절대 경로는 iOS 앱
      // 컨테이너 UUID가 재설치·백업 복원 시 바뀌어 이후 파일을 못 찾는다.
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
      originalPath: await _photoStorage.resolve(paths.originalPath),
      thumbnailPath: await _photoStorage.resolve(paths.thumbnailPath),
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
    return _resolvePaths(rows);
  }

  @override
  Future<List<FilmRollPhoto>> findByFilmRoll(
    String filmRollId, {
    int? limit,
  }) async {
    final rows = await _photoDs.findByFilmRoll(filmRollId, limit: limit);
    return _resolvePaths(rows);
  }

  /// Drift 행을 엔티티로 매핑하면서, DB에 저장된 상대 경로(또는 구버전 절대
  /// 경로)를 실제 접근 가능한 절대 경로로 복원한다.
  Future<List<FilmRollPhoto>> _resolvePaths(List<Photo> rows) {
    return Future.wait(
      rows.map((row) async {
        final entity = row.toEntity();
        return entity.copyWith(
          originalPath: await _photoStorage.resolve(entity.originalPath),
          thumbnailPath: await _photoStorage.resolve(entity.thumbnailPath),
        );
      }),
    );
  }

  @override
  Future<int> countByFilmRoll(String filmRollId) {
    return _photoDs.countByFilmRoll(filmRollId);
  }
}
