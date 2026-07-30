import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/drift.dart';

/// 지역별 필름롤(진행중/완료) 레코드.
/// "지역별 진행중 1개" 제약은 [FilmRollStatus.inProgress]에 대한 부분 유니크 인덱스로
/// `lib/core/database/local_database.dart`의 스키마 생성 시 별도로 구성한다.
/// 도메인 엔티티 `FilmRoll`과 이름이 겹치지 않도록 생성되는 Row 클래스명을 지정한다.
@DataClassName('FilmRollRow')
class FilmRolls extends Table {
  TextColumn get id => text()();
  TextColumn get regionCode => textEnum<RegionCode>()();
  TextColumn get regionName => text()();
  TextColumn get title => text()();
  TextColumn get status => textEnum<FilmRollStatus>()();
  TextColumn get selectedCourseId => text().nullable()();
  TextColumn get selectedCourseTitle => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
