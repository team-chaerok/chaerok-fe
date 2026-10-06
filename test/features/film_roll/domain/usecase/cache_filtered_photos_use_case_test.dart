import 'package:chaerok/data/models/film_roll_result_response.dart';
import 'package:chaerok/features/film_roll/domain/repository/photo_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/cache_filtered_photos_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePhotoRepository implements PhotoRepository {
  _FakePhotoRepository({this.filteredPaths = const {}});

  final Map<int, String> filteredPaths;
  final saved = <int, List<int>>{};

  @override
  Future<Map<int, String>> findFilteredPhotoPaths(String filmRollId) async =>
      filteredPaths;

  @override
  Future<void> saveFilteredPhoto({
    required String filmRollId,
    required int serverPhotoId,
    required List<int> bytes,
  }) async {
    saved[serverPhotoId] = bytes;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FilteredPhotoResponse _filteredPhoto(int photoId) {
  return FilteredPhotoResponse(
    photoId: photoId,
    sequence: photoId,
    downloadUrl: 'https://example.com/photo-$photoId.jpg',
    downloadUrlExpiresAt: DateTime(2026, 9, 15, 13),
  );
}

void main() {
  test('아직 보관하지 않은 필터 사진만 내려받아 보관한다', () async {
    final repository = _FakePhotoRepository(
      filteredPaths: {1: '/docs/filtered/1.jpg'},
    );
    final downloadedUrls = <String>[];
    final useCase = CacheFilteredPhotosUseCase(
      repository,
      download: (url) async {
        downloadedUrls.add(url);
        return [1, 2, 3];
      },
    );

    await useCase(
      filmRollId: 'fr-1',
      photos: [_filteredPhoto(1), _filteredPhoto(2)],
    );

    expect(downloadedUrls, ['https://example.com/photo-2.jpg']);
    expect(repository.saved, {
      2: [1, 2, 3],
    });
  });

  test('일부 사진을 받지 못해도 나머지 사진은 계속 보관한다', () async {
    final repository = _FakePhotoRepository();
    final useCase = CacheFilteredPhotosUseCase(
      repository,
      download: (url) async {
        if (url.endsWith('photo-1.jpg')) throw Exception('만료된 URL');
        return [9];
      },
    );

    await useCase(
      filmRollId: 'fr-1',
      photos: [_filteredPhoto(1), _filteredPhoto(2)],
    );

    expect(repository.saved.keys, [2]);
  });

  test('내려받은 내용이 비어 있으면 보관하지 않는다', () async {
    final repository = _FakePhotoRepository();
    final useCase = CacheFilteredPhotosUseCase(
      repository,
      download: (url) async => const [],
    );

    await useCase(filmRollId: 'fr-1', photos: [_filteredPhoto(1)]);

    expect(repository.saved, isEmpty);
  });
}
