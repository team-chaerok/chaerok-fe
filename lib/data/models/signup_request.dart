class SignupRequest {
  const SignupRequest({
    required this.signupToken,
    required this.nickname,
    required this.termsAgreed,
    required this.privacyAgreed,
  });

  final String signupToken;
  final String nickname;
  final bool termsAgreed;
  final bool privacyAgreed;

  Map<String, dynamic> toJson() => {
    'signupToken': signupToken,
    'nickname': nickname,
    'termsAgreed': termsAgreed,
    'privacyAgreed': privacyAgreed,
  };
}
