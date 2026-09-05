/// `POST /api/film-rolls/{id}/photos/upload-url` 응답.
class PhotoUploadUrlResponse {
  const PhotoUploadUrlResponse({
    required this.photoId,
    required this.filmRollId,
    required this.sequence,
    required this.objectKey,
    required this.uploadUrl,
    required this.expiresAt,
    required this.requiredHeaders,
  });

  factory PhotoUploadUrlResponse.fromJson(Map<String, dynamic> json) {
    final rawHeaders = json['requiredHeaders'] as Map<String, dynamic>? ?? {};
    final headers = <String, List<String>>{};
    for (final entry in rawHeaders.entries) {
      final value = entry.value;
      if (value is List) {
        headers[entry.key] = value.map((item) => item.toString()).toList();
      } else {
        headers[entry.key] = [value.toString()];
      }
    }

    return PhotoUploadUrlResponse(
      photoId: json['photoId'] as int,
      filmRollId: json['filmRollId'] as int,
      sequence: json['sequence'] as int,
      objectKey: json['objectKey'] as String,
      uploadUrl: json['uploadUrl'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      requiredHeaders: headers,
    );
  }

  /// 응답 본문이 비었을 때의 센티넬. `photoId == 0`으로 실패를 구분한다.
  factory PhotoUploadUrlResponse.empty() {
    return PhotoUploadUrlResponse(
      photoId: 0,
      filmRollId: 0,
      sequence: 0,
      objectKey: '',
      uploadUrl: '',
      expiresAt: DateTime.fromMillisecondsSinceEpoch(0),
      requiredHeaders: const {},
    );
  }

  final int photoId;
  final int filmRollId;
  final int sequence;
  final String objectKey;
  final String uploadUrl;
  final DateTime expiresAt;

  /// S3 PUT에 그대로 붙여야 하는 헤더. 키는 소문자(`content-type` 등)일 수 있다.
  final Map<String, List<String>> requiredHeaders;
}
