import 'package:chaerok/data/models/place_category.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/data/models/place_search_response.dart';
import 'package:chaerok/features/explore/data/bookmark_store.dart';

const _kakaoSource = 'KAKAO';

/// `/api/places/search`가 실제로 내려주는 Kakao 소스 값(Swagger 예시의 `KAKAO`와
/// 다름 — 실기기 로그로 확인). 어느 값이 오든 Kakao 장소로 인식하도록 둘 다 받는다.
const _kakaoLocalSource = 'KAKAO_LOCAL';
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
    required this.categoryGroupWire,
    required this.categoryDetail,
    required this.categoryDetailLabel,
    required this.source,
    required this.identityKey,
    this.serverId,
    this.externalPlaceId,
    this.imageUrl,
  });

  factory ExplorePlace.fromListResponse(PlaceListResponse place) {
    return ExplorePlace(
      title: place.title,
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
      categoryGroup: PlaceCategoryGroup.fromWire(place.categoryGroup),
      categoryGroupWire: place.categoryGroup,
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
      externalPlaceId: _externalPlaceId(
        source: place.source,
        tourContentId: place.tourContentId,
        kakaoPlaceId: place.kakaoPlaceId,
      ),
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
      categoryGroupWire: place.categoryGroup,
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
      externalPlaceId: _externalPlaceId(
        source: place.source,
        tourContentId: place.tourContentId,
        kakaoPlaceId: place.kakaoPlaceId,
      ),
      imageUrl: place.firstImageUrl,
    );
  }

  /// 북마크(`BookmarkStore`, 로컬 전용)에서 저장해 둔 원본 필드로 복원한다.
  /// 주소는 [BookmarkedPlace]가 보관하지 않아 빈 문자열로 채운다(코스 생성
  /// 요청의 `address`는 선택 필드라 문제없다).
  factory ExplorePlace.fromBookmarkedPlace(BookmarkedPlace place) {
    return ExplorePlace(
      title: place.title,
      address: '',
      latitude: place.latitude,
      longitude: place.longitude,
      categoryGroup: PlaceCategoryGroup.fromWire(place.categoryGroupWire),
      categoryGroupWire: place.categoryGroupWire,
      categoryDetail: PlaceCategoryDetail.fromWire(place.categoryLabel),
      categoryDetailLabel: place.categoryLabel,
      source: place.source,
      identityKey: place.identityKey,
      serverId: place.serverId,
      externalPlaceId: place.externalPlaceId,
      imageUrl: place.imageUrl,
    );
  }

  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final PlaceCategoryGroup categoryGroup;

  /// [categoryGroup]의 원본 wire 문자열. 알 수 없는 값이면 [PlaceCategoryGroup.unknown]
  /// 으로 흡수돼 `wireValue`(빈 문자열)로는 복원할 수 없으므로, 코스 생성 요청처럼
  /// 원본 값을 그대로 서버에 되돌려줘야 하는 경우를 위해 별도 보관한다.
  final String categoryGroupWire;
  final PlaceCategoryDetail categoryDetail;

  /// 카드에 그대로 노출하는 원본 소분류 문자열(백엔드가 한글을 줄 수도 있어 보존).
  final String categoryDetailLabel;
  final String source;
  final String identityKey;
  final int? serverId;

  /// TourAPI(`tourContentId`)/Kakao(`kakaoPlaceId`) 외부 장소 ID. [identityKey]에도
  /// 인코딩돼 있지만 문자열 파싱으로 역산하지 않도록 별도 필드로 노출한다.
  final String? externalPlaceId;
  final String? imageUrl;

  /// 장소를 진입 경로와 무관하게 동일하게 식별하는 키.
  ///
  /// 지역 목록과 검색 모두 `id`가 nullable이다(검색 결과는 DB에 저장되지 않아 항상
  /// null). 같은 장소가 서로 다른 필드 조합으로 올 수 있다. 두 응답 모두
  /// TourAPI/Kakao 장소면 외부 ID(`tourContentId`/`kakaoPlaceId`)를 함께 내려주므로,
  /// **외부 ID를 최우선**으로 써서 `serverId` 유무에 따라 키가 갈라지지 않게 한다.
  /// 외부 ID가 없는 순수 DB 장소만 `serverId`(두 응답 모두 보유)로 식별한다.
  static String _identityKey({
    required String source,
    required int? serverId,
    required String? tourContentId,
    required String? kakaoPlaceId,
    required String title,
    required String address,
  }) {
    final externalId = _externalPlaceId(
      source: source,
      tourContentId: tourContentId,
      kakaoPlaceId: kakaoPlaceId,
    );
    if (externalId != null && externalId.isNotEmpty) {
      return 'external:$source:$externalId';
    }
    if (serverId != null) return 'place:$serverId';
    return 'title:$source:$title:$address';
  }

  /// 소스별 외부 장소 ID(TourAPI는 `tourContentId`, Kakao는 `kakaoPlaceId`)를 고른다.
  static String? _externalPlaceId({
    required String source,
    required String? tourContentId,
    required String? kakaoPlaceId,
  }) {
    return switch (source) {
      _kakaoSource || _kakaoLocalSource => kakaoPlaceId,
      _tourApiSource => tourContentId,
      _ => null,
    };
  }
}
