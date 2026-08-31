/// 필름롤에 선택된 코스의 장소 스냅샷 도메인 엔티티.
/// [photoCount]는 DB에 별도 컬럼으로 저장하지 않고 [Photos] 테이블을 집계해 계산한다.
class FilmRollPlace {
  const FilmRollPlace({
    required this.id,
    required this.filmRollId,
    required this.name,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.visitOrder,
    required this.isVisited,
    required this.photoCount,
    this.serverPlaceId,
    this.externalPlaceId,
    this.imageUrl,
    this.visitedAt,
    this.visitSyncedAt,
  });

  final String id;
  final String filmRollId;
  final int? serverPlaceId;
  final String? externalPlaceId;
  final String name;
  final String address;
  final String category;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final int visitOrder;
  final bool isVisited;
  final DateTime? visitedAt;

  /// 이 장소의 방문 인증이 서버에 반영된 시각. null이면 서버 미전송.
  final DateTime? visitSyncedAt;
  final int photoCount;
}
