import 'package:chaerok/data/models/token_response.dart';

class OAuthLoginResponse {
  const OAuthLoginResponse({
    required this.registered,
    this.tokens,
    this.signupToken,
  });

  factory OAuthLoginResponse.fromJson(Map<String, dynamic> json) {
    final tokensJson = json['tokens'] as Map<String, dynamic>?;
    return OAuthLoginResponse(
      registered: json['registered'] as bool,
      tokens: tokensJson != null ? TokenResponse.fromJson(tokensJson) : null,
      signupToken: json['signupToken'] as String?,
    );
  }

  factory OAuthLoginResponse.empty() {
    return const OAuthLoginResponse(
      registered: false,
      tokens: null,
      signupToken: null,
    );
  }

  final bool registered;
  final TokenResponse? tokens;
  final String? signupToken;
}
