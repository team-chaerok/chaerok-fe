import 'dart:developer';

import 'package:chaerok/data/remote/places_api.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_place_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/select_course_use_case.dart';
import 'package:chaerok/features/location/data/kakao_local_api_service.dart';

const _tag = 'BackfillPlaceImagesUseCase';

/// [regionId]의 외부(TourAPI/Kakao) 장소를 실시간 조회해 `tourContentId`
/// (없으면 `kakaoPlaceId`) → 대표 사진 맵을 만든다. 실패하면 빈 맵을 반환해
/// 외부 장소 보충만 건너뛰고(서버 장소 보충에는 영향 없음) 예외를 흡수한다.
Future<Map<String, String>> defaultExternalPlaceImageFetcher(
  int regionId,
) async {
  try {
    final places = await PlacesApi.getExternalPlaces(regionId);
    final imagesByExternalId = <String, String>{};
    for (final place in places) {
      final externalId = place.tourContentId ?? place.kakaoPlaceId;
      final imageUrl = place.firstImageUrl;
      if (externalId != null && imageUrl != null) {
        imagesByExternalId[externalId] = imageUrl;
      }
    }
    return imagesByExternalId;
  } catch (e, st) {
    log(
      '외부 장소 목록 조회 실패(regionId=$regionId)',
      name: _tag,
      error: e,
      stackTrace: st,
    );
    return const {};
  }
}

/// 카카오 이미지 검색(다음 검색 API)으로 [placeName]의 대표 사진을 찾는다.
/// Kakao Local(장소 검색) API 자체가 사진을 제공하지 않는 Kakao 소스 장소를
/// 위한 최종 폴백 — 키워드 검색 결과라 정확히 그 장소의 사진이라는 보장은
/// 없다.
Future<String?> defaultKakaoImageSearchFetcher(String placeName) {
  return KakaoLocalApiService.searchPlaceImage(placeName);
}

/// [SelectCourseUseCase]의 이미지 보충 기능이 생기기 전에 이미 코스가 확정된
/// 필름롤은 장소에 [FilmRollPlace.imageUrl]이 계속 비어있다. 홈 진입 시 한 번,
/// 서버 DB 장소([FilmRollPlace.serverPlaceId] 있음)는 장소 상세 API로, 외부
/// (TourAPI/Kakao) 전용 장소([FilmRollPlace.externalPlaceId] 있음)는 같은
/// 지역의 외부 장소 목록으로 소급 보충한다. 그래도 남은 장소(Kakao Local로만
/// 들어와 애초에 사진이 없는 장소 등)는 장소명으로 카카오 이미지 검색을
/// 최종 폴백으로 시도한다. 이미 이미지가 있는 장소는 건드리지 않으므로,
/// 여러 번 호출해도 매번 남은 것만 다시 시도한다(멱등).
class BackfillPlaceImagesUseCase {
  const BackfillPlaceImagesUseCase(
    this._placeRepository, {
    this.placeImageFetcher = defaultPlaceImageFetcher,
    this.externalPlaceImageFetcher = defaultExternalPlaceImageFetcher,
    this.kakaoImageSearchFetcher = defaultKakaoImageSearchFetcher,
  });

  final FilmRollPlaceRepository _placeRepository;

  /// [SelectCourseUseCase]와 동일한 seam — 테스트에서 네트워크 없이 주입한다.
  final Future<String?> Function(int placeId) placeImageFetcher;

  /// 외부 장소 이미지 조회 seam. 지역 하나당 한 번만 호출하도록 이 use case가
  /// 결과를 묶어서 쓴다.
  final Future<Map<String, String>> Function(int regionId)
  externalPlaceImageFetcher;

  /// 장소명 기반 카카오 이미지 검색 seam.
  final Future<String?> Function(String placeName) kakaoImageSearchFetcher;

  /// [regionId]가 없으면(필름롤이 아직 서버와 동기화되지 않은 경우 등) 외부
  /// 장소 보충은 건너뛴다 — 서버 장소 보충·카카오 검색 폴백에는 영향 없다.
  Future<void> call(String filmRollId, {int? regionId}) async {
    final places = await _placeRepository.findByFilmRoll(filmRollId);

    final serverTargets = places
        .where((place) => place.imageUrl == null && place.serverPlaceId != null)
        .toList();
    final externalTargets = places
        .where(
          (place) =>
              place.imageUrl == null &&
              place.serverPlaceId == null &&
              place.externalPlaceId != null,
        )
        .toList();

    final serverResultsFuture = Future.wait(
      serverTargets.map(_backfillFromServer),
    );
    final externalResultsFuture = regionId != null && externalTargets.isNotEmpty
        ? _backfillFromExternal(regionId, externalTargets)
        : Future.value(const <String>{});

    final filledIds = <String>{
      ...(await serverResultsFuture).whereType<String>(),
      ...(await externalResultsFuture),
    };

    final kakaoTargets = places.where(
      (place) => place.imageUrl == null && !filledIds.contains(place.id),
    );
    await Future.wait(kakaoTargets.map(_backfillFromKakaoSearch));
  }

  Future<String?> _backfillFromServer(FilmRollPlace place) async {
    try {
      final imageUrl = await placeImageFetcher(place.serverPlaceId!);
      if (imageUrl == null) return null;
      await _placeRepository.updateImageUrl(place.id, imageUrl);
      return place.id;
    } catch (e, st) {
      log(
        '장소 이미지 소급 보충 실패(placeId=${place.id})',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<Set<String>> _backfillFromExternal(
    int regionId,
    List<FilmRollPlace> targets,
  ) async {
    final imagesByExternalId = await externalPlaceImageFetcher(regionId);
    if (imagesByExternalId.isEmpty) return const {};

    final filledIds = <String>{};
    await Future.wait(
      targets.map((place) async {
        final imageUrl = imagesByExternalId[place.externalPlaceId];
        if (imageUrl == null) return;
        try {
          await _placeRepository.updateImageUrl(place.id, imageUrl);
          filledIds.add(place.id);
        } catch (e, st) {
          log(
            '외부 장소 이미지 소급 보충 실패(placeId=${place.id})',
            name: _tag,
            error: e,
            stackTrace: st,
          );
        }
      }),
    );
    return filledIds;
  }

  Future<void> _backfillFromKakaoSearch(FilmRollPlace place) async {
    try {
      final imageUrl = await kakaoImageSearchFetcher(place.name);
      if (imageUrl == null) return;
      await _placeRepository.updateImageUrl(place.id, imageUrl);
    } catch (e, st) {
      log(
        '카카오 이미지 검색 보충 실패(placeId=${place.id})',
        name: _tag,
        error: e,
        stackTrace: st,
      );
    }
  }
}
