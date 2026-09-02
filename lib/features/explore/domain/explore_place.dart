import 'package:chaerok/data/models/place_category.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/data/models/place_search_response.dart';

const _kakaoSource = 'KAKAO';
const _tourApiSource = 'TOUR_API';

/// 탐색 모드가 소비하는 장소 표시/식별 모델.
///
/// 지역 장소 목록(`PlaceListResponse`)과 검색 결과(`PlaceSearchResponse`)는
/// 필드 구성이 거의 같지만 별개 타입이라, 화면에서 하나로 다루기 위해 이
/// 값 객체로 정규화한다. [identityKey]는 북마크/방문 매칭에 쓰이며
/// `NearbyPlaceRecorder`/`CoursePlaceResponse.identityParts`와 동일한
/// 식별 우선순위(서버 ID → 외부 ID → 제목+주소)를 따른다.
class ExplorePlace {
  const ExplorePlace({
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.categoryGroup,
    required this.categoryDetail,
    required this.categoryDetailLabel,
    required this.source,
    required this.identityKey,
    this.serverId,
    this.imageUrl,
  });

  factory ExplorePlace.fromListResponse(PlaceListResponse place) {
    return ExplorePlace(
      title: place.title,
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
      categoryGroup: PlaceCategoryGroup.fromWire(place.categoryGroup),
      categoryDetail: PlaceCategoryDetail.fromWire(place.categoryDetail),
      categoryDetailLabel: place.categoryDetail,
      source: place.source,
      identityKey: _identityKey(
        source: place.source,
        serverId: place.id,
        tourContentId: place.tourContentId,
        kakaoPlaceId: place.kakaoPlaceId,
        title: place.title,
        address: place.address,
      ),
      serverId: place.id,
      imageUrl: place.firstImageUrl,
    );
  }

  factory ExplorePlace.fromSearchResponse(PlaceSearchResponse place) {
    return ExplorePlace(
      title: place.title,
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
      categoryGroup: PlaceCategoryGroup.fromWire(place.categoryGroup),
      categoryDetail: PlaceCategoryDetail.fromWire(place.categoryDetail),
      categoryDetailLabel: place.categoryDetail,
      source: place.source,
      identityKey: _identityKey(
        source: place.source,
        serverId: place.id,
        tourContentId: place.tourContentId,
        kakaoPlaceId: place.kakaoPlaceId,
        title: place.title,
        address: place.address,
      ),
      serverId: place.id,
      imageUrl: place.firstImageUrl,
    );
  }

  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final PlaceCategoryGroup categoryGroup;
  final PlaceCategoryDetail categoryDetail;

  /// 카드에 그대로 노출하는 원본 소분류 문자열(백엔드가 한글을 줄 수도 있어 보존).
  final String categoryDetailLabel;
  final String source;
  final String identityKey;
  final int? serverId;
  final String? imageUrl;

  static String _identityKey({
    required String source,
    required int? serverId,
    required String? tourContentId,
    required String? kakaoPlaceId,
    required String title,
    required String address,
  }) {
    if (serverId != null) return 'place:$source:$serverId';
    final externalId = switch (source) {
      _kakaoSource => kakaoPlaceId,
      _tourApiSource => tourContentId,
      _ => null,
    };
    if (externalId != null) return 'external:$source:$externalId';
    return 'title:$source:$title:$address';
  }
}
