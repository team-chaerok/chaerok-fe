/// ApiResponse 모델은 API 요청에 대한 응답을 나타내는 클래스입니다.
class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.message,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    int statusCode, {
    T Function(dynamic)? fromJson,
  }) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? true, // 백엔드 스펙 미확정 시 기본 성공으로 간주
      statusCode: statusCode,
      data: fromJson != null && json['data'] != null
          ? fromJson(json['data'])
          : null,
      message: json['message'] as String?,
    );
  }

  final bool success;
  final int statusCode;
  final T? data;
  final String? message;
}
