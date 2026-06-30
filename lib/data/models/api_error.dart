/// ApiError 모델은 API 요청 중 발생한 오류를 나타내는 클래스입니다.
class ApiError implements Exception {
  const ApiError({
    required this.statusCode,
    required this.message,
    this.errorCode,
  });

  factory ApiError.fromJson(Map<String, dynamic> json, int statusCode) {
    return ApiError(
      statusCode: statusCode,
      message: json['message'] as String? ?? '알 수 없는 오류가 발생했습니다.',
      errorCode: json['errorCode'] as String?,
    );
  }

  final int statusCode;
  final String message;
  final String? errorCode;

  @override
  String toString() => 'ApiError($statusCode): $message';
}
