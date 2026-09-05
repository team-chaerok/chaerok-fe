import 'dart:io';

import 'package:chaerok/core/database/tables/film_roll_places_table.dart';
import 'package:chaerok/core/database/tables/film_rolls_table.dart';
import 'package:chaerok/core/database/tables/photos_table.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'local_database.g.dart';

/// 필름롤/코스/방문/사진을 로컬에 저장하는 Drift 데이터베이스.
@DriftDatabase(tables: [FilmRolls, FilmRollPlaces, Photos])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  static AppDatabase? _instance;

  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _createActiveFilmRollUniqueIndex();
      },
      onUpgrade: (m, from, to) async {
        // v2: 계정 전환 시 이전 계정의 로컬 필름롤이 노출되던 버그 수정을 위해
        // film_rolls.user_id 컬럼 추가. 기존 행은 null로 남았다가 로그인/세션
        // 재개 시점에 CurrentAccountSync가 현재 계정으로 1회 귀속시킨다.
        if (from < 2) {
          await m.addColumn(filmRolls, filmRolls.userId);
        }
        // v3: v2에서 만든 부분 유니크 인덱스가 region_code만 보고 있어서
        // "지역당 진행중 필름롤 1개" 제약이 계정 구분 없이 전체 기기에
        // 걸려버렸다. 서로 다른 계정이 같은 지역에 각자 진행중 필름롤을
        // 갖는 정상적인 상황도 UNIQUE constraint failed로 막던 버그라,
        // user_id를 포함하도록 인덱스를 다시 만든다.
        if (from < 3) {
          await customStatement(
            'DROP INDEX IF EXISTS idx_unique_active_film_roll_per_region',
          );
          await _createActiveFilmRollUniqueIndex();
        }
        // v4: 필름롤 생성/방문을 백엔드에 반영하는 동기화 계층 도입. 전부
        // nullable 컬럼이라 기존 행은 null로 남는다 — serverFilmRollId가 null이면
        // "아직 서버에 생성 안 됨", visitSyncedAt가 null이면 "방문 미전송".
        if (from < 4) {
          await m.addColumn(filmRolls, filmRolls.regionId);
          await m.addColumn(filmRolls, filmRolls.filterId);
          await m.addColumn(filmRolls, filmRolls.filterStrength);
          await m.addColumn(filmRolls, filmRolls.serverFilmRollId);
          await m.addColumn(filmRolls, filmRolls.serverStatus);
          await m.addColumn(filmRollPlaces, filmRollPlaces.visitSyncedAt);
        }
        // v5: 지역 이탈 확정 → 현상 대기 → 현상 완료 라이프사이클 도입.
        // FilmRollStatus.developing/expired는 문자열 컬럼값이라 스키마 변경이
        // 아니지만, 현상 완료 예정 시각을 보관할 컬럼은 새로 필요하다.
        if (from < 5) {
          await m.addColumn(filmRolls, filmRolls.developAvailableAt);
        }
        // v6: 방문 인증 사진 경로를 절대 경로로 저장하던 것을 문서 디렉터리
        // 기준 상대 경로로 바꾼다. iOS는 앱 Data 컨테이너 절대 경로
        // (.../Application/{UUID}/)가 재설치·백업 복원 시 바뀌어, 기존에 저장된
        // 절대 경로로는 파일을 찾지 못한다. 'film_rolls/' 세그먼트부터 잘라
        // 상대 경로로 재작성한다. 이미 상대 경로인 행은 instr가 1을 반환해
        // substr(x, 1) = 원본 그대로라 영향이 없다.
        if (from < 6) {
          await _relativizePhotoPath('original_path');
          await _relativizePhotoPath('thumbnail_path');
        }
      },
      // FilmRolls 삭제 시 FilmRollPlaces/Photos가 cascade로 함께 삭제되도록
      // SQLite의 외래 키 제약을 명시적으로 활성화한다(기본값 OFF).
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
      },
    );
  }

  /// photos 테이블의 경로 컬럼([column])에서 'film_rolls/' 이후만 남겨
  /// 문서 디렉터리 기준 상대 경로로 만든다. 'film_rolls/'를 포함하지 않는
  /// 행은 건드리지 않고, 이미 상대 경로인 행은 값이 그대로 유지된다.
  Future<void> _relativizePhotoPath(String column) async {
    await customStatement(
      "UPDATE photos SET $column = substr($column, instr($column, 'film_rolls/')) "
      "WHERE instr($column, 'film_rolls/') > 0",
    );
  }

  /// 계정별로 지역당 진행중(inProgress) 필름롤이 1개만 존재하도록 강제하는
  /// 부분 유니크 인덱스. user_id를 포함하지 않으면 서로 다른 계정끼리도
  /// 같은 지역을 동시에 진행할 수 없게 되어버린다. 완료(completed) 필름롤은
  /// 지역당 여러 개 허용되므로 status 조건을 둔다.
  Future<void> _createActiveFilmRollUniqueIndex() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_film_roll_per_region '
      "ON film_rolls(user_id, region_code) WHERE status = 'inProgress';",
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'chaerok_local.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
