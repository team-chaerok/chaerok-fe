import 'package:chaerok/data/models/film_roll_result_response.dart';
import 'package:chaerok/features/film_roll/domain/usecase/watch_film_roll_result_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

FilmRollResultResponse _result(String status) {
  return FilmRollResultResponse(
    filmRollId: 900,
    status: status,
    totalPhotoCount: 12,
    processedPhotoCount: 12,
    filteredPhotos: const [],
  );
}

void main() {
  test('COMPLETED를 받을 때까지 폴링하고 COMPLETED에서 스트림을 닫는다', () async {
    final responses = [
      _result('QUEUED'),
      _result('PROCESSING'),
      _result('COMPLETED'),
    ];
    var callCount = 0;
    final useCase = WatchFilmRollResultUseCase(
      pollInterval: Duration.zero,
      getFilmRollResult: (id) async => responses[callCount++],
    );

    final emitted = await useCase.call(900).toList();

    expect(emitted.map((r) => r.status), ['QUEUED', 'PROCESSING', 'COMPLETED']);
    expect(callCount, 3);
  });

  test('FAILED을 받으면 더 폴링하지 않고 즉시 스트림을 닫는다', () async {
    var callCount = 0;
    final useCase = WatchFilmRollResultUseCase(
      pollInterval: Duration.zero,
      getFilmRollResult: (id) async {
        callCount++;
        return _result('FAILED');
      },
    );

    final emitted = await useCase.call(900).toList();

    expect(emitted.map((r) => r.status), ['FAILED']);
    expect(callCount, 1);
  });

  test('EXPIRED을 받으면 즉시 스트림을 닫는다', () async {
    final useCase = WatchFilmRollResultUseCase(
      pollInterval: Duration.zero,
      getFilmRollResult: (id) async => _result('EXPIRED'),
    );

    final emitted = await useCase.call(900).toList();

    expect(emitted.map((r) => r.status), ['EXPIRED']);
  });
}
