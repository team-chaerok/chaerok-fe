import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
