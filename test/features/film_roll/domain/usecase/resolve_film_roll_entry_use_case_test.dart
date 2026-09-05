import 'dart:io';

import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/file/local_photo_storage.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_place_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_repository_impl.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_result.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_service.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/usecase/enter_region_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/recover_last_active_film_roll_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/resolve_film_roll_entry_use_case.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
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
  @override
  Future<FilmRollSyncResult> syncFilmRoll(
    String clientFilmRollId, {
    bool skipRegionCheck = false,
  }) async => const FilmRollSyncResult();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase database;
  late FilmRollRepositoryImpl repository;
  late AppPreferences preferences;
  late ResolveFilmRollEntryUseCase useCase;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'current_user_id': 1});
    tempDir = await Directory.systemTemp.createTemp('resolve_entry_test');
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);

    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = FilmRollRepositoryImpl(
      database: database,
      filmRollDataSource: FilmRollLocalDataSource(database),
      placeDataSource: FilmRollPlaceLocalDataSource(database),
      photoDataSource: PhotoLocalDataSource(database),
      photoStorage: LocalPhotoStorage.instance,
    );
    preferences = AppPreferences.instance;

    useCase = ResolveFilmRollEntryUseCase(
      recoverLastActiveFilmRoll: RecoverLastActiveFilmRollUseCase(
        filmRollRepository: repository,
        appPreferences: preferences,
      ),
      enterRegion: EnterRegionUseCase(
        filmRollRepository: repository,
        syncService: _FakeSyncService(),
        appPreferences: preferences,
      ),
    );
  });

  tearDown(() async {
    await database.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> insertFilmRoll({
    required String id,
    required FilmRollStatus status,
    String? selectedCourseId,
  }) async {
    final now = DateTime(2026, 8, 30);
    await database
        .into(database.filmRolls)
        .insert(
          FilmRollsCompanion.insert(
            id: id,
            userId: const Value(1),
            regionCode: RegionCode.gongju,
            regionName: '공주시',
            title: '공주',
            status: status,
            createdAt: now,
            updatedAt: now,
            selectedCourseId: Value(selectedCourseId),
          ),
        );
    await preferences.setLastActiveFilmRollId(id);
  }

  test('활성 필름롤이 없으면 새로 진입해 코스 선택이 필요하다고 판정한다', () async {
    final decision = await useCase('공주시', regionId: 11);

    expect(decision.action, FilmRollEntryAction.needsCourseSelection);
    expect(decision.filmRoll.selectedCourseId, isNull);
    expect(await preferences.getLastActiveFilmRollId(), decision.filmRoll.id);
  });

  test('지원하지 않는 지역이고 활성 필름롤이 없으면 예외가 그대로 전파된다', () async {
    await expectLater(
      useCase('서울특별시', regionId: 1),
      throwsA(isA<UnsupportedRegionException>()),
    );
  });

  test('진행중이며 코스 미선택인 활성 필름롤이 있으면 새로 진입하지 않고 코스 선택이 필요하다고 판정한다', () async {
    await insertFilmRoll(
      id: 'roll-existing',
      status: FilmRollStatus.inProgress,
    );

    // 실제로 호출되면 다른 지역 필름롤이 생성/조회될 상황을 일부러 전달해,
    // enterRegion이 호출되지 않고 기존 활성 필름롤이 그대로 반환됨을 검증한다.
    final decision = await useCase('서산시', regionId: 22);

    expect(decision.action, FilmRollEntryAction.needsCourseSelection);
    expect(decision.filmRoll.id, 'roll-existing');
  });

  test('진행중이며 코스 선택이 완료된 활성 필름롤이 있으면 진행 재개로 판정한다', () async {
    await insertFilmRoll(
      id: 'roll-with-course',
      status: FilmRollStatus.inProgress,
      selectedCourseId: 'course-1',
    );

    final decision = await useCase('공주시', regionId: 11);

    expect(decision.action, FilmRollEntryAction.resumeInProgress);
    expect(decision.filmRoll.id, 'roll-with-course');
  });

  test('현상 대기 상태의 활성 필름롤은 코스 선택 여부와 무관하게 현상 대기로 판정한다', () async {
    await insertFilmRoll(
      id: 'roll-developing',
      status: FilmRollStatus.developing,
      selectedCourseId: 'course-1',
    );

    final decision = await useCase('공주시', regionId: 11);

    expect(decision.action, FilmRollEntryAction.showDeveloping);
    expect(decision.filmRoll.id, 'roll-developing');
  });
}
