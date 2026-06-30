class ResolveRegionRequest {
  const ResolveRegionRequest({
    required this.provinceName,
    required this.cityCountyName,
  });

  final String provinceName;
  final String cityCountyName;

  Map<String, dynamic> toJson() => {
    'provinceName': provinceName,
    'cityCountyName': cityCountyName,
  };
}
