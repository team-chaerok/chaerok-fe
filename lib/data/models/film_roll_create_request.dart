class FilmRollCreateRequest {
  const FilmRollCreateRequest({
    required this.regionId,
    required this.filterId,
    required this.filterStrength,
  });

  final int regionId;
  final String filterId;
  final double filterStrength;

  Map<String, dynamic> toJson() => {
    'regionId': regionId,
    'filterId': filterId,
    'filterStrength': filterStrength,
  };
}
