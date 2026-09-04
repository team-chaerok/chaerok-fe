import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_result.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_service.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/enter_region_use_case.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSyncService implements FilmRollSyncService {
  final calls = <String>[];

  @override
  Future<FilmRollSyncResult> syncFilmRoll(
    String clientFilmRollId, {
    bool skipRegionCheck = false,
  }) async {
    calls.add(clientFilmRollId);
    return const FilmRollSyncResult();
  }
}

class _StubFilmRollRepository implements FilmRollRepository {
  FilmRoll? created;

  @override
  Future<FilmRoll> findOrCreateActiveByRegion({
    required RegionCode regionCode,
    required String regionName,
    required int regionId,
  }) async {
    final now = DateTime(2026, 8, 30);
    return created = FilmRoll(
      id: 'fr-1',
      regionCode: regionCode,
      regionName: regionName,
      title: '필름롤',
      status: FilmRollStatus.inProgress,
      totalPlaceCount: 0,
      visitedPlaceCount: 0,
      createdAt: now,
      updatedAt: now,
      regionId: regionId,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('지역 진입 성공 후 syncFilmRoll을 호출한다', () async {
    final sync = _FakeSyncService();
    final useCase = EnterRegionUseCase(
      filmRollRepository: _StubFilmRollRepository(),
      syncService: sync,
      appPreferences: AppPreferences.instance,
    );

    await useCase('공주시', regionId: 11);
    await Future<void>.delayed(Duration.zero);

    expect(sync.calls, ['fr-1']);
  });

  test('지원하지 않는 지역이면 예외를 던지고 sync를 호출하지 않는다', () async {
    final sync = _FakeSyncService();
    final useCase = EnterRegionUseCase(
      filmRollRepository: _StubFilmRollRepository(),
      syncService: sync,
      appPreferences: AppPreferences.instance,
    );

    await expectLater(
      useCase('서울특별시', regionId: 1),
      throwsA(isA<UnsupportedRegionException>()),
    );
    expect(sync.calls, isEmpty);
  });
}
