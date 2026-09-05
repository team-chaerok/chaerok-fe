class VisitCreateRequest {
  const VisitCreateRequest({required this.placeId, required this.photoId});

  final int placeId;

  /// 업로드 완료된 서버 사진 ID. 방문 인증은 사진이 있어야 한다.
  final int photoId;

  Map<String, dynamic> toJson() => {'placeId': placeId, 'photoId': photoId};
}
