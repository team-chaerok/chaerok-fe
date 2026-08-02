// drift_dev가 아래 customConstraints의 'film_roll_places' 참조를 이름으로
// 찾으려면 이 import가 파일에 있어야 한다(코드상 심볼 사용은 없음).
// ignore: unused_import
import 'package:chaerok/core/database/tables/film_roll_places_table.dart';
import 'package:chaerok/core/database/tables/film_rolls_table.dart';
import 'package:drift/drift.dart';

/// 방문 인증 사진 메타데이터. 원본 파일은 앱 내부 파일 시스템에 저장하고,
/// 이 테이블에는 경로/좌표/촬영시각만 저장한다.
class Photos extends Table {
  TextColumn get id => text()();
  TextColumn get filmRollId =>
      text().references(FilmRolls, #id, onDelete: KeyAction.cascade)();
  // filmRollPlaceId는 filmRollId와 함께 복합 외래키(customConstraints)로
  // FilmRollPlaces를 참조한다. 이는 photo가 가리키는 장소가 반드시 같은
  // filmRollId에 속하도록 강제해 다른 필름롤의 장소를 참조하는 것을 막는다.
  TextColumn get filmRollPlaceId => text()();
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

  // filmRollId만 단독 참조하는 개별 FK 대신, filmRollId와 filmRollPlaceId를
  // 함께 검증하는 복합 외래키를 선언해 photo가 참조하는 장소가 반드시
  // 같은 필름롤에 속하도록 강제한다. FilmRollPlaces 쪽 (filmRollId, id)에는
  // 대응하는 UNIQUE 제약(film_roll_places_table.dart의 uniqueKeys)이 있다.
  @override
  List<String> get customConstraints => [
    'FOREIGN KEY(film_roll_id, film_roll_place_id) '
        'REFERENCES film_roll_places(film_roll_id, id) ON DELETE CASCADE',
  ];
}
