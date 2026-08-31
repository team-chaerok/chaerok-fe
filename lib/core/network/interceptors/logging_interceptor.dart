import 'dart:developer';

import 'package:dio/dio.dart';

/// LoggingInterceptor 클래스는 Dio 클라이언트의 요청, 응답 및 오류를 로깅하는 인터셉터입니다.
class LoggingInterceptor extends Interceptor {
  static const _tag = 'DioClient';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log(
      '[REQUEST]\n'
      '  Method : ${options.method}\n'
      '  URI    : ${options.uri}\n'
      '  Body   : ${options.data}',
      name: _tag,
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log(
      '[RESPONSE]\n'
      '  Status : ${response.statusCode}\n'
      '  Path   : ${response.requestOptions.path}\n'
      '  Data   : ${response.data}',
      name: _tag,
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log(
      '[ERROR]\n'
      '  Status : ${err.response?.statusCode ?? '-'}\n'
      '  URI    : ${err.requestOptions.uri}\n'
      '  Message: ${err.message}\n'
      '  Data   : ${err.response?.data}',
      name: _tag,
      error: err,
    );
    handler.next(err);
  }
}
