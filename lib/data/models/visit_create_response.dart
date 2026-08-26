class VisitCreateResponse {
  const VisitCreateResponse({
    required this.visitId,
    required this.filmRollId,
    required this.placeId,
    required this.placeName,
    required this.categoryGroup,
    required this.visitedCategoryCount,
    required this.requiredCategoryCount,
    required this.visitRequirementMet,
    required this.visitedAt,
  });

  factory VisitCreateResponse.fromJson(Map<String, dynamic> json) {
    return VisitCreateResponse(
      visitId: json['visitId'] as int,
      filmRollId: json['filmRollId'] as int,
      placeId: json['placeId'] as int,
      placeName: json['placeName'] as String,
      categoryGroup: json['categoryGroup'] as String,
      visitedCategoryCount: json['visitedCategoryCount'] as int,
      requiredCategoryCount: json['requiredCategoryCount'] as int,
      visitRequirementMet: json['visitRequirementMet'] as bool,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
    );
  }

  factory VisitCreateResponse.empty() {
    return VisitCreateResponse(
      visitId: 0,
      filmRollId: 0,
      placeId: 0,
      placeName: '',
      categoryGroup: '',
      visitedCategoryCount: 0,
      requiredCategoryCount: 0,
      visitRequirementMet: false,
      visitedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final int visitId;
  final int filmRollId;
  final int placeId;
  final String placeName;
  final String categoryGroup;
  final int visitedCategoryCount;
  final int requiredCategoryCount;
  final bool visitRequirementMet;
  final DateTime visitedAt;
}
