import 'dart:typed_data';

import 'package:dio/dio.dart';

/// 백엔드가 발급한 presigned URL로 S3에 원본 JPEG를 PUT한다.
///
/// [DioClient]를 쓰지 않는다 — Authorization 인터셉터가 붙으면 서명이 깨진다.
class S3PutClient {
  S3PutClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 60),
              receiveTimeout: const Duration(seconds: 30),
              followRedirects: false,
            ),
          );

  final Dio _dio;

  /// [requiredHeaders]는 업로드 URL 발급 응답의 값을 그대로 쓴다.
  /// `Host`는 제외한다(Dio/HTTP 클라이언트가 자동 설정).
  Future<void> put({
    required String uploadUrl,
    required Uint8List bytes,
    required Map<String, List<String>> requiredHeaders,
  }) async {
    final headers = <String, dynamic>{};
    var contentType = 'image/jpeg';
    for (final entry in requiredHeaders.entries) {
      if (entry.key.toLowerCase() == 'host') continue;
      final value = entry.value.length == 1 ? entry.value.first : entry.value;
      headers[entry.key] = value;
      if (entry.key.toLowerCase() == 'content-type' && value is String) {
        contentType = value;
      }
    }

    await _dio.put<void>(
      uploadUrl,
      data: bytes,
      options: Options(
        headers: headers,
        contentType: contentType,
        responseType: ResponseType.bytes,
      ),
    );
  }
}
