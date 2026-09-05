import 'dart:io';
import 'dart:typed_data';

import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/file/local_photo_storage.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/repository/photo_repository_impl.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.dir);
  final Directory dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;
  late AppDatabase database;
  late PhotoRepositoryImpl repository;
  final bytes = Uint8List.fromList(List.filled(32, 7));

  const filmRollId = 'fr1';
  const placeId = 'p1';

  setUp(() async {
    documentsDir = await Directory.systemTemp.createTemp('photo_repository');
    PathProviderPlatform.instance = _FakePathProviderPlatform(documentsDir);
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = PhotoRepositoryImpl(
      photoDataSource: PhotoLocalDataSource(database),
      photoStorage: LocalPhotoStorage.instance,
    );

    await database
        .into(database.filmRolls)
        .insert(
          FilmRollsCompanion.insert(
            id: filmRollId,
            regionCode: RegionCode.gongju,
            regionName: '공주시',
            title: '공주 필름롤',
            status: FilmRollStatus.inProgress,
            createdAt: DateTime(2026, 9, 5),
            updatedAt: DateTime(2026, 9, 5),
          ),
        );
    await database
        .into(database.filmRollPlaces)
        .insert(
          FilmRollPlacesCompanion.insert(
            id: placeId,
            filmRollId: filmRollId,
            name: '장소1',
            address: '주소1',
            category: '카테고리',
            latitude: 36.0,
            longitude: 126.0,
            visitOrder: 0,
          ),
        );
  });

  tearDown(() async {
    await database.close();
    await documentsDir.delete(recursive: true);
  });

  Future<void> savePhoto() => repository.savePhoto(
    filmRollId: filmRollId,
    filmRollPlaceId: placeId,
    imageBytes: bytes,
  );

  test('savePhoto()는 DB에 상대 경로만 저장한다', () async {
    await savePhoto();

    final row = await database.select(database.photos).getSingle();
    expect(p.isAbsolute(row.originalPath), isFalse);
    expect(p.isAbsolute(row.thumbnailPath), isFalse);
    expect(row.originalPath, startsWith('film_rolls/'));
    expect(row.thumbnailPath, startsWith('film_rolls/'));
  });

  test('savePhoto()가 반환한 엔티티는 실제 파일을 가리키는 절대 경로를 갖는다', () async {
    final photo = await repository.savePhoto(
      filmRollId: filmRollId,
      filmRollPlaceId: placeId,
      imageBytes: bytes,
    );

    expect(p.isWithin(documentsDir.path, photo.originalPath), isTrue);
    expect(File(photo.originalPath).existsSync(), isTrue);
    expect(File(photo.thumbnailPath).existsSync(), isTrue);
  });

  test('findByFilmRoll()/findByPlace()는 절대 경로로 복원된 엔티티를 돌려준다', () async {
    await savePhoto();

    final byFilmRoll = await repository.findByFilmRoll(filmRollId);
    final byPlace = await repository.findByPlace(placeId);

    expect(byFilmRoll, hasLength(1));
    expect(byPlace, hasLength(1));
    for (final photo in [byFilmRoll.single, byPlace.single]) {
      expect(p.isAbsolute(photo.thumbnailPath), isTrue);
      expect(File(photo.thumbnailPath).existsSync(), isTrue);
    }
  });

  test('deletePhoto()는 DB 행과 파일을 함께 제거한다', () async {
    await savePhoto();
    final saved = (await repository.findByFilmRoll(filmRollId)).single;

    await repository.deletePhoto(saved.id);

    expect(await database.select(database.photos).get(), isEmpty);
    expect(File(saved.originalPath).existsSync(), isFalse);
    expect(File(saved.thumbnailPath).existsSync(), isFalse);
  });
}
