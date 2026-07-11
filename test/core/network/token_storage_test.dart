import 'dart:typed_data';

import 'package:chaerok/core/config/app_secrets.dart';
import 'package:chaerok/core/network/token_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

/// TokenStorage의 resolveSession 메서드를 테스트하는 단위 테스트
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) => _handler(options);

  @override
  void close({bool force = false}) {}
}

Dio _dioReturning(Future<ResponseBody> Function(RequestOptions) handler) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
  dio.httpClientAdapter = _FakeAdapter(handler);
  return dio;
}

void main() {
  setUp(() {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform({
      'refresh_token': 'old-refresh-token',
    });
  });

  test('AuthApi와 동일한 /api/auth/refresh 엔드포인트로 요청한다', () async {
    String? requestedPath;
    final dio = _dioReturning((options) async {
      requestedPath = options.path;
      return ResponseBody.fromString(
        '{"accessToken":"new-access","refreshToken":"new-refresh"}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    });

    await TokenStorage.instance.resolveSession(dio);

    expect(requestedPath, '${AppSecrets.baseUrl}/api/auth/refresh');
  });

  test('갱신에 성공하면 authenticated를 반환하고 회전된 토큰을 저장한다', () async {
    final dio = _dioReturning(
      (options) async => ResponseBody.fromString(
        '{"accessToken":"new-access","refreshToken":"new-refresh"}',
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      ),
    );

    final status = await TokenStorage.instance.resolveSession(dio);

    expect(status, SessionStatus.authenticated);
    expect(await TokenStorage.instance.getAccessToken(), 'new-access');
    expect(await TokenStorage.instance.getRefreshToken(), 'new-refresh');
  });

  test('서버가 401을 응답하면 unauthenticated를 반환하고 토큰을 삭제한다', () async {
    final dio = _dioReturning(
      (options) async => ResponseBody.fromString('{"message":"invalid"}', 401),
    );

    final status = await TokenStorage.instance.resolveSession(dio);

    expect(status, SessionStatus.unauthenticated);
    expect(await TokenStorage.instance.getRefreshToken(), isNull);
  });

  test('연결에 실패하면 networkError를 반환하고 토큰을 유지한다', () async {
    final dio = _dioReturning(
      (options) async => throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
      ),
    );

    final status = await TokenStorage.instance.resolveSession(dio);

    expect(status, SessionStatus.networkError);
    expect(await TokenStorage.instance.getRefreshToken(), 'old-refresh-token');
  });

  test('저장된 refresh token이 없으면 요청 없이 unauthenticated를 반환한다', () async {
    FlutterSecureStoragePlatform.instance = TestFlutterSecureStoragePlatform(
      {},
    );
    final dio = _dioReturning((options) async {
      fail('refresh token이 없으면 네트워크 요청을 보내면 안 된다');
    });

    final status = await TokenStorage.instance.resolveSession(dio);

    expect(status, SessionStatus.unauthenticated);
  });
}
