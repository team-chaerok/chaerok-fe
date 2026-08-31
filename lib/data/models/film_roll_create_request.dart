class FilmRollCreateRequest {
  const FilmRollCreateRequest({
    required this.clientFilmRollId,
    required this.regionId,
    required this.filterId,
    required this.filterStrength,
  });

  /// FE 로컬 FilmRoll의 UUID. 서버는 이를 멱등키로 취급해, 같은 사용자와
  /// 같은 clientFilmRollId 재요청에는 기존 FilmRoll을 반환한다.
  final String clientFilmRollId;
  final int regionId;
  final String filterId;
  final double filterStrength;

  Map<String, dynamic> toJson() => {
    'clientFilmRollId': clientFilmRollId,
    'regionId': regionId,
    'filterId': filterId,
    'filterStrength': filterStrength,
  };
}
