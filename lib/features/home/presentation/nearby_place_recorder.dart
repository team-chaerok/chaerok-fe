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

  /// `/api/places/search`가 실제로 내려주는 Kakao 소스 값(Swagger 예시의 `KAKAO`와
  /// 다름 — 실기기 로그로 확인, [ExplorePlace] 참고). 어느 값이 오든 Kakao 장소로
  /// 인식하도록 둘 다 받는다.
  static const _kakaoLocalSource = 'KAKAO_LOCAL';
  static const _tourApiSource = 'TOUR_API';

  static bool isRecorded(
    PlaceListResponse place,
    List<FilmRollPlace> filmRollPlaces,
  ) {
    final placeId = place.id;
    final externalId = _externalIdOf(place);

    for (final filmRollPlace in filmRollPlaces) {
      if (!filmRollPlace.isVisited) continue;
      // 서버 ID가 있으면 그것만으로 판정한다 — externalId가 우연히 같더라도
      // 서버 ID가 다르면 다른 장소이므로 무시해야 한다(identityParts와 동일한
      // 우선순위: 서버 ID 있으면 서버 ID만 사용, 없을 때만 external ID로 대체).
      final matches = placeId != null
          ? filmRollPlace.serverPlaceId == placeId
          : externalId != null && filmRollPlace.externalPlaceId == externalId;
      if (matches) return true;
    }
    return false;
  }

  static String? _externalIdOf(PlaceListResponse place) {
    switch (place.source) {
      case _kakaoSource || _kakaoLocalSource:
        return place.kakaoPlaceId;
      case _tourApiSource:
        return place.tourContentId;
      default:
        return null;
    }
  }
}
