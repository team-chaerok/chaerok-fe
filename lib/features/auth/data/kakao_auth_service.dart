import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class KakaoAuthService {
  static const _tag = 'KakaoAuthService';

  Future<OAuthToken> signIn() async {
    final kakaoTalkInstalled = await isKakaoTalkInstalled();
    log('카카오톡 설치 여부: $kakaoTalkInstalled', name: _tag);

    if (kakaoTalkInstalled) {
      try {
        log('카카오톡 앱으로 로그인 시도', name: _tag);
        final token = await UserApi.instance.loginWithKakaoTalk();
        log('카카오톡으로 로그인 성공 - accessToken: ${token.accessToken}', name: _tag);
        return token;
      } catch (e) {
        log('카카오톡으로 로그인 실패', name: _tag, error: e);

        // 사용자가 권한 요청 화면에서 취소한 경우 → 로그인 취소로 처리
        if (e is PlatformException && e.code == 'CANCELED') {
          log('사용자가 카카오톡 로그인 취소', name: _tag);
          rethrow;
        }

        // 카카오톡에 연결된 카카오계정이 없는 경우 → 카카오계정으로 폴백
      }
    }

    try {
      log('카카오 계정으로 로그인 시도', name: _tag);
      final token = await UserApi.instance.loginWithKakaoAccount();
      log('카카오계정으로 로그인 성공 - accessToken: ${token.accessToken}', name: _tag);
      return token;
    } catch (e) {
      log('카카오계정으로 로그인 실패', name: _tag, error: e);
      rethrow;
    }
  }
}
