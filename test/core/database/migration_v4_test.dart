import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v4 스키마: 필름롤 서버 동기화 컬럼이 존재하고 기본값은 null', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(db.schemaVersion, 4);

    await db
        .into(db.filmRolls)
        .insert(
          FilmRollsCompanion.insert(
            id: 't1',
            regionCode: RegionCode.gongju,
            regionName: '공주시',
            title: '공주 필름롤',
            status: FilmRollStatus.inProgress,
            createdAt: DateTime(2026, 8, 30),
            updatedAt: DateTime(2026, 8, 30),
            regionId: const Value(11),
          ),
        );

    final row = await db.select(db.filmRolls).getSingle();
    expect(row.regionId, 11);
    expect(row.serverFilmRollId, isNull);
    expect(row.serverStatus, isNull);
    expect(row.filterId, isNull);
    expect(row.filterStrength, isNull);
  });

  test('v4 스키마: FilmRollPlaces.visitSyncedAt 컬럼이 존재한다', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await db
        .into(db.filmRolls)
        .insert(
          FilmRollsCompanion.insert(
            id: 'fr1',
            regionCode: RegionCode.buyeo,
            regionName: '부여군',
            title: '부여 필름롤',
            status: FilmRollStatus.inProgress,
            createdAt: DateTime(2026, 8, 30),
            updatedAt: DateTime(2026, 8, 30),
          ),
        );
    await db
        .into(db.filmRollPlaces)
        .insert(
          FilmRollPlacesCompanion.insert(
            id: 'p1',
            filmRollId: 'fr1',
            name: '장소1',
            address: '주소1',
            category: '카테고리',
            latitude: 36.0,
            longitude: 126.0,
            visitOrder: 0,
          ),
        );

    final place = await db.select(db.filmRollPlaces).getSingle();
    expect(place.visitSyncedAt, isNull);
  });
}
