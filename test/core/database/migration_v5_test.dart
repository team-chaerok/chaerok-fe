import 'dart:io';

import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test('v5 스키마: developAvailableAt 컬럼이 존재하고 기본값은 null', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, greaterThanOrEqualTo(5));

    await db
        .into(db.filmRolls)
        .insert(
          FilmRollsCompanion.insert(
            id: 't1',
            regionCode: RegionCode.gongju,
            regionName: '공주시',
            title: '공주 필름롤',
            status: FilmRollStatus.inProgress,
            createdAt: DateTime(2026, 9, 5),
            updatedAt: DateTime(2026, 9, 5),
          ),
        );

    final row = await db.select(db.filmRolls).getSingle();
    expect(row.developAvailableAt, isNull);
  });

  test(
    'v5 스키마: developing/expired 상태와 developAvailableAt을 저장·조회할 수 있다',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      final developAvailableAt = DateTime(2026, 9, 5, 16);
      await db
          .into(db.filmRolls)
          .insert(
            FilmRollsCompanion.insert(
              id: 't2',
              regionCode: RegionCode.seosan,
              regionName: '서산시',
              title: '서산 필름롤',
              status: FilmRollStatus.developing,
              createdAt: DateTime(2026, 9, 5),
              updatedAt: DateTime(2026, 9, 5),
              developAvailableAt: Value(developAvailableAt),
            ),
          );
      await db
          .into(db.filmRolls)
          .insert(
            FilmRollsCompanion.insert(
              id: 't3',
              regionCode: RegionCode.yesan,
              regionName: '예산군',
              title: '예산 필름롤',
              status: FilmRollStatus.expired,
              createdAt: DateTime(2026, 9, 5),
              updatedAt: DateTime(2026, 9, 5),
            ),
          );

      final rows = await db.select(db.filmRolls).get();
      final developing = rows.firstWhere((r) => r.id == 't2');
      final expired = rows.firstWhere((r) => r.id == 't3');

      expect(developing.status, FilmRollStatus.developing);
      expect(developing.developAvailableAt, developAvailableAt);
      expect(expired.status, FilmRollStatus.expired);
      expect(expired.developAvailableAt, isNull);
    },
  );

  test('v4 → v5 실제 마이그레이션: 기존 필름롤 행이 보존되고 developAvailableAt이 추가된다', () async {
    // AppDatabase.forTesting(NativeDatabase.memory())는 항상 최신 스키마로
    // createAll을 실행하므로 onUpgrade 경로를 타지 않는다. 이 테스트는 v4
    // 스키마(develop_available_at 컬럼 없음)를 raw sqlite3로 직접 만들고
    // 기존 데이터를 넣은 뒤, 실제 AppDatabase(schemaVersion=5)로 같은 파일을
    // 열어 진짜 onUpgrade(4, 5)가 실행되는지, 기존 행이 보존되는지 검증한다.
    final tempDir = await Directory.systemTemp.createTemp(
      'migration_v4_to_v5_test',
    );
    addTearDown(() => tempDir.delete(recursive: true));
    final dbFile = File('${tempDir.path}/legacy.sqlite');

    final legacyCreatedAt = DateTime(2026, 8, 1, 10);
    final raw = sqlite3.sqlite3.open(dbFile.path);
    raw.execute('''
        CREATE TABLE film_rolls (
          id TEXT NOT NULL,
          user_id INTEGER NULL,
          region_code TEXT NOT NULL,
          region_name TEXT NOT NULL,
          title TEXT NOT NULL,
          status TEXT NOT NULL,
          selected_course_id TEXT NULL,
          selected_course_title TEXT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          completed_at INTEGER NULL,
          region_id INTEGER NULL,
          filter_id TEXT NULL,
          filter_strength REAL NULL,
          server_film_roll_id INTEGER NULL,
          server_status TEXT NULL,
          PRIMARY KEY (id)
        );
      ''');
    // photos / film_roll_places는 v1부터 존재한 테이블이라 v4 픽스처에도
    // 있어야 한다(onUpgrade의 from < 6 블록이 photos를 UPDATE한다).
    raw.execute('''
        CREATE TABLE film_roll_places (
          id TEXT NOT NULL,
          film_roll_id TEXT NOT NULL,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          category TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          visit_order INTEGER NOT NULL,
          is_visited INTEGER NOT NULL DEFAULT 0,
          visited_at INTEGER NULL,
          PRIMARY KEY (id),
          UNIQUE (film_roll_id, id)
        );
      ''');
    raw.execute('''
        CREATE TABLE photos (
          id TEXT NOT NULL,
          film_roll_id TEXT NOT NULL REFERENCES film_rolls (id) ON DELETE CASCADE,
          film_roll_place_id TEXT NOT NULL,
          original_path TEXT NOT NULL,
          thumbnail_path TEXT NOT NULL,
          latitude REAL NULL,
          longitude REAL NULL,
          taken_at INTEGER NOT NULL,
          is_synced INTEGER NOT NULL DEFAULT 0 CHECK ("is_synced" IN (0, 1)),
          PRIMARY KEY (id),
          FOREIGN KEY (film_roll_id, film_roll_place_id)
            REFERENCES film_roll_places (film_roll_id, id) ON DELETE CASCADE
        );
      ''');
    raw.execute(
      'INSERT INTO film_rolls '
      '(id, region_code, region_name, title, status, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?)',
      [
        'legacy-1',
        'gongju',
        '공주시',
        '공주 필름롤',
        'inProgress',
        legacyCreatedAt.millisecondsSinceEpoch ~/ 1000,
        legacyCreatedAt.millisecondsSinceEpoch ~/ 1000,
      ],
    );
    // v4까지 적용된 상태를 표시 — onUpgrade(4, 최신)이 실행된다.
    raw.execute('PRAGMA user_version = 4;');
    raw.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(db.close);

    final rows = await db.select(db.filmRolls).get();
    expect(rows, hasLength(1));
    final legacy = rows.single;
    expect(legacy.id, 'legacy-1');
    expect(legacy.regionCode, RegionCode.gongju);
    expect(legacy.status, FilmRollStatus.inProgress);
    expect(legacy.createdAt, legacyCreatedAt);
    // 마이그레이션으로 새로 생긴 컬럼은 기존 행에서 기본값(null)이어야 한다.
    expect(legacy.developAvailableAt, isNull);

    // 마이그레이션 이후에는 새 컬럼에 값을 쓰고 읽는 것도 정상 동작해야 한다.
    final developAvailableAt = DateTime(2026, 9, 5, 16);
    await db
        .into(db.filmRolls)
        .insert(
          FilmRollsCompanion.insert(
            id: 'after-migration-1',
            regionCode: RegionCode.buyeo,
            regionName: '부여군',
            title: '부여 필름롤',
            status: FilmRollStatus.developing,
            createdAt: DateTime(2026, 9, 5),
            updatedAt: DateTime(2026, 9, 5),
            developAvailableAt: Value(developAvailableAt),
          ),
        );
    final afterMigration = await (db.select(
      db.filmRolls,
    )..where((t) => t.id.equals('after-migration-1'))).getSingle();
    expect(afterMigration.developAvailableAt, developAvailableAt);
  });
}
