import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/file/local_photo_storage.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/repository/photo_repository_impl.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/usecase/get_film_roll_photo_count_use_case.dart';
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
          takenAt: DateTime.now(),
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('필름롤 전체에서 촬영된 사진 수를 리포지토리를 통해 조회한다', () async {
    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final repository = PhotoRepositoryImpl(
      photoDataSource: PhotoLocalDataSource(database),
      photoStorage: LocalPhotoStorage.instance,
    );
    final useCase = GetFilmRollPhotoCountUseCase(repository);

    await _insertFilmRoll(database, 'roll-1');
    await _insertFilmRollPlace(database, id: 'place-1', filmRollId: 'roll-1');
    await _insertPhoto(
      database,
      id: 'photo-1',
      filmRollId: 'roll-1',
      filmRollPlaceId: 'place-1',
    );
    await _insertPhoto(
      database,
      id: 'photo-2',
      filmRollId: 'roll-1',
      filmRollPlaceId: 'place-1',
    );

    final count = await useCase('roll-1');

    expect(count, 2);

    await database.close();
  });
}
