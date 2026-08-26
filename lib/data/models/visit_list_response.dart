import 'package:chaerok/data/models/visit_item_response.dart';

class VisitListResponse {
  const VisitListResponse({
    required this.filmRollId,
    required this.visitedCategoryCount,
    required this.requiredCategoryCount,
    required this.visitRequirementMet,
    required this.visits,
  });

  factory VisitListResponse.fromJson(Map<String, dynamic> json) {
    return VisitListResponse(
      filmRollId: json['filmRollId'] as int,
      visitedCategoryCount: json['visitedCategoryCount'] as int,
      requiredCategoryCount: json['requiredCategoryCount'] as int,
      visitRequirementMet: json['visitRequirementMet'] as bool,
      visits: (json['visits'] as List<dynamic>)
          .map((e) => VisitItemResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory VisitListResponse.empty() {
    return const VisitListResponse(
      filmRollId: 0,
      visitedCategoryCount: 0,
      requiredCategoryCount: 0,
      visitRequirementMet: false,
      visits: [],
    );
  }

  final int filmRollId;
  final int visitedCategoryCount;
  final int requiredCategoryCount;
  final bool visitRequirementMet;
  final List<VisitItemResponse> visits;
}
