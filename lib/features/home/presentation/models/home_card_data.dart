/// 홈 대시보드/채록길 카드 위젯이 소비하는 표시 전용 뷰 데이터.
/// 도메인 엔티티(`FilmRoll`, `PlaceListResponse` 등)를 화면에서 이 타입으로
/// 매핑해 사용하며, UI 디자인 프리뷰(`lib/ui/home`)도 동일한 타입을 재사용한다.
class FilmRollSummaryData {
  const FilmRollSummaryData({
    required this.name,
    required this.capturedCount,
    required this.totalCount,
  });

  final String name;
  final int capturedCount;
  final int totalCount;

  double get progress =>
      totalCount <= 0 ? 0.0 : (capturedCount / totalCount).clamp(0.0, 1.0);
}

class RecommendedPlaceSummaryData {
  const RecommendedPlaceSummaryData({
    required this.name,
    required this.category,
    required this.placeholderMood,
    this.distance,
  });

  final String name;
  final String category;

  /// 현재 위치를 확인할 수 없으면(예: 위치 권한 미허용) null.
  final String? distance;
  final PlacePlaceholderMood placeholderMood;
}

enum PlacePlaceholderMood { stream, wall, forest }
