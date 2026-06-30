import 'package:chaerok/core/network/dio_client.dart';
import 'package:chaerok/data/models/o_auth_login_request.dart';
import 'package:chaerok/data/models/o_auth_login_response.dart';
import 'package:chaerok/data/models/refresh_token_request.dart';
import 'package:chaerok/data/models/signup_request.dart';
import 'package:chaerok/data/models/token_response.dart';

/// AuthApi 클래스는 인증 관련 API 호출을 제공합니다.
class AuthApi {
  const AuthApi._();

  /// [회원가입] API 호출
  /// Signup Token과 약관 동의 정보를 검증한 뒤 신규 사용자를 생성하고 Access Token과 Refresh Token을 발급합니다.
  static Future<TokenResponse> signUp(SignupRequest request) async {
    final response = await DioClient.instance.post<TokenResponse>(
      '/api/auth/signup',
      data: request.toJson(),
      fromJson: (data) => TokenResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? TokenResponse.empty();
  }

  /// [Refresh Token을 사용하여 Access Token을 갱신하는] API 호출
  /// 유효한 Refresh Token을 검증하고 새로운 Access Token과 Refresh Token을 발급합니다.
  static Future<TokenResponse> getRefreshToken(
    RefreshTokenRequest request,
  ) async {
    final response = await DioClient.instance.post<TokenResponse>(
      '/api/auth/refresh',
      data: {'refreshToken': request.refreshToken},
      fromJson: (data) => TokenResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? TokenResponse.empty();
  }

  /// [Refresh Token을 사용하여 로그아웃]하는 API 호출
  /// 전달받은 Refresh Token을 폐기해 로그아웃 처리합니다.
  static Future<void> logout(RefreshTokenRequest request) async {
    await DioClient.instance.post<void>(
      '/api/auth/logout',
      data: {'refreshToken': request.refreshToken},
    );
  }

  /// [OAuth 로그인] API 호출
  /// 카카오 또는 구글 ID Token을 검증합니다.
  /// 기존 회원은 Access Token과 Refresh Token을 발급하고, 신규 회원은 회원가입에 사용할 Signup Token을 반환합니다.
  static Future<OAuthLoginResponse> login(OAuthLoginRequest request) async {
    final response = await DioClient.instance.post<OAuthLoginResponse>(
      '/api/auth/login',
      data: request.toJson(),
      fromJson: (data) =>
          OAuthLoginResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? OAuthLoginResponse.empty();
  }
}
