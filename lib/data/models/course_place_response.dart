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

  /// 장소의 안정적인 식별자 구성 요소. 서버 장소 ID를 우선 사용하고, 없으면
  /// 외부 장소 ID, 그마저 없으면 제목+주소 조합으로 대체한다. 첫 요소는 ID
  /// 종류(kind) 태그, 두 번째는 [source]로, 서로 다른 종류/출처의 ID 값이
  /// 우연히 같은 문자열이더라도 다른 장소로 구분되도록 한다. 이 값들은
  /// [CourseResponse.courseId]에서 구조적으로(JSON) 결합되므로 각 요소
  /// 내부에 구분자(`|`, `@` 등)가 포함되어도 충돌하지 않는다.
  List<String> get identityParts {
    if (placeId != null) return ['place', source, placeId.toString()];
    if (externalPlaceId != null) return ['external', source, externalPlaceId!];
    return ['title', source, title, address];
  }
}
