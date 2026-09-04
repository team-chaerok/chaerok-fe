import 'dart:convert';

import 'package:chaerok/data/models/o_auth_login_request.dart';
import 'package:chaerok/data/models/user_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> baseJson() =>
      jsonDecode('''
    {
      "id": 1,
      "provider": "KAKAO",
      "nickname": "채록",
      "email": "chaerok@example.com",
      "role": "USER"
    }
    ''')
          as Map<String, dynamic>;

  test('기본 필드를 정상 파싱한다', () {
    final result = UserResponse.fromJson(baseJson());

    expect(result.id, 1);
    expect(result.provider, OAuthProvider.kakao);
    expect(result.nickname, '채록');
    expect(result.email, 'chaerok@example.com');
    expect(result.role, UserRole.user);
  });

  test('isTester 필드가 없으면 false로 파싱한다', () {
    final result = UserResponse.fromJson(baseJson());

    expect(result.isTester, false);
  });

  test('isTester 필드가 null이면 false로 파싱한다', () {
    final json = baseJson()..['isTester'] = null;

    expect(UserResponse.fromJson(json).isTester, false);
  });

  test('isTester 필드가 true면 true로 파싱한다', () {
    final json = baseJson()..['isTester'] = true;

    expect(UserResponse.fromJson(json).isTester, true);
  });

  test('isTester 필드가 boolean이 아닌 값이면 예외 없이 false로 파싱한다', () {
    for (final invalid in <Object>['true', 1, 'TESTER', 0]) {
      final json = baseJson()..['isTester'] = invalid;

      expect(
        UserResponse.fromJson(json).isTester,
        false,
        reason: '$invalid (${invalid.runtimeType})',
      );
    }
  });
}
