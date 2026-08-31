import 'dart:io';

import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/file/local_photo_storage.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_place_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_place_repository_impl.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_repository_impl.dart';
import 'package:chaerok/features/film_roll/domain/entity/course_candidate_place.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.dir);
  final Directory dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase database;
  late FilmRollRepositoryImpl repository;
  late FilmRollPlaceRepositoryImpl placeRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'current_user_id': 1});
    tempDir = await Directory.systemTemp.createTemp('film_roll_sync_support');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FilmRollRepositoryImpl(
      database: database,
      filmRollDataSource: FilmRollLocalDataSource(database),
      placeDataSource: FilmRollPlaceLocalDataSource(database),
      photoDataSource: PhotoLocalDataSource(database),
      photoStorage: LocalPhotoStorage.instance,
    );
    placeRepository = FilmRollPlaceRepositoryImpl(
      placeDataSource: FilmRollPlaceLocalDataSource(database),
      photoDataSource: PhotoLocalDataSource(database),
    );
  });

  tearDown(() async {
    await database.close();
    await tempDir.delete(recursive: true);
  });

  test('신규 생성 시 regionId를 저장한다', () async {
    final filmRoll = await repository.findOrCreateActiveByRegion(
      regionCode: RegionCode.seosan,
      regionName: '서산시',
      regionId: 33,
    );
    expect(filmRoll.regionId, 33);
  });

  test('linkServerFilmRoll이 serverFilmRollId/status/filter를 저장한다', () async {
    final fr = await repository.findOrCreateActiveByRegion(
      regionCode: RegionCode.gongju,
      regionName: '공주시',
      regionId: 11,
    );

    await repository.linkServerFilmRoll(
      clientFilmRollId: fr.id,
      serverFilmRollId: 900,
      serverStatus: 'CAPTURING',
      filterId: 'f1',
      filterStrength: 1.0,
    );

    final updated = await repository.findById(fr.id);
    expect(updated!.serverFilmRollId, 900);
    expect(updated.serverStatus, 'CAPTURING');
    expect(updated.regionId, 11);
  });

  test('updateServerStatus가 status만 갱신한다', () async {
    final fr = await repository.findOrCreateActiveByRegion(
      regionCode: RegionCode.gongju,
      regionName: '공주시',
      regionId: 11,
    );
    await repository.linkServerFilmRoll(
      clientFilmRollId: fr.id,
      serverFilmRollId: 900,
      serverStatus: 'CAPTURING',
    );

    await repository.updateServerStatus(
      clientFilmRollId: fr.id,
      serverStatus: 'READY',
    );

    expect((await repository.findById(fr.id))!.serverStatus, 'READY');
  });

  test('findUnsyncedVisitedPlaces는 방문했고 미동기화인 장소만 반환한다', () async {
    final fr = await repository.findOrCreateActiveByRegion(
      regionCode: RegionCode.buyeo,
      regionName: '부여군',
      regionId: 22,
    );
    await repository.selectCourse(
      filmRollId: fr.id,
      courseId: 'c1',
      courseTitle: '코스',
      places: const [
        CourseCandidatePlace(
          name: 'A',
          address: 'a',
          category: 'cat',
          latitude: 36,
          longitude: 126,
          visitOrder: 0,
          serverPlaceId: 1,
        ),
        CourseCandidatePlace(
          name: 'B',
          address: 'b',
          category: 'cat',
          latitude: 36,
          longitude: 126,
          visitOrder: 1,
          serverPlaceId: 2,
        ),
        CourseCandidatePlace(
          name: 'C',
          address: 'c',
          category: 'cat',
          latitude: 36,
          longitude: 126,
          visitOrder: 2,
          serverPlaceId: 3,
        ),
      ],
    );
    final places = await placeRepository.findByFilmRoll(fr.id);
    final a = places.firstWhere((p) => p.name == 'A');
    final b = places.firstWhere((p) => p.name == 'B');

    // A: 방문 + 동기화됨,  B: 방문 + 미동기화,  C: 미방문
    await placeRepository.markVisited(a.id);
    await placeRepository.markVisited(b.id);
    await placeRepository.markVisitSynced(a.id, at: DateTime(2026, 8, 30));

    final pending = await placeRepository.findUnsyncedVisitedPlaces(fr.id);
    expect(pending.map((p) => p.name), ['B']);
  });
}
