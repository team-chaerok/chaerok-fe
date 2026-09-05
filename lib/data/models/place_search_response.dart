class PlaceSearchResponse {
  const PlaceSearchResponse({
    this.id,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.categoryGroup,
    required this.categoryDetail,
    required this.source,
    this.tourContentId,
    this.kakaoPlaceId,
    this.firstImageUrl,
  });

  factory PlaceSearchResponse.fromJson(Map<String, dynamic> json) {
    return PlaceSearchResponse(
      id: json['id'] as int?,
      tourContentId: json['tourContentId'] as String?,
      kakaoPlaceId: json['kakaoPlaceId'] as String?,
      title: json['title'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      firstImageUrl: json['firstImageUrl'] as String?,
      categoryGroup: json['categoryGroup'] as String,
      categoryDetail: json['categoryDetail'] as String,
      source: json['source'] as String,
    );
  }

  /// 검색 결과는 DB에 저장되지 않으므로(`PlacesApi.searchPlaces` 참고) id가 없을 수 있다.
  final int? id;
  final String? tourContentId;
  final String? kakaoPlaceId;
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final String? firstImageUrl;
  final String categoryGroup;
  final String categoryDetail;
  final String source;
}
