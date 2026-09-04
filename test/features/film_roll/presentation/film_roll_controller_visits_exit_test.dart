import 'dart:io';

import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/file/local_photo_storage.dart';
import 'package:chaerok/data/models/film_roll_exit_response.dart';
import 'package:chaerok/data/models/visit_item_response.dart';
import 'package:chaerok/data/models/visit_list_response.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_place_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_place_repository_impl.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_repository_impl.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_result.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_service.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/usecase/exit_film_roll_use_case.dart';
import 'package:chaerok/features/film_roll/presentation/controller/film_roll_controller.dart';
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

class _NoopSyncService implements FilmRollSyncService {
  @override
  Future<FilmRollSyncResult> syncFilmRoll(
    String clientFilmRollId, {
    bool skipRegionCheck = false,
  }) async => const FilmRollSyncResult();
}

VisitListResponse _visitList({
  required int filmRollId,
  int visitedCategoryCount = 3,
  int requiredCategoryCount = 3,
  bool visitRequirementMet = true,
}) {
  return VisitListResponse(
    filmRollId: filmRollId,
    visitedCategoryCount: visitedCategoryCount,
    requiredCategoryCount: requiredCategoryCount,
    visitRequirementMet: visitRequirementMet,
    visits: const <VisitItemResponse>[],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase database;
  late FilmRollRepositoryImpl repository;
  late FilmRollPlaceRepositoryImpl placeRepository;
  late String seededId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'current_user_id': 1});
    tempDir = await Directory.systemTemp.createTemp(
      'film_roll_controller_visits_exit',
    );
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
    final fr = await repository.findOrCreateActiveByRegion(
      regionCode: RegionCode.gongju,
      regionName: '공주시',
      regionId: 11,
    );
    seededId = fr.id;
  });

  tearDown(() async {
    await database.close();
    await tempDir.delete(recursive: true);
  });

  FilmRollController controller({
    Future<VisitListResponse> Function(int filmRollId)? getVisits,
    ExitFilmRollUseCase? exitFilmRollUseCase,
  }) => FilmRollController(
    filmRollId: seededId,
    onStateChanged: (_) {},
    filmRollRepository: repository,
    filmRollPlaceRepository: placeRepository,
    syncService: _NoopSyncService(),
    getVisits: getVisits,
    exitFilmRollUseCase: exitFilmRollUseCase,
  );

  test('서버 필름롤이 아직 없으면 loadVisits는 아무것도 하지 않는다', () async {
    var calls = 0;
    final c = controller(
      getVisits: (id) async {
        calls++;
        return _visitList(filmRollId: id);
      },
    );

    await c.load();
    await Future<void>.delayed(Duration.zero);

    expect(calls, 0);
    expect(c.state.filmRoll!.visitRequirementMet, isNull);
  });

  test('서버 필름롤이 있으면 load() 이후 방문 현황이 필름롤에 반영된다', () async {
    await repository.linkServerFilmRoll(
      clientFilmRollId: seededId,
      serverFilmRollId: 900,
    );
    final c = controller(
      getVisits: (id) async => _visitList(
        filmRollId: id,
        visitedCategoryCount: 2,
        requiredCategoryCount: 3,
        visitRequirementMet: false,
      ),
    );

    await c.load();
    await Future<void>.delayed(Duration.zero);

    final filmRoll = c.state.filmRoll!;
    expect(filmRoll.visitRequirementMet, isFalse);
    expect(filmRoll.visitedCategoryCount, 2);
    expect(filmRoll.requiredCategoryCount, 3);
    expect(c.state.isLoadingVisits, isFalse);
    expect(c.state.visitsLoadFailed, isFalse);
  });

  test('방문 현황 조회가 실패하면 visitsLoadFailed가 true가 된다', () async {
    await repository.linkServerFilmRoll(
      clientFilmRollId: seededId,
      serverFilmRollId: 900,
    );
    final c = controller(getVisits: (_) async => throw StateError('boom'));

    await c.load();
    await Future<void>.delayed(Duration.zero);

    expect(c.state.visitsLoadFailed, isTrue);
    expect(c.state.isLoadingVisits, isFalse);
  });

  test('exitFilmRoll은 유스케이스를 호출하고 최신 상태를 다시 불러온다', () async {
    await repository.linkServerFilmRoll(
      clientFilmRollId: seededId,
      serverFilmRollId: 900,
    );
    final developAvailableAt = DateTime(2026, 9, 5, 16);
    final exitUseCase = ExitFilmRollUseCase(
      filmRollRepository: repository,
      syncService: _NoopSyncService(),
      exitFilmRoll: (id) async {
        await repository.markDeveloping(
          clientFilmRollId: seededId,
          developAvailableAt: developAvailableAt,
          serverStatus: 'READY_TO_RENDER',
        );
        return FilmRollExitResponse(
          filmRollId: id,
          status: 'READY_TO_RENDER',
          exitedAt: DateTime(2026, 9, 5, 15),
          developAvailableAt: developAvailableAt,
          developAvailable: true,
        );
      },
    );
    final c = controller(exitFilmRollUseCase: exitUseCase);
    await c.load();
    await Future<void>.delayed(Duration.zero);

    final result = await c.exitFilmRoll();

    expect(result.isDeveloping, isTrue);
    expect(c.state.filmRoll!.status, FilmRollStatus.developing);
  });

  test('필름롤이 로드되지 않은 상태에서 exitFilmRoll을 호출하면 StateError를 던진다', () async {
    final c = FilmRollController(
      filmRollId: 'not-loaded-yet',
      onStateChanged: (_) {},
      filmRollRepository: repository,
      filmRollPlaceRepository: placeRepository,
      syncService: _NoopSyncService(),
    );

    await expectLater(c.exitFilmRoll(), throwsA(isA<StateError>()));
  });
}
