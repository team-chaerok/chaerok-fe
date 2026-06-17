import 'dart:developer';

import 'package:google_sign_in/google_sign_in.dart';

class GoogleAuthService {
  static const _tag = 'GoogleAuthService';

  Future<GoogleSignInAccount> signIn() async {
    log('구글 로그인 시도', name: _tag);

    try {
      final account = await GoogleSignIn.instance.authenticate();
      log('구글 로그인 성공 - email: ${account.email}', name: _tag);
      return account;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        log('사용자가 구글 로그인 취소', name: _tag);
      } else {
        log('구글 로그인 실패 - code: ${e.code}', name: _tag, error: e);
      }
      rethrow;
    }
  }
}
