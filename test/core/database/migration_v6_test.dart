import 'dart:io';

import 'package:chaerok/core/database/local_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test('v6 스키마: photos 경로 컬럼이 존재한다', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, greaterThanOrEqualTo(6));
  });

  test(
    'v5 → v6 마이그레이션: 절대 경로 photo 행은 상대 경로로 재작성되고 이미 상대 경로인 행은 보존된다',
    () async {
      // AppDatabase.forTesting(NativeDatabase.memory())는 항상 최신 스키마로
      // createAll을 실행하므로 onUpgrade 경로를 타지 않는다. 이 테스트는 v5
      // 스키마를 raw sqlite3로 직접 만들고 절대/상대 경로가 섞인 photo 행을
      // 넣은 뒤, 실제 AppDatabase로 같은 파일을 열어 onUpgrade(5, 6)가
      // 경로를 상대화하는지 검증한다.
      final tempDir = await Directory.systemTemp.createTemp(
        'migration_v5_to_v6',
      );
      addTearDown(() => tempDir.delete(recursive: true));
      final dbFile = File('${tempDir.path}/legacy.sqlite');

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
          develop_available_at INTEGER NULL,
          PRIMARY KEY (id)
        );
      ''');
      raw.execute('''
        CREATE TABLE film_roll_places (
          id TEXT NOT NULL,
          film_roll_id TEXT NOT NULL,
          server_place_id INTEGER NULL,
          external_place_id TEXT NULL,
          name TEXT NOT NULL,
          address TEXT NOT NULL,
          category TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL,
          image_url TEXT NULL,
          visit_order INTEGER NOT NULL,
          is_visited INTEGER NOT NULL DEFAULT 0,
          visited_at INTEGER NULL,
          visit_synced_at INTEGER NULL,
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

      final takenAt = DateTime(2026, 8, 1, 10).millisecondsSinceEpoch ~/ 1000;
      raw.execute(
        'INSERT INTO film_rolls (id, region_code, region_name, title, status, '
        'created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        ['fr1', 'gongju', '공주시', '공주 필름롤', 'inProgress', takenAt, takenAt],
      );
      raw.execute(
        'INSERT INTO film_roll_places (id, film_roll_id, name, address, '
        'category, latitude, longitude, visit_order) '
        'VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        ['p1', 'fr1', '장소1', '주소1', '카테고리', 36.0, 126.0, 0],
      );

      const oldContainer =
          '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/';
      raw.execute(
        'INSERT INTO photos (id, film_roll_id, film_roll_place_id, '
        'original_path, thumbnail_path, taken_at) VALUES (?, ?, ?, ?, ?, ?)',
        [
          'legacy-abs',
          'fr1',
          'p1',
          '${oldContainer}film_rolls/fr1/p1/original/legacy-abs.jpg',
          '${oldContainer}film_rolls/fr1/p1/thumbnail/legacy-abs.jpg',
          takenAt,
        ],
      );
      raw.execute(
        'INSERT INTO photos (id, film_roll_id, film_roll_place_id, '
        'original_path, thumbnail_path, taken_at) VALUES (?, ?, ?, ?, ?, ?)',
        [
          'already-rel',
          'fr1',
          'p1',
          'film_rolls/fr1/p1/original/already-rel.jpg',
          'film_rolls/fr1/p1/thumbnail/already-rel.jpg',
          takenAt,
        ],
      );
      raw.execute('PRAGMA user_version = 5;');
      raw.dispose();

      final db = AppDatabase.forTesting(NativeDatabase(dbFile));
      addTearDown(db.close);

      final rows = await db.select(db.photos).get();
      final legacy = rows.firstWhere((r) => r.id == 'legacy-abs');
      final alreadyRel = rows.firstWhere((r) => r.id == 'already-rel');

      expect(legacy.originalPath, 'film_rolls/fr1/p1/original/legacy-abs.jpg');
      expect(
        legacy.thumbnailPath,
        'film_rolls/fr1/p1/thumbnail/legacy-abs.jpg',
      );
      expect(
        alreadyRel.originalPath,
        'film_rolls/fr1/p1/original/already-rel.jpg',
      );
      expect(
        alreadyRel.thumbnailPath,
        'film_rolls/fr1/p1/thumbnail/already-rel.jpg',
      );
    },
  );
}
