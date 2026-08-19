import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _insertFilmRoll(AppDatabase database, String id) {
  final now = DateTime.now();
  return database
      .into(database.filmRolls)
      .insert(
        FilmRollsCompanion.insert(
          id: id,
          regionCode: RegionCode.gongju,
          regionName: '공주시',
          title: '공주',
          status: FilmRollStatus.inProgress,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

Future<void> _insertFilmRollPlace(
  AppDatabase database, {
  required String id,
  required String filmRollId,
}) {
  return database
      .into(database.filmRollPlaces)
      .insert(
        FilmRollPlacesCompanion.insert(
          id: id,
          filmRollId: filmRollId,
          name: '장소',
          address: '주소',
          category: '카테고리',
          latitude: 0,
          longitude: 0,
          visitOrder: 0,
        ),
      );
}

Future<void> _insertPhoto(
  AppDatabase database, {
  required String id,
  required String filmRollId,
  required String filmRollPlaceId,
  required DateTime takenAt,
}) {
  return database
      .into(database.photos)
      .insert(
        PhotosCompanion.insert(
          id: id,
          filmRollId: filmRollId,
          filmRollPlaceId: filmRollPlaceId,
          originalPath: '/tmp/$id-original.jpg',
          thumbnailPath: '/tmp/$id-thumb.jpg',
          takenAt: takenAt,
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late PhotoLocalDataSource dataSource;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = PhotoLocalDataSource(database);

    await _insertFilmRoll(database, 'roll-1');
    await _insertFilmRoll(database, 'roll-2');
    await _insertFilmRollPlace(database, id: 'place-1', filmRollId: 'roll-1');
    await _insertFilmRollPlace(database, id: 'place-2', filmRollId: 'roll-2');
  });

  tearDown(() async {
    await database.close();
  });

  test('findByFilmRoll은 다른 필름롤의 사진을 섞지 않고 촬영순 최신순으로 반환한다', () async {
    final now = DateTime.now();
    await _insertPhoto(
      database,
      id: 'photo-old',
      filmRollId: 'roll-1',
      filmRollPlaceId: 'place-1',
      takenAt: now.subtract(const Duration(hours: 1)),
    );
    await _insertPhoto(
      database,
      id: 'photo-new',
      filmRollId: 'roll-1',
      filmRollPlaceId: 'place-1',
      takenAt: now,
    );
    await _insertPhoto(
      database,
      id: 'photo-other-roll',
      filmRollId: 'roll-2',
      filmRollPlaceId: 'place-2',
      takenAt: now,
    );

    final result = await dataSource.findByFilmRoll('roll-1');

    expect(result.map((p) => p.id), ['photo-new', 'photo-old']);
  });

  test('limit을 지정하면 최신 사진만 반환한다', () async {
    final now = DateTime.now();
    await _insertPhoto(
      database,
      id: 'photo-1',
      filmRollId: 'roll-1',
      filmRollPlaceId: 'place-1',
      takenAt: now.subtract(const Duration(minutes: 2)),
    );
    await _insertPhoto(
      database,
      id: 'photo-2',
      filmRollId: 'roll-1',
      filmRollPlaceId: 'place-1',
      takenAt: now.subtract(const Duration(minutes: 1)),
    );
    await _insertPhoto(
      database,
      id: 'photo-3',
      filmRollId: 'roll-1',
      filmRollPlaceId: 'place-1',
      takenAt: now,
    );

    final result = await dataSource.findByFilmRoll('roll-1', limit: 2);

    expect(result.map((p) => p.id), ['photo-3', 'photo-2']);
  });

  test('사진이 없는 필름롤은 빈 리스트를 반환한다', () async {
    final result = await dataSource.findByFilmRoll('roll-1');

    expect(result, isEmpty);
  });
}
