import 'package:dio/dio.dart';

import '../../../data/models/api_error.dart';

/// Dio 요청 중 발생한 오류를 ApiError로 변환하는 인터셉터
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final apiError = _toApiError(err);
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: apiError,
        type: err.type,
        response: err.response,
      ),
    );
  }

  /// DioException을 ApiError로 변환
  ApiError _toApiError(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiError(statusCode: 408, message: '요청 시간이 초과되었습니다.');
      case DioExceptionType.connectionError:
        return const ApiError(statusCode: 0, message: '네트워크 연결을 확인해주세요.');
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode ?? 0;
        final data = err.response?.data;
        if (data is Map<String, dynamic>) {
          return ApiError.fromJson(data, statusCode);
        }
        return ApiError(
          statusCode: statusCode,
          message: _statusMessage(statusCode),
        );
      default:
        return const ApiError(statusCode: 0, message: '알 수 없는 오류가 발생했습니다.');
    }
  }

  /// HTTP 상태 코드에 따른 기본 오류 메시지 반환
  String _statusMessage(int statusCode) {
    return switch (statusCode) {
      400 => '잘못된 요청입니다.',
      401 => '인증이 필요합니다.',
      403 => '접근 권한이 없습니다.',
      404 => '요청한 리소스를 찾을 수 없습니다.',
      500 => '서버 오류가 발생했습니다.',
      _ => '오류가 발생했습니다. ($statusCode)',
    };
  }
}
