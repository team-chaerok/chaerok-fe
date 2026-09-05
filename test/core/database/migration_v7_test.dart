import 'dart:io';

import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;

void main() {
  test('v7 스키마: photos에 sequence·serverPhotoId 컬럼이 있고 기본값을 쓴다', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, greaterThanOrEqualTo(7));

    await db
        .into(db.filmRolls)
        .insert(
          FilmRollsCompanion.insert(
            id: 'fr1',
            regionCode: RegionCode.gongju,
            regionName: '공주시',
            title: '공주 필름롤',
            status: FilmRollStatus.inProgress,
            createdAt: DateTime(2026, 9, 6),
            updatedAt: DateTime(2026, 9, 6),
          ),
        );
    await db
        .into(db.filmRollPlaces)
        .insert(
          FilmRollPlacesCompanion.insert(
            id: 'p1',
            filmRollId: 'fr1',
            name: 'A',
            address: 'a',
            category: 'cat',
            latitude: 36,
            longitude: 126,
            visitOrder: 0,
          ),
        );
    await db
        .into(db.photos)
        .insert(
          PhotosCompanion.insert(
            id: 'ph1',
            filmRollId: 'fr1',
            filmRollPlaceId: 'p1',
            originalPath: '/o.jpg',
            thumbnailPath: '/t.jpg',
            takenAt: DateTime(2026, 9, 6, 14),
            sequence: const Value(3),
            serverPhotoId: const Value(99),
          ),
        );

    final row = await db.select(db.photos).getSingle();
    expect(row.sequence, 3);
    expect(row.serverPhotoId, 99);
  });

  test('v6 → v7 실제 마이그레이션: 기존 사진 sequence를 taken_at 순으로 백필한다', () async {
    // v6 스키마(sequence/server_photo_id 컬럼 없음)를 raw sqlite3로 만들고,
    // 같은 필름롤 사진 2장을 넣은 뒤 실제 onUpgrade(6, 7)를 태운다.
    final tempDir = await Directory.systemTemp.createTemp('migration_v6_to_v7');
    addTearDown(() => tempDir.delete(recursive: true));
    final dbFile = File('${tempDir.path}/legacy.sqlite');

    final t1 = DateTime(2026, 9, 6, 14);
    final t2 = DateTime(2026, 9, 6, 15);
    final raw = sqlite3.sqlite3.open(dbFile.path);
    raw.execute('''
      CREATE TABLE photos (
        id TEXT NOT NULL,
        film_roll_id TEXT NOT NULL,
        film_roll_place_id TEXT NOT NULL,
        original_path TEXT NOT NULL,
        thumbnail_path TEXT NOT NULL,
        latitude REAL NULL,
        longitude REAL NULL,
        taken_at INTEGER NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0,
        PRIMARY KEY (id)
      );
    ''');
    void insertPhoto(String id, DateTime takenAt) {
      raw.execute(
        'INSERT INTO photos '
        '(id, film_roll_id, film_roll_place_id, original_path, thumbnail_path, taken_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        [
          id,
          'fr1',
          'p1',
          '/$id-o.jpg',
          '/$id-t.jpg',
          takenAt.millisecondsSinceEpoch ~/ 1000,
        ],
      );
    }

    insertPhoto('ph2', t2);
    insertPhoto('ph1', t1);
    raw.execute('PRAGMA user_version = 6;');
    raw.dispose();

    final db = AppDatabase.forTesting(NativeDatabase(dbFile));
    addTearDown(db.close);

    final photos = await db.select(db.photos).get();
    expect(photos, hasLength(2));
    expect(photos.firstWhere((p) => p.id == 'ph1').sequence, 1);
    expect(photos.firstWhere((p) => p.id == 'ph2').sequence, 2);
    // 새 컬럼은 기존 행에서 null이어야 한다.
    expect(photos.every((p) => p.serverPhotoId == null), isTrue);

    // 마이그레이션 이후 새 컬럼 쓰기/읽기도 정상 동작해야 한다.
    await (db.update(db.photos)..where((t) => t.id.equals('ph1'))).write(
      const PhotosCompanion(serverPhotoId: Value(1234), isSynced: Value(true)),
    );
    final updated = await (db.select(
      db.photos,
    )..where((t) => t.id.equals('ph1'))).getSingle();
    expect(updated.serverPhotoId, 1234);
    expect(updated.isSynced, isTrue);
  });
}
