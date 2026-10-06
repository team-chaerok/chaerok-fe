import 'package:chaerok/data/models/film_roll_result_response.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_photo.dart';
import 'package:chaerok/features/film_roll/domain/repository/photo_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/get_film_roll_result_photos_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePhotoRepository implements PhotoRepository {
  _FakePhotoRepository({
    this.filteredPaths = const {},
    this.localPhotos = const [],
  });

  final Map<int, String> filteredPaths;
  final List<FilmRollPhoto> localPhotos;

  @override
  Future<Map<int, String>> findFilteredPhotoPaths(String filmRollId) async =>
      filteredPaths;

  @override
  Future<List<FilmRollPhoto>> findByFilmRoll(
    String filmRollId, {
    int? limit,
  }) async => localPhotos;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FilmRollPhoto _localPhoto(int sequence, {int? serverPhotoId}) {
  return FilmRollPhoto(
    id: 'ph-$sequence',
    filmRollId: 'fr-1',
    filmRollPlaceId: 'p-1',
    originalPath: '/docs/original/ph-$sequence.jpg',
    thumbnailPath: '/docs/thumbnail/ph-$sequence.jpg',
    takenAt: DateTime(2026, 9, 15, 10, sequence),
    sequence: sequence,
    serverPhotoId: serverPhotoId,
    isSynced: serverPhotoId != null,
  );
}

FilteredPhotoResponse _filteredPhoto(int photoId, int sequence) {
  return FilteredPhotoResponse(
    photoId: photoId,
    sequence: sequence,
    downloadUrl: 'https://example.com/photo-$photoId.jpg',
    downloadUrlExpiresAt: DateTime(2026, 9, 15, 13),
  );
}

FilmRollResultResponse _result(
  String status, {
  List<FilteredPhotoResponse> filteredPhotos = const [],
}) {
  return FilmRollResultResponse(
    filmRollId: 900,
    status: status,
    totalPhotoCount: 3,
    processedPhotoCount: 3,
    filteredPhotos: filteredPhotos,
    completedAt: DateTime(2026, 9, 15, 12),
  );
}

void main() {
  test('보관 기간 안이면 서버 필터 사진을 촬영 순서대로 주고, 보관본이 있는 사진은 기기 경로를 함께 준다', () async {
    final useCase = GetFilmRollResultPhotosUseCase(
      _FakePhotoRepository(filteredPaths: {101: '/docs/filtered/101.jpg'}),
    );

    final photos = await useCase(
      filmRollId: 'fr-1',
      result: _result(
        'COMPLETED',
        filteredPhotos: [_filteredPhoto(102, 2), _filteredPhoto(101, 1)],
      ),
    );

    expect(photos.map((p) => p.sequence), [1, 2]);
    expect(photos[0].localPath, '/docs/filtered/101.jpg');
    expect(photos[0].remoteUrl, 'https://example.com/photo-101.jpg');
    expect(photos[1].localPath, isNull);
    expect(photos[1].remoteUrl, 'https://example.com/photo-102.jpg');
    expect(photos.every((p) => p.isFiltered), isTrue);
  });

  test('보관 기간이 지나면 기기에 보관한 필터 사진을 주고, 보관본이 없는 사진은 촬영 원본으로 대체한다', () async {
    final useCase = GetFilmRollResultPhotosUseCase(
      _FakePhotoRepository(
        filteredPaths: {101: '/docs/filtered/101.jpg'},
        localPhotos: [
          _localPhoto(3),
          _localPhoto(2, serverPhotoId: 102),
          _localPhoto(1, serverPhotoId: 101),
        ],
      ),
    );

    final photos = await useCase(
      filmRollId: 'fr-1',
      result: _result('EXPIRED'),
    );

    expect(photos.map((p) => p.sequence), [1, 2, 3]);
    expect(photos[0].localPath, '/docs/filtered/101.jpg');
    expect(photos[0].isFiltered, isTrue);
    // 서버에 올라갔지만 보관본을 받지 못한 사진.
    expect(photos[1].localPath, '/docs/original/ph-2.jpg');
    expect(photos[1].isFiltered, isFalse);
    // 서버에 올라간 적이 없는 사진.
    expect(photos[2].localPath, '/docs/original/ph-3.jpg');
    expect(photos[2].isFiltered, isFalse);
    expect(photos.every((p) => p.remoteUrl == null), isTrue);
  });

  test('fromServer()는 기기 조회 없이 서버 사진만으로 촬영 순서 목록을 만든다', () {
    final photos = GetFilmRollResultPhotosUseCase.fromServer(
      _result(
        'COMPLETED',
        filteredPhotos: [_filteredPhoto(102, 2), _filteredPhoto(101, 1)],
      ),
    );

    expect(photos.map((p) => p.remoteUrl), [
      'https://example.com/photo-101.jpg',
      'https://example.com/photo-102.jpg',
    ]);
    expect(photos.every((p) => p.localPath == null), isTrue);
  });
}
