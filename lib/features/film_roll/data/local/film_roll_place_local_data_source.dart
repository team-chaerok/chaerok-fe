import 'package:chaerok/core/database/local_database.dart';
import 'package:drift/drift.dart';

/// [AppDatabase]의 `film_roll_places` 테이블 접근을 담당하는 로컬 데이터소스.
class FilmRollPlaceLocalDataSource {
  const FilmRollPlaceLocalDataSource(this._db);

  final AppDatabase _db;

  Future<List<FilmRollPlaceRow>> findByFilmRoll(String filmRollId) {
    return (_db.select(_db.filmRollPlaces)
          ..where((t) => t.filmRollId.equals(filmRollId))
          ..orderBy([(t) => OrderingTerm.asc(t.visitOrder)]))
        .get();
  }

  Future<FilmRollPlaceRow?> findById(String id) {
    return (_db.select(
      _db.filmRollPlaces,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<int> countByFilmRoll(String filmRollId) {
    final count = _db.filmRollPlaces.id.count();
    final query = _db.selectOnly(_db.filmRollPlaces)
      ..addColumns([count])
      ..where(_db.filmRollPlaces.filmRollId.equals(filmRollId));
    return query.map((row) => row.read(count)!).getSingle();
  }

  Future<int> countVisitedByFilmRoll(String filmRollId) {
    final count = _db.filmRollPlaces.id.count();
    final query = _db.selectOnly(_db.filmRollPlaces)
      ..addColumns([count])
      ..where(
        _db.filmRollPlaces.filmRollId.equals(filmRollId) &
            _db.filmRollPlaces.isVisited.equals(true),
      );
    return query.map((row) => row.read(count)!).getSingle();
  }

  Future<bool> hasAnyVisited(String filmRollId) async {
    return await countVisitedByFilmRoll(filmRollId) > 0;
  }

  Future<void> insertAll(List<FilmRollPlacesCompanion> rows) {
    return _db.batch((batch) => batch.insertAll(_db.filmRollPlaces, rows));
  }

  Future<void> deleteAllByFilmRoll(String filmRollId) {
    return (_db.delete(
      _db.filmRollPlaces,
    )..where((t) => t.filmRollId.equals(filmRollId))).go();
  }

  Future<void> update(String id, FilmRollPlacesCompanion row) {
    return (_db.update(
      _db.filmRollPlaces,
    )..where((t) => t.id.equals(id))).write(row);
  }
}
