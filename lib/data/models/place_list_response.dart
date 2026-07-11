class PlaceListResponse {
  const PlaceListResponse({
    required this.id,
    required this.title,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.categoryGroup,
    required this.categoryDetail,
    required this.isRepresentative,
    required this.source,
    this.tourContentId,
    this.kakaoPlaceId,
    this.firstImageUrl,
  });

  factory PlaceListResponse.fromJson(Map<String, dynamic> json) {
    return PlaceListResponse(
      id: json['id'] as int,
      tourContentId: json['tourContentId'] as String?,
      kakaoPlaceId: json['kakaoPlaceId'] as String?,
      title: json['title'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      firstImageUrl: json['firstImageUrl'] as String?,
      categoryGroup: json['categoryGroup'] as String,
      categoryDetail: json['categoryDetail'] as String,
      isRepresentative: json['isRepresentative'] as bool,
      source: json['source'] as String,
    );
  }

  final int id;
  final String? tourContentId;
  final String? kakaoPlaceId;
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final String? firstImageUrl;
  final String categoryGroup;
  final String categoryDetail;
  final bool isRepresentative;
  final String source;
}
