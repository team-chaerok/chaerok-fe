/// resolveSession()이 판정한 세션 상태.
enum SessionStatus {
  /// refresh에 성공해 유효한 세션이 확인됨
  authenticated,

  /// 토큰이 없거나 refresh token이 만료/무효함
  unauthenticated,

  /// 네트워크 문제로 세션 유효성을 확인하지 못함 (토큰은 유지)
  networkError,
}
