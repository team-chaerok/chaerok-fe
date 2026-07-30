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

  @override
  Set<Column> get primaryKey => {id};
}
