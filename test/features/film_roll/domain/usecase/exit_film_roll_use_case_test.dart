import 'package:chaerok/data/models/film_roll_exit_response.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_result.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_service.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/exit_film_roll_use_case.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter_test/flutter_test.dart';

FilmRoll _filmRoll({int? serverFilmRollId}) {
  final now = DateTime(2026, 9, 5);
  return FilmRoll(
    id: 'fr-1',
    regionCode: RegionCode.gongju,
    regionName: '공주시',
    title: '공주 필름롤',
    status: FilmRollStatus.inProgress,
    totalPlaceCount: 3,
    visitedPlaceCount: 3,
    createdAt: now,
    updatedAt: now,
    serverFilmRollId: serverFilmRollId,
  );
}

class _FakeFilmRollRepository implements FilmRollRepository {
  _FakeFilmRollRepository(this.filmRoll);

  FilmRoll filmRoll;
  final markDevelopingCalls = <(String, DateTime, String?)>[];
  final markExpiredCalls = <(String, String?)>[];

  @override
  Future<FilmRoll?> findById(String filmRollId) async => filmRoll;

  @override
  Future<void> markDeveloping({
    required String clientFilmRollId,
    required DateTime developAvailableAt,
    String? serverStatus,
  }) async {
    markDevelopingCalls.add((
      clientFilmRollId,
      developAvailableAt,
      serverStatus,
    ));
    filmRoll = filmRoll.copyWith(
      status: FilmRollStatus.developing,
      developAvailableAt: developAvailableAt,
    );
  }

  @override
  Future<void> markExpired({
    required String clientFilmRollId,
    String? serverStatus,
  }) async {
    markExpiredCalls.add((clientFilmRollId, serverStatus));
    filmRoll = filmRoll.copyWith(status: FilmRollStatus.expired);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSyncService implements FilmRollSyncService {
  _FakeSyncService({this.onSync});

  final calls = <String>[];
  final void Function()? onSync;

  @override
  Future<FilmRollSyncResult> syncFilmRoll(
    String clientFilmRollId, {
    bool skipRegionCheck = false,
  }) async {
    calls.add(clientFilmRollId);
    onSync?.call();
    return const FilmRollSyncResult();
  }
}

void main() {
  test('현상 조건 충족(READY_TO_RENDER)이면 developing으로 전환한다', () async {
    final repo = _FakeFilmRollRepository(_filmRoll(serverFilmRollId: 900));
    final developAvailableAt = DateTime(2026, 9, 5, 16);
    final useCase = ExitFilmRollUseCase(
      filmRollRepository: repo,
      syncService: _FakeSyncService(),
      exitFilmRoll: (id) async => FilmRollExitResponse(
        filmRollId: id,
        status: 'READY_TO_RENDER',
        exitedAt: DateTime(2026, 9, 5, 15),
        developAvailableAt: developAvailableAt,
        developAvailable: true,
      ),
    );

    final result = await useCase.call(repo.filmRoll);

    expect(result.isDeveloping, isTrue);
    expect(result.developAvailableAt, developAvailableAt);
    expect(repo.markDevelopingCalls, [
      ('fr-1', developAvailableAt, 'READY_TO_RENDER'),
    ]);
    expect(repo.filmRoll.status, FilmRollStatus.developing);
  });

  test('현상 조건 미충족(EXPIRED)이면 expired로 전환한다', () async {
    final repo = _FakeFilmRollRepository(_filmRoll(serverFilmRollId: 900));
    final useCase = ExitFilmRollUseCase(
      filmRollRepository: repo,
      syncService: _FakeSyncService(),
      exitFilmRoll: (id) async => FilmRollExitResponse(
        filmRollId: id,
        status: 'EXPIRED',
        exitedAt: DateTime(2026, 9, 5, 15),
        developAvailable: false,
      ),
    );

    final result = await useCase.call(repo.filmRoll);

    expect(result.isDeveloping, isFalse);
    expect(repo.markExpiredCalls, [('fr-1', 'EXPIRED')]);
    expect(repo.filmRoll.status, FilmRollStatus.expired);
  });

  test('developAvailableAt이 응답에 없으면 exitedAt + 1시간으로 대체한다', () async {
    final repo = _FakeFilmRollRepository(_filmRoll(serverFilmRollId: 900));
    final exitedAt = DateTime(2026, 9, 5, 15);
    final useCase = ExitFilmRollUseCase(
      filmRollRepository: repo,
      syncService: _FakeSyncService(),
      exitFilmRoll: (id) async => FilmRollExitResponse(
        filmRollId: id,
        status: 'READY_TO_RENDER',
        exitedAt: exitedAt,
        developAvailable: true,
      ),
    );

    final result = await useCase.call(repo.filmRoll);

    expect(result.developAvailableAt, exitedAt.add(const Duration(hours: 1)));
  });

  test('serverFilmRollId가 없으면 skipRegionCheck로 동기화를 시도해 확보한다', () async {
    final repo = _FakeFilmRollRepository(_filmRoll());
    final sync = _FakeSyncService(
      onSync: () =>
          repo.filmRoll = repo.filmRoll.copyWith(serverFilmRollId: 900),
    );
    final calledWithId = <int>[];
    final useCase = ExitFilmRollUseCase(
      filmRollRepository: repo,
      syncService: sync,
      exitFilmRoll: (id) async {
        calledWithId.add(id);
        return FilmRollExitResponse(
          filmRollId: id,
          status: 'READY_TO_RENDER',
          exitedAt: DateTime(2026, 9, 5, 15),
          developAvailableAt: DateTime(2026, 9, 5, 16),
          developAvailable: true,
        );
      },
    );

    final result = await useCase.call(repo.filmRoll);

    expect(sync.calls, ['fr-1']);
    expect(calledWithId, [900]);
    expect(result.isDeveloping, isTrue);
  });

  test('동기화 후에도 serverFilmRollId가 없으면 ExitNotSyncedException을 던진다', () async {
    final repo = _FakeFilmRollRepository(_filmRoll());
    final useCase = ExitFilmRollUseCase(
      filmRollRepository: repo,
      syncService: _FakeSyncService(), // onSync 없음 — serverFilmRollId 계속 null
      exitFilmRoll: (_) async => throw StateError('호출되면 안 됨'),
    );

    await expectLater(
      useCase.call(repo.filmRoll),
      throwsA(isA<ExitNotSyncedException>()),
    );
  });
}
