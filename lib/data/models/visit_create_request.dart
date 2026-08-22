class VisitCreateRequest {
  const VisitCreateRequest({required this.placeId});

  final int placeId;

  Map<String, dynamic> toJson() => {'placeId': placeId};
}
