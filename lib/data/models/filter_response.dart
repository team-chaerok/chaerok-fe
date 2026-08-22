class FilterResponse {
  const FilterResponse({
    required this.filterId,
    required this.name,
    required this.description,
  });

  factory FilterResponse.fromJson(Map<String, dynamic> json) {
    return FilterResponse(
      filterId: json['filterId'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
    );
  }

  final String filterId;
  final String name;
  final String description;
}
