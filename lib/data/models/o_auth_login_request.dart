enum OAuthProvider {
  kakao,
  google,
  apple;

  String toJson() => name.toUpperCase();

  static OAuthProvider fromJson(String value) =>
      values.byName(value.toLowerCase());
}

class OAuthLoginRequest {
  const OAuthLoginRequest({
    required this.provider,
    required this.idToken,
    this.nonce,
  });

  final OAuthProvider provider;
  final String idToken;

  /// Apple 로그인 시 재생공격 방지를 위한 nonce. Apple SDK(`getAppleIDCredential`)에
  /// 전달했던 SHA256 해시값을 그대로 보낸다 — 백엔드가 추가로 해싱하지 않고
  /// ID Token의 nonce claim과 문자열 그대로 비교하기 때문(실기기 검증으로 확인,
  /// 2026-09-02). 카카오·구글 로그인에서는 사용하지 않아 null이다.
  final String? nonce;

  Map<String, dynamic> toJson() => {
    'provider': provider.toJson(),
    'idToken': idToken,
    if (nonce != null) 'nonce': nonce,
  };
}
