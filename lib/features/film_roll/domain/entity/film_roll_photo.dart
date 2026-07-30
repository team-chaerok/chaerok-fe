/// 방문 인증 사진 도메인 엔티티. 원본/썸네일 실제 파일은 앱 내부 파일 시스템에 저장되며,
/// 여기서는 경로/메타데이터만 다룬다.
class FilmRollPhoto {
  const FilmRollPhoto({
    required this.id,
    required this.filmRollId,
    required this.filmRollPlaceId,
    required this.originalPath,
    required this.thumbnailPath,
    required this.takenAt,
    required this.isSynced,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String filmRollId;
  final String filmRollPlaceId;
  final String originalPath;
  final String thumbnailPath;
  final double? latitude;
  final double? longitude;
  final DateTime takenAt;
  final bool isSynced;
}
