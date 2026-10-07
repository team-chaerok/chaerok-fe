import 'package:chaerok/data/models/film_roll_result_response.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_photo.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_place_repository.dart';
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

class _FakePlaceRepository implements FilmRollPlaceRepository {
  _FakePlaceRepository(this.places);

  final List<FilmRollPlace> places;

  @override
  Future<List<FilmRollPlace>> findByFilmRoll(String filmRollId) async => places;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FilmRollPlace _place(String id, String name) {
  return FilmRollPlace(
    id: id,
    filmRollId: 'fr-1',
    name: name,
    address: '충남 공주시',
    category: '관광지',
    latitude: 36.46,
    longitude: 127.12,
    visitOrder: 1,
    isVisited: true,
    photoCount: 1,
  );
}

FilmRollPhoto _localPhoto(
  int sequence, {
  int? serverPhotoId,
  String placeId = 'p-1',
}) {
  return FilmRollPhoto(
    id: 'ph-$sequence',
    filmRollId: 'fr-1',
    filmRollPlaceId: placeId,
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

  test('보관 기간 안이면 기기 촬영 기록과 서버 사진 id로 맞춰 사진마다 촬영 장소를 담는다', () async {
    final useCase = GetFilmRollResultPhotosUseCase(
      _FakePhotoRepository(
        localPhotos: [
          _localPhoto(1, serverPhotoId: 101, placeId: 'p-1'),
          _localPhoto(2, serverPhotoId: 102, placeId: 'p-2'),
        ],
      ),
      placeRepository: _FakePlaceRepository([
        _place('p-1', '공산성'),
        _place('p-2', '제민천'),
      ]),
    );

    final photos = await useCase(
      filmRollId: 'fr-1',
      result: _result(
        'COMPLETED',
        filteredPhotos: [
          _filteredPhoto(101, 1),
          _filteredPhoto(102, 2),
          _filteredPhoto(103, 3),
        ],
      ),
    );

    expect(photos.map((p) => p.filmRollPlaceId), ['p-1', 'p-2', null]);
    expect(photos.map((p) => p.placeName), ['공산성', '제민천', null]);
  });

  test('pickPlaceRepresentatives()는 장소마다 처음 찍은 사진을 한 장씩 최대 3장 고른다', () {
    FilmRollResultPhoto photo(int sequence, String? placeId) =>
        FilmRollResultPhoto(
          sequence: sequence,
          remoteUrl: 'https://example.com/$sequence.jpg',
          filmRollPlaceId: placeId,
        );

    final picked = GetFilmRollResultPhotosUseCase.pickPlaceRepresentatives([
      photo(1, 'p-1'),
      photo(2, 'p-1'),
      photo(3, 'p-2'),
      photo(4, 'p-3'),
      photo(5, 'p-4'),
    ]);
    expect(picked.map((p) => p.sequence), [1, 3, 4]);

    // 장소를 모르면 각각 다른 장소로 보아 앞에서부터 고른다.
    final unknown = GetFilmRollResultPhotosUseCase.pickPlaceRepresentatives([
      photo(1, null),
      photo(2, null),
      photo(3, null),
      photo(4, null),
    ]);
    expect(unknown.map((p) => p.sequence), [1, 2, 3]);
  });
}
