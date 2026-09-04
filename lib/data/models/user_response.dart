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
      isTester: json['isTester'] as bool? ?? false,
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
