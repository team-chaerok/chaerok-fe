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
  });

  factory UserResponse.fromJson(Map<String, dynamic> json) {
    return UserResponse(
      id: json['id'] as int,
      provider: OAuthProvider.fromJson(json['provider'] as String),
      nickname: json['nickname'] as String,
      email: json['email'] as String,
      role: UserRole.fromJson(json['role'] as String),
    );
  }

  final int id;
  final OAuthProvider provider;
  final String nickname;
  final String email;
  final UserRole role;
}
