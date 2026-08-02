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

  Future<int> countByPlace(String filmRollPlaceId) async {
    final rows = await findByPlace(filmRollPlaceId);
    return rows.length;
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
