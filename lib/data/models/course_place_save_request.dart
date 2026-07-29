class CoursePlaceSaveRequest {
  const CoursePlaceSaveRequest({
    required this.title,
    required this.categoryGroup,
    this.placeId,
    this.externalPlaceId,
    this.source,
    this.categoryDetail,
    this.address,
    this.latitude,
    this.longitude,
    this.placeUrl,
  });

  final int? placeId;
  final String? externalPlaceId;
  final String? source;
  final String title;
  final String categoryGroup;
  final String? categoryDetail;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? placeUrl;

  Map<String, dynamic> toJson() => {
    'placeId': placeId,
    'externalPlaceId': externalPlaceId,
    'source': source,
    'title': title,
    'categoryGroup': categoryGroup,
    'categoryDetail': categoryDetail,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
    'placeUrl': placeUrl,
  };
}
