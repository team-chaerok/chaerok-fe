enum OAuthProvider {
  kakao,
  google;

  String toJson() => name.toUpperCase();

  static OAuthProvider fromJson(String value) =>
      values.byName(value.toLowerCase());
}

class OAuthLoginRequest {
  const OAuthLoginRequest({required this.provider, required this.idToken});

  final OAuthProvider provider;
  final String idToken;

  Map<String, dynamic> toJson() => {
    'provider': provider.toJson(),
    'idToken': idToken,
  };
}
