import 'package:chaerok/data/models/film_roll_development_response.dart';
import 'package:chaerok/data/models/film_roll_result_response.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/develop_film_roll_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/watch_film_roll_result_use_case.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_result_screen.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_developing_view.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FilmRoll _filmRoll() {
  final now = DateTime(2026, 9, 15);
  return FilmRoll(
    id: 'fr-1',
    regionCode: RegionCode.gongju,
    regionName: '공주시',
    title: '공주 필름롤',
    status: FilmRollStatus.developing,
    totalPlaceCount: 3,
    visitedPlaceCount: 3,
    createdAt: now,
    updatedAt: now,
    serverFilmRollId: 900,
    developAvailableAt: now.add(const Duration(hours: 1)),
  );
}

FilmRollResultResponse _result(String status) {
  return FilmRollResultResponse(
    filmRollId: 900,
    status: status,
    totalPhotoCount: 12,
    processedPhotoCount: 12,
    filteredPhotos: const [],
    completedAt: status == 'COMPLETED' ? DateTime(2026, 9, 15, 12) : null,
  );
}

class _FakeFilmRollRepository implements FilmRollRepository {
  final markCompletedCalls = <(String, DateTime, String?)>[];

  @override
  Future<void> markCompleted({
    required String clientFilmRollId,
    required DateTime completedAt,
    String? serverStatus,
  }) async {
    markCompletedCalls.add((clientFilmRollId, completedAt, serverStatus));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    '진입 즉시 develop을 호출하고, COMPLETED 수신 시 markCompleted 후 결과 화면으로 이동한다',
    (tester) async {
      final developCalledWithId = <int>[];
      final repo = _FakeFilmRollRepository();
      final responses = [_result('PROCESSING'), _result('COMPLETED')];
      var resultCallCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FilmRollDevelopingView(
              filmRoll: _filmRoll(),
              filmRollRepository: repo,
              developFilmRoll: DevelopFilmRollUseCase(
                developFilmRoll: (id) async {
                  developCalledWithId.add(id);
                  return FilmRollDevelopmentResponse(
                    filmRollId: id,
                    status: 'QUEUED',
                    totalPhotoCount: 12,
                    requestedAt: DateTime(2026, 9, 15, 11),
                  );
                },
              ),
              watchFilmRollResult: WatchFilmRollResultUseCase(
                pollInterval: Duration.zero,
                getFilmRollResult: (id) async => responses[resultCallCount++],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(developCalledWithId, [900]);
      expect(repo.markCompletedCalls, [
        ('fr-1', DateTime(2026, 9, 15, 12), null),
      ]);
      expect(find.byType(FilmRollResultScreen), findsOneWidget);
    },
  );

  testWidgets('FAILED 응답을 받으면 실패 안내를 보여주고 화면 전환하지 않는다', (tester) async {
    final repo = _FakeFilmRollRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FilmRollDevelopingView(
            filmRoll: _filmRoll(),
            filmRollRepository: repo,
            developFilmRoll: DevelopFilmRollUseCase(
              developFilmRoll: (id) async => FilmRollDevelopmentResponse(
                filmRollId: id,
                status: 'QUEUED',
                totalPhotoCount: 12,
                requestedAt: DateTime(2026, 9, 15, 11),
              ),
            ),
            watchFilmRollResult: WatchFilmRollResultUseCase(
              pollInterval: Duration.zero,
              getFilmRollResult: (id) async => FilmRollResultResponse(
                filmRollId: id,
                status: 'FAILED',
                totalPhotoCount: 12,
                processedPhotoCount: 0,
                filteredPhotos: const [],
                failure: const FailureResponse(
                  code: 'RENDER_ERROR',
                  message: '릴스 생성 중 오류가 발생했어요.',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(repo.markCompletedCalls, isEmpty);
    expect(find.byType(FilmRollResultScreen), findsNothing);
    expect(find.text('릴스 생성에 실패했어요'), findsOneWidget);
    expect(find.text('릴스 생성 중 오류가 발생했어요.'), findsOneWidget);
  });
}
