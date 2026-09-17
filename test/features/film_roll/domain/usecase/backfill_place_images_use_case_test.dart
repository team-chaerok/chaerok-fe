import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_place_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/backfill_place_images_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

class _StubFilmRollPlaceRepository implements FilmRollPlaceRepository {
  _StubFilmRollPlaceRepository(this.places);

  final List<FilmRollPlace> places;
  final Map<String, String> updatedImageUrls = {};

  @override
  Future<List<FilmRollPlace>> findByFilmRoll(String filmRollId) async => places;

  @override
  Future<void> updateImageUrl(String filmRollPlaceId, String imageUrl) async {
    updatedImageUrls[filmRollPlaceId] = imageUrl;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FilmRollPlace _place({
  required String id,
  int? serverPlaceId,
  String? externalPlaceId,
  String? imageUrl,
  String name = '',
}) => FilmRollPlace(
  id: id,
  filmRollId: 'fr-1',
  name: name.isEmpty ? '장소 $id' : name,
  address: '충남 어딘가',
  category: 'HERITAGE',
  latitude: 36.5,
  longitude: 127.1,
  visitOrder: 0,
  isVisited: false,
  photoCount: 0,
  serverPlaceId: serverPlaceId,
  externalPlaceId: externalPlaceId,
  imageUrl: imageUrl,
);

/// 대부분의 테스트는 카카오 이미지 검색 폴백까지 도달시키고 싶지 않으므로,
/// 기본값은 항상 null(검색 결과 없음)을 반환하는 no-op으로 둔다.
Future<String?> _noKakaoFallback(String placeName) async => null;

void main() {
  test('serverPlaceId가 있고 이미지가 없는 장소만 보충한다', () async {
    final repository = _StubFilmRollPlaceRepository([
      _place(id: 'p1', serverPlaceId: 1),
      _place(id: 'p2', serverPlaceId: 2, imageUrl: 'https://already.jpg'),
      _place(id: 'p3'), // serverPlaceId 없음(외부 장소)
    ]);
    final useCase = BackfillPlaceImagesUseCase(
      repository,
      placeImageFetcher: (placeId) async => 'https://img/$placeId.jpg',
      kakaoImageSearchFetcher: _noKakaoFallback,
    );

    await useCase.call('fr-1');

    expect(repository.updatedImageUrls, {'p1': 'https://img/1.jpg'});
  });

  test('보충할 장소가 없으면 아무것도 하지 않는다', () async {
    final repository = _StubFilmRollPlaceRepository([
      _place(id: 'p1', serverPlaceId: 1, imageUrl: 'https://already.jpg'),
    ]);
    var fetchCount = 0;
    final useCase = BackfillPlaceImagesUseCase(
      repository,
      placeImageFetcher: (placeId) async {
        fetchCount++;
        return 'x';
      },
      kakaoImageSearchFetcher: _noKakaoFallback,
    );

    await useCase.call('fr-1');

    expect(fetchCount, 0);
    expect(repository.updatedImageUrls, isEmpty);
  });

  test('fetcher가 null을 반환하면 카카오 이미지 검색으로 폴백한다', () async {
    final repository = _StubFilmRollPlaceRepository([
      _place(id: 'p1', serverPlaceId: 1, name: '제민천'),
    ]);
    final useCase = BackfillPlaceImagesUseCase(
      repository,
      placeImageFetcher: (placeId) async => null,
      kakaoImageSearchFetcher: (placeName) async =>
          placeName == '제민천' ? 'https://kakao-img/1.jpg' : null,
    );

    await useCase.call('fr-1');

    expect(repository.updatedImageUrls, {'p1': 'https://kakao-img/1.jpg'});
  });

  test('한 장소의 보충이 예외로 실패해도 나머지는 계속 보충한다', () async {
    final repository = _StubFilmRollPlaceRepository([
      _place(id: 'p1', serverPlaceId: 1),
      _place(id: 'p2', serverPlaceId: 2),
    ]);
    final useCase = BackfillPlaceImagesUseCase(
      repository,
      placeImageFetcher: (placeId) async {
        if (placeId == 1) throw Exception('network error');
        return 'https://img/$placeId.jpg';
      },
      kakaoImageSearchFetcher: _noKakaoFallback,
    );

    await useCase.call('fr-1');

    expect(repository.updatedImageUrls, {'p2': 'https://img/2.jpg'});
  });

  test('regionId가 있으면 serverPlaceId 없이 externalPlaceId만 있는 장소도 보충한다', () async {
    final repository = _StubFilmRollPlaceRepository([
      _place(id: 'p1', externalPlaceId: 'tour-1'),
      _place(id: 'p2', externalPlaceId: 'tour-2'),
    ]);
    final regionIdsQueried = <int>[];
    final useCase = BackfillPlaceImagesUseCase(
      repository,
      externalPlaceImageFetcher: (regionId) async {
        regionIdsQueried.add(regionId);
        return {'tour-1': 'https://img/tour-1.jpg'};
      },
      kakaoImageSearchFetcher: _noKakaoFallback,
    );

    await useCase.call('fr-1', regionId: 10);

    expect(regionIdsQueried, [10]);
    // p2는 외부 목록에 이미지가 없어 카카오 폴백까지 가지만, 폴백도
    // null이라 최종적으로 채워지지 않는다.
    expect(repository.updatedImageUrls, {'p1': 'https://img/tour-1.jpg'});
  });

  test('regionId가 없으면 외부 장소 조회 자체를 시도하지 않는다', () async {
    final repository = _StubFilmRollPlaceRepository([
      _place(id: 'p1', externalPlaceId: 'tour-1'),
    ]);
    var fetchCount = 0;
    final useCase = BackfillPlaceImagesUseCase(
      repository,
      externalPlaceImageFetcher: (regionId) async {
        fetchCount++;
        return {'tour-1': 'https://img/tour-1.jpg'};
      },
      kakaoImageSearchFetcher: _noKakaoFallback,
    );

    await useCase.call('fr-1');

    expect(fetchCount, 0);
    expect(repository.updatedImageUrls, isEmpty);
  });

  test(
    'serverPlaceId/externalPlaceId 어느 쪽으로도 못 채운 장소는 장소명으로 카카오 이미지 검색을 시도한다',
    () async {
      final repository = _StubFilmRollPlaceRepository([
        _place(id: 'p1', externalPlaceId: 'kakao-1', name: '너티트릿츠'),
      ]);
      final queriedNames = <String>[];
      final useCase = BackfillPlaceImagesUseCase(
        repository,
        externalPlaceImageFetcher: (regionId) async => const {}, // TourAPI엔 없음
        kakaoImageSearchFetcher: (placeName) async {
          queriedNames.add(placeName);
          return 'https://kakao-img/nutty.jpg';
        },
      );

      await useCase.call('fr-1', regionId: 10);

      expect(queriedNames, ['너티트릿츠']);
      expect(repository.updatedImageUrls, {
        'p1': 'https://kakao-img/nutty.jpg',
      });
    },
  );

  test('외부 목록에서 이미 채워진 장소는 카카오 이미지 검색을 다시 시도하지 않는다', () async {
    final repository = _StubFilmRollPlaceRepository([
      _place(id: 'p1', externalPlaceId: 'tour-1', name: '제민천'),
    ]);
    var kakaoQueryCount = 0;
    final useCase = BackfillPlaceImagesUseCase(
      repository,
      externalPlaceImageFetcher: (regionId) async => {
        'tour-1': 'https://img/tour-1.jpg',
      },
      kakaoImageSearchFetcher: (placeName) async {
        kakaoQueryCount++;
        return 'https://kakao-img/should-not-be-used.jpg';
      },
    );

    await useCase.call('fr-1', regionId: 10);

    expect(kakaoQueryCount, 0);
    expect(repository.updatedImageUrls, {'p1': 'https://img/tour-1.jpg'});
  });

  test('카카오 이미지 검색이 예외로 실패해도 나머지 장소는 계속 보충한다', () async {
    final repository = _StubFilmRollPlaceRepository([
      _place(id: 'p1', name: '실패장소'),
      _place(id: 'p2', name: '성공장소'),
    ]);
    final useCase = BackfillPlaceImagesUseCase(
      repository,
      kakaoImageSearchFetcher: (placeName) async {
        if (placeName == '실패장소') throw Exception('network error');
        return 'https://kakao-img/success.jpg';
      },
    );

    await useCase.call('fr-1');

    expect(repository.updatedImageUrls, {
      'p2': 'https://kakao-img/success.jpg',
    });
  });
}
