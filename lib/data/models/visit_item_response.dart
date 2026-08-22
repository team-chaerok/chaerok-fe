class VisitItemResponse {
  const VisitItemResponse({
    required this.visitId,
    required this.placeId,
    required this.placeName,
    required this.categoryGroup,
    required this.visitedAt,
  });

  factory VisitItemResponse.fromJson(Map<String, dynamic> json) {
    return VisitItemResponse(
      visitId: json['visitId'] as int,
      placeId: json['placeId'] as int,
      placeName: json['placeName'] as String,
      categoryGroup: json['categoryGroup'] as String,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
    );
  }

  final int visitId;
  final int placeId;
  final String placeName;
  final String categoryGroup;
  final DateTime visitedAt;
}
