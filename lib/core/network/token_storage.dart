import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/app_secrets.dart';
import 'session_status.dart';

export 'session_status.dart';

const _keyAccessToken = 'access_token';
const _keyRefreshToken = 'refresh_token';

/// accessToken/refreshToken을 안전 저장소에 저장·조회·삭제하는 공용 서비스.
class TokenStorage {
  TokenStorage._({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            // first_unlock: 기기 재시작 후 첫 잠금 해제 시점부터 접근 허용 (백그라운드 토큰 갱신 지원)
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  static TokenStorage? _instance;

  static TokenStorage get instance => _instance ??= TokenStorage._();

  final FlutterSecureStorage _storage;

  /// 로그인 여부를 구독 가능한 형태로 노출. saveTokens/clear 호출 시 자동 갱신됨.
  final ValueNotifier<bool> isLoggedIn = ValueNotifier(false);

  Future<String?> getAccessToken() => _readSafely(_keyAccessToken);

  Future<String?> getRefreshToken() => _readSafely(_keyRefreshToken);

  /// 토큰 저장에 성공하면 true, 저장소 오류로 실패하면 false를 반환한다.
  Future<bool> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      await _storage.write(key: _keyRefreshToken, value: refreshToken);
      isLoggedIn.value = true;
      return true;
    } on PlatformException {
      await _clearSilently();
      return false;
    }
  }

  /// 저장된 토큰을 모두 삭제하고 isLoggedIn 상태를 false로 갱신한다.
  Future<void> clear() async {
    await _clearSilently();
  }

  /// refresh token으로 실제 갱신을 시도해 세션 유효성을 검증한다.
  ///
  /// [dio]는 AuthInterceptor가 붙지 않은 순수 Dio 인스턴스여야 한다. 인터셉터가
  /// 붙은 인스턴스를 넘기면 refresh 요청이 401을 받았을 때 AuthInterceptor가
  /// 다시 자체적으로 refresh를 시도해 이중 처리가 된다.
  Future<SessionStatus> resolveSession(Dio dio) async {
    final refreshToken = await getRefreshToken();
    if (refreshToken == null) {
      return SessionStatus.unauthenticated;
    }

    try {
      final response = await dio.post(
        '${AppSecrets.baseUrl}/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['accessToken'] as String?;
      final newRefreshToken = response.data['refreshToken'] as String?;
      if (newAccessToken == null ||
          newAccessToken.isEmpty ||
          newRefreshToken == null ||
          newRefreshToken.isEmpty) {
        await clear();
        return SessionStatus.unauthenticated;
      }

      final saved = await saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return saved
          ? SessionStatus.authenticated
          : SessionStatus.unauthenticated;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        await clear();
        return SessionStatus.unauthenticated;
      }
      return SessionStatus.networkError;
    } catch (_) {
      return SessionStatus.networkError;
    }
  }

  // 저장소 읽기 실패(예: Android 키스토어 손상으로 인한 BAD_DECRYPT) 시
  // 저장소를 정리하고 null을 반환해 호출부가 재로그인 흐름으로 넘어가게 한다.
  // 네이티브 플랫폼 채널 호출이 예외 없이 멈추는 기기 환경도 있어(알려진
  // flutter_secure_storage 이슈), 그 경우까지 대비해 읽기에 타임아웃을 둔다.
  Future<String?> _readSafely(String key) async {
    try {
      return await _storage
          .read(key: key)
          .timeout(const Duration(seconds: 10), onTimeout: () => null);
    } on PlatformException {
      await _clearSilently();
      return null;
    }
  }

  Future<void> _clearSilently() async {
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
    } on PlatformException {
      // 삭제 자체가 실패해도 로그인 상태만은 확실히 false로 맞춘다.
    }
    isLoggedIn.value = false;
  }
}
