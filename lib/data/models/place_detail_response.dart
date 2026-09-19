class PlaceDetailResponse {
  const PlaceDetailResponse({
    required this.id,
    required this.regionId,
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
    this.overview,
    this.lDongRegnCd,
    this.lDongSignguCd,
    this.lclsSystm1,
    this.lclsSystm2,
    this.lclsSystm3,
    this.openingHours,
    this.phone,
  });

  factory PlaceDetailResponse.fromJson(Map<String, dynamic> json) {
    return PlaceDetailResponse(
      id: json['id'] as int,
      regionId: json['regionId'] as int,
      tourContentId: json['tourContentId'] as String?,
      kakaoPlaceId: json['kakaoPlaceId'] as String?,
      title: json['title'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      firstImageUrl: json['firstImageUrl'] as String?,
      overview: json['overview'] as String?,
      lDongRegnCd: json['lDongRegnCd'] as String?,
      lDongSignguCd: json['lDongSignguCd'] as String?,
      lclsSystm1: json['lclsSystm1'] as String?,
      lclsSystm2: json['lclsSystm2'] as String?,
      lclsSystm3: json['lclsSystm3'] as String?,
      // TourAPI detailIntro2 usetime/infocenter passthrough — 백엔드가 아직
      // 내려주지 않으면 null(안내 문구를 화면에서 숨긴다).
      openingHours: json['openingHours'] as String?,
      phone: json['phone'] as String?,
      categoryGroup: json['categoryGroup'] as String,
      categoryDetail: json['categoryDetail'] as String,
      isRepresentative: json['isRepresentative'] as bool,
      source: json['source'] as String,
    );
  }

  factory PlaceDetailResponse.empty() {
    return const PlaceDetailResponse(
      id: 0,
      regionId: 0,
      title: '',
      address: '',
      latitude: 0,
      longitude: 0,
      categoryGroup: '',
      categoryDetail: '',
      isRepresentative: false,
      source: '',
    );
  }

  final int id;
  final int regionId;
  final String? tourContentId;
  final String? kakaoPlaceId;
  final String title;
  final String address;
  final double latitude;
  final double longitude;
  final String? firstImageUrl;
  final String? overview;
  final String? lDongRegnCd;
  final String? lDongSignguCd;
  final String? lclsSystm1;
  final String? lclsSystm2;
  final String? lclsSystm3;

  /// TourAPI detailIntro2의 `usetime`(운영시간). 백엔드가 아직 내려주지 않는다.
  final String? openingHours;

  /// TourAPI detailIntro2의 `infocenter`(전화번호). 백엔드가 아직 내려주지 않는다.
  final String? phone;
  final String categoryGroup;
  final String categoryDetail;
  final bool isRepresentative;
  final String source;
}
