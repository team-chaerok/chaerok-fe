import 'package:chaerok/core/database/tables/film_rolls_table.dart';
import 'package:drift/drift.dart';

/// 필름롤에 선택된 코스의 장소 스냅샷(API 응답을 확정 시점에 복제한 로컬 레코드).
/// 도메인 엔티티 `FilmRollPlace`와 이름이 겹치지 않도록 생성되는 Row 클래스명을 지정한다.
@DataClassName('FilmRollPlaceRow')
class FilmRollPlaces extends Table {
  TextColumn get id => text()();
  TextColumn get filmRollId =>
      text().references(FilmRolls, #id, onDelete: KeyAction.cascade)();
  IntColumn get serverPlaceId => integer().nullable()();
  TextColumn get externalPlaceId => text().nullable()();
  TextColumn get name => text()();
  TextColumn get address => text()();
  TextColumn get category => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get imageUrl => text().nullable()();
  IntColumn get visitOrder => integer()();
  BoolColumn get isVisited => boolean().withDefault(const Constant(false))();
  DateTimeColumn get visitedAt => dateTime().nullable()();

  /// 이 장소의 방문 인증이 서버(`POST /film-rolls/{id}/visits`)에 반영된 시각.
  /// null이면 아직 서버로 전송되지 않은 상태.
  DateTimeColumn get visitSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  // Photos.filmRollId/filmRollPlaceId 복합 외래키가 이 컬럼 조합을 참조하므로,
  // SQLite가 요구하는 대로 (filmRollId, id) 전용 UNIQUE 인덱스를 별도로 선언한다.
  @override
  List<Set<Column>> get uniqueKeys => [
    {filmRollId, id},
  ];
}
