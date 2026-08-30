import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_place_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/model/film_roll_place_mapper.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_place_repository.dart';
import 'package:drift/drift.dart';

/// [FilmRollPlaceRepository]의 Drift 기반 구현체.
class FilmRollPlaceRepositoryImpl implements FilmRollPlaceRepository {
  FilmRollPlaceRepositoryImpl({
    required FilmRollPlaceLocalDataSource placeDataSource,
    required PhotoLocalDataSource photoDataSource,
  }) : _placeDs = placeDataSource,
       _photoDs = photoDataSource;

  final FilmRollPlaceLocalDataSource _placeDs;
  final PhotoLocalDataSource _photoDs;

  @override
  Future<List<FilmRollPlace>> findByFilmRoll(String filmRollId) async {
    final rows = await _placeDs.findByFilmRoll(filmRollId);
    final entities = <FilmRollPlace>[];
    for (final row in rows) {
      final photoCount = await _photoDs.countByPlace(row.id);
      entities.add(row.toEntity(photoCount: photoCount));
    }
    return entities;
  }

  @override
  Future<FilmRollPlace?> findById(String filmRollPlaceId) async {
    final row = await _placeDs.findById(filmRollPlaceId);
    if (row == null) return null;
    final photoCount = await _photoDs.countByPlace(filmRollPlaceId);
    return row.toEntity(photoCount: photoCount);
  }

  @override
  Future<void> markVisited(String filmRollPlaceId) async {
    final row = await _placeDs.findById(filmRollPlaceId);
    if (row == null) {
      throw StateError('필름롤 장소를 찾을 수 없습니다: $filmRollPlaceId');
    }
    // 이미 방문 처리된 장소라면 아무 것도 하지 않는다(중복 방지, 최초 방문 시각 보존).
    if (row.isVisited) return;

    await _placeDs.update(
      filmRollPlaceId,
      FilmRollPlacesCompanion(
        isVisited: const Value(true),
        visitedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<bool> hasAnyVisitedOrPhoto(String filmRollId) async {
    final hasVisited = await _placeDs.hasAnyVisited(filmRollId);
    if (hasVisited) return true;
    return _photoDs.hasAnyByFilmRoll(filmRollId);
  }

  @override
  Future<List<FilmRollPlace>> findUnsyncedVisitedPlaces(
    String filmRollId,
  ) async {
    final rows = await _placeDs.findByFilmRoll(filmRollId);
    final result = <FilmRollPlace>[];
    for (final row in rows) {
      if (!row.isVisited || row.visitSyncedAt != null) continue;
      final photoCount = await _photoDs.countByPlace(row.id);
      result.add(row.toEntity(photoCount: photoCount));
    }
    return result;
  }

  @override
  Future<void> markVisitSynced(String filmRollPlaceId, {required DateTime at}) {
    return _placeDs.update(
      filmRollPlaceId,
      FilmRollPlacesCompanion(visitSyncedAt: Value(at)),
    );
  }
}
