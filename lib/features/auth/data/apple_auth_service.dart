import 'dart:convert';
import 'dart:developer';

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Apple 로그인 결과. [idToken]은 백엔드로 전달할 Apple ID Token(JWT),
/// [hashedNonce]는 Apple SDK에 전달했던 SHA256(raw nonce) 해시값이다.
///
/// 백엔드는 이 값을 추가로 해싱하지 않고 ID Token의 nonce claim과 문자열
/// 그대로 비교한다. raw nonce를 보내면 claim(해시값)과 불일치해 401이
/// 발생함을 실기기 검증으로 확인했다(2026-09-02).
typedef AppleSignInResult = ({String idToken, String hashedNonce});

class AppleAuthService {
  static const _tag = 'AppleAuthService';

  Future<AppleSignInResult> signIn() async {
    log('애플 로그인 시도', name: _tag);

    final rawNonce = generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('애플 identityToken이 없습니다.');
      }

      log('애플 로그인 성공', name: _tag);
      return (idToken: idToken, hashedNonce: hashedNonce);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        log('사용자가 애플 로그인 취소', name: _tag);
      } else {
        log('애플 로그인 실패 - code: ${e.code}', name: _tag, error: e);
      }
      rethrow;
    }
  }

  String _sha256ofString(String input) =>
      sha256.convert(utf8.encode(input)).toString();
}
