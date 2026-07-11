import 'dart:developer';

import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static const _tag = 'GoogleAuthService';

  Future<String> signIn() async {
    log('구글 로그인 시도', name: _tag);

    try {
      final account = await GoogleSignIn.instance.authenticate();
      log('구글 로그인 성공 - email: ${account.email}', name: _tag);

      final auth = account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception('구글 idToken이 null입니다.');
      return idToken;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        log('사용자가 구글 로그인 취소', name: _tag);
      } else {
        log('구글 로그인 실패 - code: ${e.code}', name: _tag, error: e);
      }
      rethrow;
    }
  }

  /// 구글 계정 연동을 해제합니다. 회원탈퇴 시 호출되며,
  /// 실패해도 이미 완료된 탈퇴를 되돌릴 수 없으므로 로그만 남기고 넘어갑니다.
  Future<void> disconnect() async {
    log('구글 계정 연동 해제 시도', name: _tag);
    try {
      await GoogleSignIn.instance.disconnect();
      log('구글 계정 연동 해제 성공', name: _tag);
    } catch (e) {
      log('구글 계정 연동 해제 실패', name: _tag, error: e);
    }
  }
}
