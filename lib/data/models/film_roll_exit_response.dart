class FilmRollExitResponse {
  const FilmRollExitResponse({
    required this.filmRollId,
    required this.status,
    required this.exitedAt,
    required this.developAvailableAt,
    required this.developAvailable,
  });

  factory FilmRollExitResponse.fromJson(Map<String, dynamic> json) {
    return FilmRollExitResponse(
      filmRollId: json['filmRollId'] as int,
      status: json['status'] as String,
      exitedAt: DateTime.parse(json['exitedAt'] as String),
      developAvailableAt: DateTime.parse(json['developAvailableAt'] as String),
      developAvailable: json['developAvailable'] as bool,
    );
  }

  factory FilmRollExitResponse.empty() {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return FilmRollExitResponse(
      filmRollId: 0,
      status: '',
      exitedAt: epoch,
      developAvailableAt: epoch,
      developAvailable: false,
    );
  }

  final int filmRollId;
  final String status;
  final DateTime exitedAt;
  final DateTime developAvailableAt;
  final bool developAvailable;
}
