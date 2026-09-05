/// `POST /api/film-rolls/{id}/photos/upload-url` 요청.
class PhotoUploadUrlRequest {
  const PhotoUploadUrlRequest({
    required this.sequence,
    required this.contentType,
    required this.contentLength,
    required this.takenAt,
  });

  final int sequence;
  final String contentType;
  final int contentLength;

  /// 촬영 시각. JSON에는 타임존/밀리초 없는 로컬 `yyyy-MM-ddTHH:mm:ss`로 보낸다.
  final DateTime takenAt;

  /// 백엔드 LocalDateTime 규약: 타임존·밀리초 없이 초 단위까지.
  static String formatTakenAt(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year.toString().padLeft(4, '0')}-'
        '${two(local.month)}-${two(local.day)}T'
        '${two(local.hour)}:${two(local.minute)}:${two(local.second)}';
  }

  Map<String, dynamic> toJson() => {
    'sequence': sequence,
    'contentType': contentType,
    'contentLength': contentLength,
    'takenAt': formatTakenAt(takenAt),
  };
}
