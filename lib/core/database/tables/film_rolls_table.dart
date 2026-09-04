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
  // 마이그레이션 이전(v1) 레거시 행은 계정을 알 수 없어 null로 남는다.
  // 로그인/세션 재개 시점에 현재 계정으로 1회 귀속(claim)된 뒤에는 항상 값이 채워진다.
  IntColumn get userId => integer().nullable()();
  TextColumn get regionCode => textEnum<RegionCode>()();
  TextColumn get regionName => text()();
  TextColumn get title => text()();
  TextColumn get status => textEnum<FilmRollStatus>()();
  TextColumn get selectedCourseId => text().nullable()();
  TextColumn get selectedCourseTitle => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();

  // v5: 지역 이탈 확정(exit) 후 현상 완료 예정 시각. developing 상태에서만
  // 값이 채워지며, 현상 대기 화면의 카운트다운 기준으로 쓰인다.
  DateTimeColumn get developAvailableAt => dateTime().nullable()();

  // 백엔드 필름롤 동기화용. 로컬이 source of truth이며, 아래 컬럼은 서버
  // 필름롤과의 연결/생성 파라미터를 보관한다. serverFilmRollId가 null이면
  // "아직 서버에 생성되지 않음"으로 취급한다.
  IntColumn get regionId => integer().nullable()();
  TextColumn get filterId => text().nullable()();
  RealColumn get filterStrength => real().nullable()();
  IntColumn get serverFilmRollId => integer().nullable()();
  TextColumn get serverStatus => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
