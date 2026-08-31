import 'dart:async';
import 'dart:io';

import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/file/local_photo_storage.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_place_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_place_repository_impl.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_repository_impl.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_result.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_service.dart';
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

class _FakeSyncService implements FilmRollSyncService {
  int calls = 0;
  FilmRollSyncResult next = const FilmRollSyncResult();

  /// null이 아니면 syncFilmRoll이 이 completer가 완료될 때까지 대기한다.
  Completer<void>? gate;

  @override
  Future<FilmRollSyncResult> syncFilmRoll(String clientFilmRollId) async {
    calls++;
    if (gate != null) await gate!.future;
    return next;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase database;
  late FilmRollRepositoryImpl repository;
  late FilmRollPlaceRepositoryImpl placeRepository;
  late _FakeSyncService sync;
  late String seededId;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'current_user_id': 1});
    tempDir = await Directory.systemTemp.createTemp(
      'film_roll_controller_sync',
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
    sync = _FakeSyncService();
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

  FilmRollController controller() => FilmRollController(
    filmRollId: seededId,
    onStateChanged: (_) {},
    filmRollRepository: repository,
    filmRollPlaceRepository: placeRepository,
    syncService: sync,
  );

  test('load()가 끝나면 syncFilmRoll을 fire-and-forget 호출한다', () async {
    final c = controller();
    await c.load();
    await Future<void>.delayed(Duration.zero);
    expect(sync.calls, 1);
  });

  test('retrySync는 결과의 hasError를 state.lastSyncHadError에 반영한다', () async {
    final c = controller();
    await c.load();
    await Future<void>.delayed(Duration.zero);

    sync.next = const FilmRollSyncResult(error: 'boom');
    final result = await c.retrySync();

    expect(result.hasError, isTrue);
    expect(c.state.lastSyncHadError, isTrue);
  });

  test('retrySync 성공 시 lastSyncHadError는 false', () async {
    final c = controller();
    await c.load();
    await Future<void>.delayed(Duration.zero);

    sync.next = const FilmRollSyncResult(created: true);
    await c.retrySync();

    expect(c.state.lastSyncHadError, isFalse);
  });

  test('retrySync는 syncFilmRoll을 한 번만 호출한다(load 재트리거 없음)', () async {
    final c = controller();
    await c.load();
    await Future<void>.delayed(Duration.zero);
    expect(sync.calls, 1);

    await c.retrySync();
    await Future<void>.delayed(Duration.zero);

    expect(sync.calls, 2); // load 1회 + retrySync 1회. retrySync 내부에서 추가 트리거 없음.
  });

  test('동기화 진행 중 retrySync는 새 syncFilmRoll을 시작하지 않고 진행 중인 것을 공유한다', () async {
    sync.gate = Completer<void>();
    final c = controller();

    await c
        .load(); // _reload는 await, _triggerSync는 fire-and-forget으로 sync #1 시작(계류)
    expect(sync.calls, 1);

    final retryFut = c.retrySync(); // 계류 중인 #1을 공유 — 새로 시작하지 않음
    await Future<void>.delayed(Duration.zero);
    expect(sync.calls, 1);

    sync.gate!.complete(); // #1 완료
    await retryFut;
    expect(sync.calls, 1);

    // 완료 후에는 _inFlightSync가 비워져 다음 트리거가 새 동기화를 시작한다.
    sync.gate = null;
    await c.retrySync();
    expect(sync.calls, 2);
  });
}
