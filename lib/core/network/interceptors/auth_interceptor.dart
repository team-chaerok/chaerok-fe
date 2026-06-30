import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../config/app_secrets.dart';

const _keyAccessToken = 'access_token';
const _keyRefreshToken = 'refresh_token';
// 재시도 요청임을 표시해 401 무한 루프 방지
const _extraRetried = '_retried';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required FlutterSecureStorage storage,
    required Dio dio,
    this.onUnauthorized,
  }) : _storage = storage,
       _dio = dio;

  final FlutterSecureStorage _storage;
  final Dio _dio;
  final void Function()? onUnauthorized;

  bool _isRefreshing = false;
  // 동시에 여러 요청이 401을 받았을 때 refresh를 1번만 호출하고 나머지는 대기
  Completer<String?>? _refreshCompleter;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: _keyAccessToken);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
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

  Future<String?> _refreshAccessToken() async {
    if (_isRefreshing) {
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await _storage.read(key: _keyRefreshToken);
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
      if (newAccessToken != null) {
        await _storage.write(key: _keyAccessToken, value: newAccessToken);
      }

      _complete(newAccessToken);
      return newAccessToken;
    } catch (_) {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
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
