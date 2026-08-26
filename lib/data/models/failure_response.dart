class FailureResponse {
  const FailureResponse({required this.code, required this.message});

  factory FailureResponse.fromJson(Map<String, dynamic> json) {
    return FailureResponse(
      code: json['code'] as String,
      message: json['message'] as String,
    );
  }

  final String code;
  final String message;
}
