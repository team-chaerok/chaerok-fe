import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/drift.dart';

/// [AppDatabase]의 `film_rolls` 테이블 접근을 담당하는 로컬 데이터소스.
///
/// 계정 전환 시 이전 계정의 필름롤이 노출되지 않도록, 조회/삭제는 현재
/// 로그인 계정([AppPreferences.getCurrentUserId])으로 스코핑된다. 값을
/// 캐싱하지 않고 호출 시점마다 다시 읽으므로, 같은 프로세스 안에서 로그아웃
/// 후 다른 계정으로 바로 로그인해도 별도 재생성 없이 정확히 동작한다.
/// 현재 계정을 아직 알 수 없으면(드문 초기화 레이스) 전체를 보여주는 대신
/// 아무것도 보여주지 않는 쪽을 기본값으로 삼는다.
class FilmRollLocalDataSource {
  const FilmRollLocalDataSource(this._db, {AppPreferences? appPreferences})
    : _preferences = appPreferences;

  final AppDatabase _db;
  final AppPreferences? _preferences;

  Future<int?> currentUserId() {
    final preferences = _preferences ?? AppPreferences.instance;
    return preferences.getCurrentUserId();
  }

  /// [userId]를 명시하면 재조회 없이 그 값으로 스코핑한다. 한 트랜잭션 안에서
  /// 계정 조회+생성처럼 여러 단계에 걸쳐 같은 계정 컨텍스트를 유지해야 할 때
  /// (예: [FilmRollRepositoryImpl.findOrCreateActiveByRegion]) 사용한다.
  Future<FilmRollRow?> findActiveByRegion(
    RegionCode regionCode, {
    int? userId,
  }) async {
    final resolvedUserId = userId ?? await currentUserId();
    if (resolvedUserId == null) return null;
    return (_db.select(_db.filmRolls)..where(
          (t) =>
              t.userId.equals(resolvedUserId) &
              t.regionCode.equalsValue(regionCode) &
              t.status.equalsValue(FilmRollStatus.inProgress),
        ))
        .getSingleOrNull();
  }

  Future<FilmRollRow?> findById(String id) async {
    final userId = await currentUserId();
    if (userId == null) return null;
    return (_db.select(_db.filmRolls)
          ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
        .getSingleOrNull();
  }

  Future<List<FilmRollRow>> findAll() async {
    final userId = await currentUserId();
    if (userId == null) return [];
    return (_db.select(_db.filmRolls)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  /// 행 자체의 변경(생성/수정/삭제)마다 재발행되며, 매 발행 시점에 현재 계정을
  /// 다시 읽어 대조한다. 단, DB에 아무 변경도 없이 계정만 전환된 경우에는
  /// (drift의 watch가 테이블 변경을 트리거로 삼으므로) 새 이벤트가 없어 다음
  /// 실제 변경 전까지는 이전 값이 화면에 남아있을 수 있다.
  Stream<FilmRollRow?> watchById(String id) {
    return (_db.select(
      _db.filmRolls,
    )..where((t) => t.id.equals(id))).watchSingleOrNull().asyncMap((row) async {
      if (row == null) return null;
      final userId = await currentUserId();
      if (userId == null) return null;
      return row.userId == userId ? row : null;
    });
  }

  Future<void> insert(FilmRollsCompanion row) {
    return _db.into(_db.filmRolls).insert(row);
  }

  Future<void> update(String id, FilmRollsCompanion row) {
    return (_db.update(
      _db.filmRolls,
    )..where((t) => t.id.equals(id))).write(row);
  }

  Future<void> deleteById(String id) async {
    final userId = await currentUserId();
    if (userId == null) return;
    await (_db.delete(
      _db.filmRolls,
    )..where((t) => t.id.equals(id) & t.userId.equals(userId))).go();
  }

  /// 계정 스코프 도입(v2) 이전에 생성돼 계정이 비어있는(`userId IS NULL`)
  /// 레거시 행을 [userId] 소유로 1회 확정한다. 이미 귀속된 행은 건드리지 않는다.
  Future<void> claimLegacyData(int userId) {
    return (_db.update(_db.filmRolls)..where((t) => t.userId.isNull())).write(
      FilmRollsCompanion(userId: Value(userId)),
    );
  }
}
