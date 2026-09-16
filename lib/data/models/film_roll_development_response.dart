class FilmRollDevelopmentResponse {
  const FilmRollDevelopmentResponse({
    required this.filmRollId,
    required this.status,
    required this.totalPhotoCount,
    required this.requestedAt,
  });

  factory FilmRollDevelopmentResponse.fromJson(Map<String, dynamic> json) {
    return FilmRollDevelopmentResponse(
      filmRollId: json['filmRollId'] as int,
      status: json['status'] as String,
      totalPhotoCount: json['totalPhotoCount'] as int,
      requestedAt: DateTime.parse(json['requestedAt'] as String),
    );
  }

  factory FilmRollDevelopmentResponse.empty() {
    return FilmRollDevelopmentResponse(
      filmRollId: 0,
      status: '',
      totalPhotoCount: 0,
      requestedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final int filmRollId;
  final String status;
  final int totalPhotoCount;
  final DateTime requestedAt;
}
