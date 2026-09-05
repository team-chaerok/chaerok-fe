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
    required this.sequence,
    required this.isSynced,
    this.serverPhotoId,
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

  /// 필름롤 안에서의 촬영 순서(1~24). 촬영 시점에 로컬에서 부여하고
  /// `POST .../photos/upload-url` 의 `sequence` 로 보낸다.
  final int sequence;

  /// 서버가 발급한 사진 PK. null이면 아직 서버에 업로드되지 않았다.
  final int? serverPhotoId;

  /// 서버 업로드 완료 여부. true면 [serverPhotoId]가 채워져 있다.
  final bool isSynced;

  /// 저장된 상대 경로를 실제 접근 가능한 절대 경로로 교체할 때 사용한다.
  FilmRollPhoto copyWith({String? originalPath, String? thumbnailPath}) {
    return FilmRollPhoto(
      id: id,
      filmRollId: filmRollId,
      filmRollPlaceId: filmRollPlaceId,
      originalPath: originalPath ?? this.originalPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      takenAt: takenAt,
      sequence: sequence,
      serverPhotoId: serverPhotoId,
      isSynced: isSynced,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
