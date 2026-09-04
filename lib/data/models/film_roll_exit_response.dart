class FilmRollExitResponse {
  const FilmRollExitResponse({
    required this.filmRollId,
    required this.status,
    required this.exitedAt,
    this.developAvailableAt,
    required this.developAvailable,
  });

  factory FilmRollExitResponse.fromJson(Map<String, dynamic> json) {
    return FilmRollExitResponse(
      filmRollId: json['filmRollId'] as int,
      status: json['status'] as String,
      exitedAt: DateTime.parse(json['exitedAt'] as String),
      // 조건 미충족(EXPIRED) 응답에는 현상 완료 예정 시각이 없을 수 있다.
      developAvailableAt: json['developAvailableAt'] != null
          ? DateTime.parse(json['developAvailableAt'] as String)
          : null,
      developAvailable: json['developAvailable'] as bool,
    );
  }

  factory FilmRollExitResponse.empty() {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return FilmRollExitResponse(
      filmRollId: 0,
      status: '',
      exitedAt: epoch,
      developAvailable: false,
    );
  }

  final int filmRollId;
  final String status;
  final DateTime exitedAt;
  final DateTime? developAvailableAt;
  final bool developAvailable;
}
