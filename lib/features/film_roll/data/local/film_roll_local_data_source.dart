import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/drift.dart';

/// [AppDatabase]의 `film_rolls` 테이블 접근을 담당하는 로컬 데이터소스.
class FilmRollLocalDataSource {
  const FilmRollLocalDataSource(this._db);

  final AppDatabase _db;

  Future<FilmRollRow?> findActiveByRegion(RegionCode regionCode) {
    return (_db.select(_db.filmRolls)..where(
          (t) =>
              t.regionCode.equalsValue(regionCode) &
              t.status.equalsValue(FilmRollStatus.inProgress),
        ))
        .getSingleOrNull();
  }

  Future<FilmRollRow?> findById(String id) {
    return (_db.select(
      _db.filmRolls,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<FilmRollRow>> findAll() {
    return (_db.select(
      _db.filmRolls,
    )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();
  }

  Stream<FilmRollRow?> watchById(String id) {
    return (_db.select(
      _db.filmRolls,
    )..where((t) => t.id.equals(id))).watchSingleOrNull();
  }

  Future<void> insert(FilmRollsCompanion row) {
    return _db.into(_db.filmRolls).insert(row);
  }

  Future<void> update(String id, FilmRollsCompanion row) {
    return (_db.update(
      _db.filmRolls,
    )..where((t) => t.id.equals(id))).write(row);
  }

  Future<void> deleteById(String id) {
    return (_db.delete(_db.filmRolls)..where((t) => t.id.equals(id))).go();
  }
}
