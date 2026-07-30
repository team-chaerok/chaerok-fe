import 'package:chaerok/core/database/tables/film_roll_places_table.dart';
import 'package:chaerok/core/database/tables/film_rolls_table.dart';
import 'package:drift/drift.dart';

/// 방문 인증 사진 메타데이터. 원본 파일은 앱 내부 파일 시스템에 저장하고,
/// 이 테이블에는 경로/좌표/촬영시각만 저장한다.
class Photos extends Table {
  TextColumn get id => text()();
  TextColumn get filmRollId =>
      text().references(FilmRolls, #id, onDelete: KeyAction.cascade)();
  TextColumn get filmRollPlaceId =>
      text().references(FilmRollPlaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get originalPath => text()();
  TextColumn get thumbnailPath => text()();
  RealColumn get latitude => real().nullable()();
  RealColumn get longitude => real().nullable()();
  DateTimeColumn get takenAt => dateTime()();
  // 서버 동기화는 이번 스코프 밖. 필드만 예약하고 항상 false로 둔다.
  // TODO(#41): 서버 동기화 기능 구현 시 실제 동기화 로직 연결.
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
