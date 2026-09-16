import 'package:chaerok/data/models/film_roll_development_response.dart';
import 'package:chaerok/features/film_roll/domain/usecase/develop_film_roll_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('서버 필름롤 ID로 현상을 요청하고 응답을 그대로 반환한다', () async {
    final calledWithId = <int>[];
    final useCase = DevelopFilmRollUseCase(
      developFilmRoll: (id) async {
        calledWithId.add(id);
        return FilmRollDevelopmentResponse(
          filmRollId: id,
          status: 'QUEUED',
          totalPhotoCount: 12,
          requestedAt: DateTime(2026, 9, 15, 10),
        );
      },
    );

    final result = await useCase.call(900);

    expect(calledWithId, [900]);
    expect(result.status, 'QUEUED');
    expect(result.totalPhotoCount, 12);
  });

  test('API 호출이 실패하면 예외를 그대로 전파한다', () async {
    final useCase = DevelopFilmRollUseCase(
      developFilmRoll: (_) async => throw StateError('네트워크 오류'),
    );

    await expectLater(useCase.call(900), throwsA(isA<StateError>()));
  });
}
