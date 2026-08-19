import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';

/// [PlaceListResponse]가 현재 진행중 필름롤에서 이미 채록(방문)된 장소와
/// 동일한 실제 장소인지 판정한다. 서버 DB에 등록된 장소는 [PlaceListResponse.id]
/// (`FilmRollPlace.serverPlaceId`와 동일 출처)로 우선 비교하고, 없으면
/// `source`에 대응하는 외부 ID(`kakaoPlaceId`/`tourContentId`)를
/// `FilmRollPlace.externalPlaceId`와 비교한다.
/// (`CoursePlaceResponse.identityParts`가 코스 확정 시 사용하는 것과 동일한
/// 식별 우선순위를 따른다.)
class NearbyPlaceRecorder {
  const NearbyPlaceRecorder._();

  static const _kakaoSource = 'KAKAO';
  static const _tourApiSource = 'TOUR_API';

  static bool isRecorded(
    PlaceListResponse place,
    List<FilmRollPlace> filmRollPlaces,
  ) {
    final externalId = _externalIdOf(place);
    for (final filmRollPlace in filmRollPlaces) {
      if (!filmRollPlace.isVisited) continue;
      if (place.id != null && filmRollPlace.serverPlaceId == place.id) {
        return true;
      }
      if (externalId != null && filmRollPlace.externalPlaceId == externalId) {
        return true;
      }
    }
    return false;
  }

  static String? _externalIdOf(PlaceListResponse place) {
    switch (place.source) {
      case _kakaoSource:
        return place.kakaoPlaceId;
      case _tourApiSource:
        return place.tourContentId;
      default:
        return null;
    }
  }
}
