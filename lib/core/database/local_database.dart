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
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _createActiveFilmRollUniqueIndex();
      },
      // FilmRolls 삭제 시 FilmRollPlaces/Photos가 cascade로 함께 삭제되도록
      // SQLite의 외래 키 제약을 명시적으로 활성화한다(기본값 OFF).
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON;');
      },
    );
  }

  /// 지역당 진행중(inProgress) 필름롤이 1개만 존재하도록 강제하는 부분 유니크 인덱스.
  /// 완료(completed) 필름롤은 지역당 여러 개 허용되므로 status 조건을 둔다.
  Future<void> _createActiveFilmRollUniqueIndex() async {
    await customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_film_roll_per_region '
      "ON film_rolls(region_code) WHERE status = 'inProgress';",
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
