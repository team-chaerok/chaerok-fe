/// `POST /api/film-rolls/{id}/photos/{photoId}/complete` 응답.
class PhotoCompleteResponse {
  const PhotoCompleteResponse({
    required this.photoId,
    required this.filmRollId,
    required this.sequence,
    required this.status,
    required this.totalPhotoCount,
    this.uploadCompletedAt,
  });

  factory PhotoCompleteResponse.fromJson(Map<String, dynamic> json) {
    return PhotoCompleteResponse(
      photoId: json['photoId'] as int,
      filmRollId: json['filmRollId'] as int,
      sequence: json['sequence'] as int,
      status: json['status'] as String,
      totalPhotoCount: json['totalPhotoCount'] as int,
      uploadCompletedAt: json['uploadCompletedAt'] != null
          ? DateTime.parse(json['uploadCompletedAt'] as String)
          : null,
    );
  }

  /// 응답 본문이 비었을 때의 센티넬. `photoId == 0`으로 실패를 구분한다.
  factory PhotoCompleteResponse.empty() {
    return const PhotoCompleteResponse(
      photoId: 0,
      filmRollId: 0,
      sequence: 0,
      status: '',
      totalPhotoCount: 0,
    );
  }

  final int photoId;
  final int filmRollId;
  final int sequence;
  final String status;
  final int totalPhotoCount;
  final DateTime? uploadCompletedAt;
}
