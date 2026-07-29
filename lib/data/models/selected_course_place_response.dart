class SelectedCoursePlaceResponse {
  const SelectedCoursePlaceResponse({
    required this.placeId,
    required this.source,
    required this.title,
    required this.categoryGroup,
    required this.address,
    required this.sequence,
    this.categoryDetail,
  });

  factory SelectedCoursePlaceResponse.fromJson(Map<String, dynamic> json) {
    return SelectedCoursePlaceResponse(
      placeId: json['placeId'] as int,
      source: json['source'] as String,
      title: json['title'] as String,
      categoryGroup: json['categoryGroup'] as String,
      categoryDetail: json['categoryDetail'] as String?,
      address: json['address'] as String,
      sequence: json['sequence'] as int,
    );
  }

  final int placeId;
  final String source;
  final String title;
  final String categoryGroup;
  final String? categoryDetail;
  final String address;
  final int sequence;
}
