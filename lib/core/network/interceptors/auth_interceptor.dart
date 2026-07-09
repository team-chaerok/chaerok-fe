import 'dart:async';

import 'package:dio/dio.dart';

import '../../config/app_secrets.dart';
import '../token_storage.dart';

// 재시도 요청임을 표시해 401 무한 루프 방지
const _extraRetried = '_retried';

/// 인증 토큰을 자동으로 갱신하고 요청을 재시도하는 Dio 인터셉터
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage, // 토큰 저장소
    required Dio dio, // 토큰 갱신 요청을 보내기 위한 Dio 인스턴스
    this.onUnauthorized,
  }) : _tokenStorage = tokenStorage,
       _dio = dio;

  final TokenStorage _tokenStorage;
  final Dio _dio;
  final void Function()? onUnauthorized;

  bool _isRefreshing = false;
  // 동시에 여러 요청이 401을 받았을 때 refresh를 1번만 호출하고 나머지는 대기
  Completer<String?>? _refreshCompleter;

  @override
  // 요청이 보내지기 전에 accessToken을 헤더에 추가
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getAccessToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  // 401 Unauthorized 에러 발생 시 토큰 갱신 후 요청 재시도
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_extraRetried] == true;

    if (!isUnauthorized || alreadyRetried) {
      handler.next(err);
      return;
    }

    final newToken = await _refreshAccessToken();
    if (newToken == null) {
      onUnauthorized?.call();
      handler.next(err);
      return;
    }

    final retryOptions = err.requestOptions
      ..headers['Authorization'] = 'Bearer $newToken'
      ..extra[_extraRetried] = true;

    try {
      final response = await _dio.fetch(retryOptions);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  // 토큰 갱신(refresh) 요청을 보내고 새로운 accessToken을 반환
  Future<String?> _refreshAccessToken() async {
    if (_isRefreshing) {
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await _tokenStorage.getRefreshToken();
      if (refreshToken == null) {
        _complete(null);
        return null;
      }

      final response = await _dio.post(
        '${AppSecrets.baseUrl}/auth/refresh',
        data: {'refreshToken': refreshToken},
        options: Options(extra: {_extraRetried: true}),
      );

      final newAccessToken = response.data['accessToken'] as String?;
      final newRefreshToken = response.data['refreshToken'] as String?;
      if (newAccessToken != null && newRefreshToken != null) {
        await _tokenStorage.saveTokens(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
        );
      }

      _complete(newAccessToken);
      return newAccessToken;
    } catch (_) {
      await _tokenStorage.clear();
      _complete(null);
      return null;
    }
  }

  void _complete(String? token) {
    _refreshCompleter?.complete(token);
    _refreshCompleter = null;
    _isRefreshing = false;
  }
}
