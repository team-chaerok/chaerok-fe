/// 필름롤 현상 결과 조회(`GET /api/film-rolls/{id}/results`) 응답.
/// `status`가 `COMPLETED`일 때만 [filteredPhotos]/[zip]/[reel]이 채워진다.
class FilmRollResultResponse {
  const FilmRollResultResponse({
    required this.filmRollId,
    required this.status,
    required this.totalPhotoCount,
    required this.processedPhotoCount,
    required this.filteredPhotos,
    this.zip,
    this.reel,
    this.requestedAt,
    this.completedAt,
    this.expiresAt,
    this.failure,
  });

  factory FilmRollResultResponse.fromJson(Map<String, dynamic> json) {
    return FilmRollResultResponse(
      filmRollId: json['filmRollId'] as int,
      status: json['status'] as String,
      totalPhotoCount: json['totalPhotoCount'] as int,
      processedPhotoCount: json['processedPhotoCount'] as int,
      filteredPhotos:
          (json['filteredPhotos'] as List<dynamic>?)
              ?.map(
                (e) =>
                    FilteredPhotoResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      zip: json['zip'] != null
          ? DownloadResponse.fromJson(json['zip'] as Map<String, dynamic>)
          : null,
      reel: json['reel'] != null
          ? DownloadResponse.fromJson(json['reel'] as Map<String, dynamic>)
          : null,
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      failure: json['failure'] != null
          ? FailureResponse.fromJson(json['failure'] as Map<String, dynamic>)
          : null,
    );
  }

  factory FilmRollResultResponse.empty() {
    return const FilmRollResultResponse(
      filmRollId: 0,
      status: '',
      totalPhotoCount: 0,
      processedPhotoCount: 0,
      filteredPhotos: [],
    );
  }

  final int filmRollId;
  final String status;
  final int totalPhotoCount;
  final int processedPhotoCount;
  final List<FilteredPhotoResponse> filteredPhotos;
  final DownloadResponse? zip;
  final DownloadResponse? reel;
  final DateTime? requestedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final FailureResponse? failure;

  bool get isCompleted => status == 'COMPLETED';
  bool get isFailed => status == 'FAILED';
  bool get isExpired => status == 'EXPIRED';

  /// 현상이 아직 끝나지 않아 폴링을 계속해야 하는 상태인지.
  bool get isInProgress => !isCompleted && !isFailed && !isExpired;
}

class FilteredPhotoResponse {
  const FilteredPhotoResponse({
    required this.photoId,
    required this.sequence,
    required this.downloadUrl,
    required this.downloadUrlExpiresAt,
  });

  factory FilteredPhotoResponse.fromJson(Map<String, dynamic> json) {
    return FilteredPhotoResponse(
      photoId: json['photoId'] as int,
      sequence: json['sequence'] as int,
      downloadUrl: json['downloadUrl'] as String,
      downloadUrlExpiresAt: DateTime.parse(
        json['downloadUrlExpiresAt'] as String,
      ),
    );
  }

  final int photoId;
  final int sequence;
  final String downloadUrl;
  final DateTime downloadUrlExpiresAt;
}

class DownloadResponse {
  const DownloadResponse({
    required this.downloadUrl,
    required this.downloadUrlExpiresAt,
    required this.fileSize,
  });

  factory DownloadResponse.fromJson(Map<String, dynamic> json) {
    return DownloadResponse(
      downloadUrl: json['downloadUrl'] as String,
      downloadUrlExpiresAt: DateTime.parse(
        json['downloadUrlExpiresAt'] as String,
      ),
      fileSize: json['fileSize'] as int,
    );
  }

  final String downloadUrl;
  final DateTime downloadUrlExpiresAt;
  final int fileSize;
}

class FailureResponse {
  const FailureResponse({required this.code, required this.message});

  factory FailureResponse.fromJson(Map<String, dynamic> json) {
    return FailureResponse(
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }

  final String code;
  final String message;
}
