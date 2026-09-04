import 'package:chaerok/data/models/o_auth_login_request.dart';

enum UserRole {
  user,
  admin;

  static UserRole fromJson(String value) => values.byName(value.toLowerCase());
}

class UserResponse {
  const UserResponse({
    required this.id,
    required this.provider,
    required this.nickname,
    required this.email,
    required this.role,
    this.isTester = false,
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as int,
      provider: OAuthProvider.fromJson(json['provider'] as String),
      nickname: json['nickname'] as String,
      email: json['email'] as String?,
      role: UserRole.fromJson(json['role'] as String),
      // 서버가 boolean이 아닌 값(문자열/숫자/누락)을 보내도 예외 없이 false로.
      // 잘못된 파싱으로 예외가 나면 CurrentAccountSync가 setTester를 건너뛰어
      // 이전 테스터 상태가 남을 수 있으므로 방어적으로 처리한다.
      isTester: json['isTester'] == true,
    );
  }

  final int id;
  final OAuthProvider provider;
  final String nickname;
  final String? email;
  final UserRole role;

  /// Play 심사 등에서 실제 이동 없이 인증 흐름을 재현하기 위해 mock 위치를
  /// 허용할지 판단하는 서버 플래그. 서버 응답에 필드가 없으면 false.
  final bool isTester;
}
