import 'package:dio/dio.dart';

/// API 호출 중 발생한 예외에서 사용자에게 보여줄 에러 메시지를 추출합니다.
String apiErrorMessage(Object error) {
  if (error is DioException && error.error is ApiError) {
    return (error.error as ApiError).toString();
  }
  return error.toString();
}

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
