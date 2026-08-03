import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/file/local_photo_storage.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_place_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/model/film_roll_mapper.dart';
import 'package:chaerok/features/film_roll/domain/entity/course_candidate_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart' show SqliteException;
import 'package:uuid/uuid.dart';

/// [FilmRollRepository]의 Drift 기반 구현체.
class FilmRollRepositoryImpl implements FilmRollRepository {
  FilmRollRepositoryImpl({
    required AppDatabase database,
    required FilmRollLocalDataSource filmRollDataSource,
    required FilmRollPlaceLocalDataSource placeDataSource,
    required PhotoLocalDataSource photoDataSource,
    required LocalPhotoStorage photoStorage,
    Uuid? uuid,
  }) : _db = database,
       _filmRollDs = filmRollDataSource,
       _placeDs = placeDataSource,
       _photoDs = photoDataSource,
       _photoStorage = photoStorage,
       _uuid = uuid ?? const Uuid();

  final AppDatabase _db;
  final FilmRollLocalDataSource _filmRollDs;
  final FilmRollPlaceLocalDataSource _placeDs;
  final PhotoLocalDataSource _photoDs;
  final LocalPhotoStorage _photoStorage;
  final Uuid _uuid;

  @override
  Future<FilmRoll> findOrCreateActiveByRegion({
    required RegionCode regionCode,
    required String regionName,
  }) {
    return _db.transaction(() async {
      final userId = await _filmRollDs.currentUserId();
      if (userId == null) {
        // 이 경로는 이미 인증된 화면(MainTabScreen 등)에서만 호출되므로
        // 현재 계정을 알 수 없는 상태는 로그인 동기화가 아직 안 끝난
        // 예외적 레이스뿐이다. 계정 없이 생성하면 다음 로그인 계정에
        // 잘못 노출될 수 있어, 여기서는 생성하지 않고 예외로 알린다.
        throw StateError('현재 로그인 계정을 확인할 수 없어 필름롤을 생성할 수 없습니다.');
      }

      // 이 트랜잭션 안에서는 위에서 확정한 [userId] 하나만 계속 사용한다.
      // 매번 AppPreferences를 다시 읽으면, 트랜잭션 도중 계정이 바뀌는
      // 극단적인 레이스에서 "조회는 이전 계정 기준, 생성은 새 계정 기준"으로
      // 어긋날 수 있기 때문이다.
      final existing = await _filmRollDs.findActiveByRegion(
        regionCode,
        userId: userId,
      );
      if (existing != null) {
        return _toEntity(existing);
      }

      final now = DateTime.now();
      final row = FilmRollsCompanion.insert(
        id: _uuid.v4(),
        userId: Value(userId),
        regionCode: regionCode,
        regionName: regionName,
        title: regionCode.filmRollTitle,
        status: FilmRollStatus.inProgress,
        createdAt: now,
        updatedAt: now,
      );

      try {
        await _filmRollDs.insert(row);
      } on SqliteException catch (e) {
        // 동시 호출로 부분 유니크 인덱스(지역당 진행중 1개, idx_unique_active_
        // film_roll_per_region) 위반 시에만 다른 호출이 먼저 생성한 레코드를
        // 재조회해 반환한다. 그 외 UNIQUE 위반(예: PK 충돌)이나 다른 DB 오류는
        // 이 레이스와 무관하므로 그대로 전파한다.
        if (!_isActiveRegionUniqueViolation(e)) rethrow;
      }

      final created = await _filmRollDs.findActiveByRegion(
        regionCode,
        userId: userId,
      );
      return _toEntity(created!);
    });
  }

  @override
  Future<FilmRoll?> findById(String filmRollId) async {
    final row = await _filmRollDs.findById(filmRollId);
    if (row == null) return null;
    return _toEntity(row);
  }

  @override
  Future<List<FilmRoll>> findAll() async {
    final rows = await _filmRollDs.findAll();
    final entities = <FilmRoll>[];
    for (final row in rows) {
      entities.add(await _toEntity(row));
    }
    return entities;
  }

  @override
  Stream<FilmRoll?> watchById(String filmRollId) {
    return _filmRollDs.watchById(filmRollId).asyncMap((row) async {
      if (row == null) return null;
      return _toEntity(row);
    });
  }

  @override
  Future<void> selectCourse({
    required String filmRollId,
    required String courseId,
    required String courseTitle,
    required List<CourseCandidatePlace> places,
  }) {
    return _db.transaction(() async {
      final row = await _filmRollDs.findById(filmRollId);
      if (row == null) {
        throw StateError('필름롤을 찾을 수 없습니다: $filmRollId');
      }

      final hasVisitOrPhotoRecords =
          await _placeDs.hasAnyVisited(filmRollId) ||
          await _photoDs.hasAnyByFilmRoll(filmRollId);
      final isDifferentCourse = row.selectedCourseId != courseId;
      if (hasVisitOrPhotoRecords && isDifferentCourse) {
        throw const CourseChangeBlockedException();
      }

      await _placeDs.deleteAllByFilmRoll(filmRollId);
      await _placeDs.insertAll(
        places
            .map(
              (place) => FilmRollPlacesCompanion.insert(
                id: _uuid.v4(),
                filmRollId: filmRollId,
                name: place.name,
                address: place.address,
                category: place.category,
                latitude: place.latitude,
                longitude: place.longitude,
                visitOrder: place.visitOrder,
                serverPlaceId: Value(place.serverPlaceId),
                externalPlaceId: Value(place.externalPlaceId),
                imageUrl: Value(place.imageUrl),
              ),
            )
            .toList(),
      );

      await _filmRollDs.update(
        filmRollId,
        FilmRollsCompanion(
          selectedCourseId: Value(courseId),
          selectedCourseTitle: Value(courseTitle),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> completeFilmRoll(String filmRollId) {
    return _db.transaction(() async {
      final row = await _filmRollDs.findById(filmRollId);
      if (row == null) {
        throw StateError('필름롤을 찾을 수 없습니다: $filmRollId');
      }

      final total = await _placeDs.countByFilmRoll(filmRollId);
      final visited = await _placeDs.countVisitedByFilmRoll(filmRollId);
      final isCompletable =
          row.selectedCourseId != null && total > 0 && visited >= total;
      if (!isCompletable) {
        throw const FilmRollNotCompletableException();
      }

      final now = DateTime.now();
      await _filmRollDs.update(
        filmRollId,
        FilmRollsCompanion(
          status: const Value(FilmRollStatus.completed),
          completedAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    });
  }

  @override
  Future<void> deleteFilmRoll(String filmRollId) async {
    // _filmRollDs.deleteById도 계정으로 스코핑돼 다른 계정 소유 행은 지우지
    // 않지만, 사진 원본 파일 삭제는 Drift를 거치지 않는 별도의 파일 시스템
    // 작업이라 그 보호를 받지 못한다. 그래서 파일을 지우기 전에 먼저
    // findById(현재 계정 스코핑됨)로 소유권을 확인해, 다른 계정 소유이거나
    // 이미 없는 필름롤이면 아무 것도 건드리지 않고 조용히 반환한다.
    final row = await _filmRollDs.findById(filmRollId);
    if (row == null) return;

    // FilmRollPlaces/Photos 행은 FK cascade로 함께 삭제되지만, 실제 사진 파일은
    // DB cascade가 미치지 못하므로 파일 시스템 정리를 별도로 수행한다. 파일
    // 삭제를 DB 삭제보다 먼저 수행해, 파일 삭제가 실패해도 DB 레코드가 남아있어
    // 재시도/복구가 가능하도록 한다(반대 순서면 고아 파일만 남고 재시도할
    // 레코드가 사라진다).
    await _photoStorage.deleteFilmRollDirectory(filmRollId);
    await _filmRollDs.deleteById(filmRollId);
  }

  @override
  Future<void> claimLegacyData(int userId) {
    return _filmRollDs.claimLegacyData(userId);
  }

  Future<FilmRoll> _toEntity(FilmRollRow row) async {
    final total = await _placeDs.countByFilmRoll(row.id);
    final visited = await _placeDs.countVisitedByFilmRoll(row.id);
    return row.toEntity(totalPlaceCount: total, visitedPlaceCount: visited);
  }

  /// [idx_unique_active_film_roll_per_region] 부분 유니크 인덱스(지역당
  /// 진행중 필름롤 1개) 위반인지 확인한다. SQLite는 이 인덱스 위반 시 메시지에
  /// 인덱스가 걸린 컬럼명(`film_rolls.region_code`)을 포함시키므로, 이를 통해
  /// id PK 충돌 등 다른 UNIQUE 위반과 구분한다.
  bool _isActiveRegionUniqueViolation(SqliteException error) {
    return error.message.contains('film_rolls.region_code');
  }
}
