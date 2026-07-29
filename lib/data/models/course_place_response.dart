class CoursePlaceResponse {
  const CoursePlaceResponse({
    required this.source,
    required this.title,
    required this.categoryGroup,
    required this.address,
    this.placeId,
    this.externalPlaceId,
    this.categoryDetail,
    this.latitude,
    this.longitude,
    this.placeUrl,
  });

  factory CoursePlaceResponse.fromJson(Map<String, dynamic> json) {
    return CoursePlaceResponse(
      placeId: json['placeId'] as int?,
      externalPlaceId: json['externalPlaceId'] as String?,
      source: json['source'] as String,
      title: json['title'] as String,
      categoryGroup: json['categoryGroup'] as String,
      categoryDetail: json['categoryDetail'] as String?,
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      placeUrl: json['placeUrl'] as String?,
    );
  }

  final int? placeId;
  final String? externalPlaceId;
  final String source;
  final String title;
  final String categoryGroup;
  final String? categoryDetail;
  final String address;
  final double? latitude;
  final double? longitude;
  final String? placeUrl;
}
