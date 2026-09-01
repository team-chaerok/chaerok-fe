import 'package:chaerok/data/models/o_auth_login_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OAuthProvider', () {
    test('toJson은 대문자 provider 이름을 반환한다', () {
      expect(OAuthProvider.kakao.toJson(), 'KAKAO');
      expect(OAuthProvider.google.toJson(), 'GOOGLE');
      expect(OAuthProvider.apple.toJson(), 'APPLE');
    });

    test('fromJson은 대문자 문자열을 enum으로 되돌린다', () {
      expect(OAuthProvider.fromJson('KAKAO'), OAuthProvider.kakao);
      expect(OAuthProvider.fromJson('GOOGLE'), OAuthProvider.google);
      expect(OAuthProvider.fromJson('APPLE'), OAuthProvider.apple);
    });
  });

  group('OAuthLoginRequest.toJson', () {
    test('Apple 요청은 nonce(해시값)를 포함한다', () {
      final json = const OAuthLoginRequest(
        provider: OAuthProvider.apple,
        idToken: 'apple-id-token',
        nonce: 'hashed-nonce',
      ).toJson();

      expect(json, {
        'provider': 'APPLE',
        'idToken': 'apple-id-token',
        'nonce': 'hashed-nonce',
      });
    });

    test('nonce가 없으면 nonce 키를 직렬화하지 않는다', () {
      final json = const OAuthLoginRequest(
        provider: OAuthProvider.kakao,
        idToken: 'kakao-id-token',
      ).toJson();

      expect(json, {'provider': 'KAKAO', 'idToken': 'kakao-id-token'});
      expect(json.containsKey('nonce'), isFalse);
    });
  });
}
