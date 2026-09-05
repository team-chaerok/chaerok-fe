import 'package:chaerok/core/database/local_database.dart';
import 'package:drift/drift.dart';

/// [AppDatabase]의 `photos` 테이블 접근을 담당하는 로컬 데이터소스.
class PhotoLocalDataSource {
  const PhotoLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<Photo>> findByPlace(String filmRollPlaceId) {
    return (_db.select(_db.photos)
          ..where((t) => t.filmRollPlaceId.equals(filmRollPlaceId))
          ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]))
        .get();
  }

  Future<Photo?> findById(String id) {
    return (_db.select(
      _db.photos,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// 필름롤 전체에서 촬영된 사진을 최신순으로 조회합니다.
  Future<List<Photo>> findByFilmRoll(String filmRollId, {int? limit}) {
    final query = _db.select(_db.photos)
      ..where((t) => t.filmRollId.equals(filmRollId))
      ..orderBy([(t) => OrderingTerm.desc(t.takenAt)]);
    if (limit != null) query.limit(limit);
    return query.get();
  }

  Future<int> countByPlace(String filmRollPlaceId) async {
    final rows = await findByPlace(filmRollPlaceId);
    return rows.length;
  }

  Future<int> countByFilmRoll(String filmRollId) {
    final count = _db.photos.id.count();
    final query = _db.selectOnly(_db.photos)
      ..addColumns([count])
      ..where(_db.photos.filmRollId.equals(filmRollId));
    return query.map((row) => row.read(count)!).getSingle();
  }

  /// 서버에 아직 업로드되지 않은 사진을 sequence 오름차순으로 조회한다.
  Future<List<Photo>> findUnuploadedByFilmRoll(String filmRollId) {
    return (_db.select(_db.photos)
          ..where(
            (t) => t.filmRollId.equals(filmRollId) & t.serverPhotoId.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.sequence)]))
        .get();
  }

  /// 이 장소에서 촬영했고 서버 업로드가 끝난 사진 중 sequence가 가장 작은 것.
  Future<Photo?> firstUploadedByPlace(String filmRollPlaceId) {
    return (_db.select(_db.photos)
          ..where(
            (t) =>
                t.filmRollPlaceId.equals(filmRollPlaceId) &
                t.serverPhotoId.isNotNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.sequence)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> setServerPhotoId(String id, int serverPhotoId) {
    return (_db.update(_db.photos)..where((t) => t.id.equals(id))).write(
      PhotosCompanion(
        serverPhotoId: Value(serverPhotoId),
        isSynced: const Value(true),
      ),
    );
  }

  Future<bool> hasAnyByFilmRoll(String filmRollId) async {
    final row =
        await (_db.select(_db.photos)
              ..where((t) => t.filmRollId.equals(filmRollId))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> insert(PhotosCompanion row) {
    return _db.into(_db.photos).insert(row);
  }

  Future<void> deleteById(String id) {
    return (_db.delete(_db.photos)..where((t) => t.id.equals(id))).go();
  }
}
