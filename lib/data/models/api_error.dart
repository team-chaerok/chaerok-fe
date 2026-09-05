import 'package:dio/dio.dart';

/// API 호출 중 발생한 예외에서 사용자에게 보여줄 에러 메시지를 추출합니다.
String apiErrorMessage(Object error) {
  if (error is DioException && error.error is ApiError) {
    return (error.error as ApiError).message;
  }
  return error.toString();
}

/// ApiError 모델은 API 요청 중 발생한 오류를 나타내는 클래스입니다.
class ApiError implements Exception {
  const ApiError({
    required this.statusCode,
    required this.message,
    this.errorCode,
    this.fields = const [],
  });

  factory ApiError.fromJson(Map<String, dynamic> json, int statusCode) {
    final rawErrors = json['errors'];
    final fields = <String>[
      if (rawErrors is List)
        for (final e in rawErrors)
          if (e is Map<String, dynamic> && e['field'] is String)
            e['field'] as String,
    ];
    return ApiError(
      statusCode: statusCode,
      message: json['message'] as String? ?? '알 수 없는 오류가 발생했습니다.',
      // 서버는 상단 에러 코드를 `errorCode` 또는 `code`로 내려준다.
      errorCode: json['errorCode'] as String? ?? json['code'] as String?,
      fields: fields,
    );
  }

  final int statusCode;
  final String message;
  final String? errorCode;

  /// 검증 실패(`errors: [{field, message}]`) 시 문제가 된 요청 필드 이름 목록.
  final List<String> fields;

  @override
  String toString() => 'ApiError($statusCode): $message';
}
