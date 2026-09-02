import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/api_response.dart';
import '../config/app_secrets.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/logging_interceptor.dart';
import 'token_storage.dart';

/// 앱 전체에서 공유되는 Dio HTTP 클라이언트 싱글톤.
/// 로그아웃 처리가 필요하면 main.dart에서 [init]으로 초기화할 것.
class DioClient {
  DioClient._({void Function()? onUnauthorized}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppSecrets.baseUrl,

        /// TODO : TIMEOUT 시간 백엔드랑 상의 후 수정
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.addAll([
      AuthInterceptor(
        tokenStorage: TokenStorage.instance,
        dio: _dio,
        onUnauthorized: onUnauthorized,
      ),
      ErrorInterceptor(),
      if (kDebugMode) LoggingInterceptor(),
    ]);
  }

  static DioClient? _instance;

  static DioClient get instance {
    _instance ??= DioClient._();
    return _instance!;
  }

  /// 로그아웃 콜백이 필요할 때 앱 시작 시 1회 호출.
  /// 호출하지 않으면 401 만료 후 로그아웃 처리가 동작하지 않음.
  static void init({void Function()? onUnauthorized}) {
    _instance = DioClient._(onUnauthorized: onUnauthorized);
  }

  late final Dio _dio;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.get(path, queryParameters: queryParameters);
    return _toApiResponse(response, fromJson);
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    ResponseType? responseType,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: responseType != null
          ? Options(responseType: responseType)
          : null,
    );
    return _toApiResponse(response, fromJson);
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.put(path, data: data);
    return _toApiResponse(response, fromJson);
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.patch(path, data: data);
    return _toApiResponse(response, fromJson);
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    final response = await _dio.delete(path, data: data);
    return _toApiResponse(response, fromJson);
  }

  ApiResponse<T> _toApiResponse<T>(
    Response response,
    T Function(dynamic)? fromJson,
  ) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ApiResponse.fromJson(
        data,
        response.statusCode ?? 200,
        fromJson: fromJson,
      );
    }
    return ApiResponse<T>(
      success: true,
      statusCode: response.statusCode ?? 200,
      data: fromJson != null && data != null ? fromJson(data) : null,
    );
  }
}
