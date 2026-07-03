class RegionResponse {
  const RegionResponse({
    required this.serviceArea,
    required this.regionId,
    required this.provinceName,
    required this.cityCountyName,
  });

  factory RegionResponse.fromJson(Map<String, dynamic> json) {
    return RegionResponse(
      serviceArea: json['serviceArea'] as bool,
      regionId: json['regionId'] as int,
      provinceName: json['provinceName'] as String,
      cityCountyName: json['cityCountyName'] as String,
    );
  }

  final bool serviceArea;
  final int regionId;
  final String provinceName;
  final String cityCountyName;
}
