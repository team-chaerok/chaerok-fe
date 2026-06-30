class TokenResponse {
  const TokenResponse({required this.accessToken, required this.refreshToken});

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  factory TokenResponse.empty() {
    return const TokenResponse(accessToken: '', refreshToken: '');
  }

  final String accessToken;
  final String refreshToken;
}
