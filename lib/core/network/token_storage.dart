import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

  Future<String?> getAccessToken() => _storage.read(key: _keyAccessToken);

  Future<String?> getRefreshToken() => _storage.read(key: _keyRefreshToken);

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
    await _storage.write(key: _keyRefreshToken, value: refreshToken);
    isLoggedIn.value = true;
  }

  /// 토큰 재발급(refresh) 시 accessToken만 갱신한다.
  Future<void> saveAccessToken(String accessToken) async {
    await _storage.write(key: _keyAccessToken, value: accessToken);
  }

  Future<void> clear() async {
    await _storage.delete(key: _keyAccessToken);
    await _storage.delete(key: _keyRefreshToken);
    isLoggedIn.value = false;
  }
}
