import 'package:chaerok/core/network/dio_client.dart';
import 'package:chaerok/data/models/update_nickname_request.dart';
import 'package:chaerok/data/models/user_response.dart';

/// UsersApi 클래스는 사용자 리소스 관련 API 호출을 제공합니다.
class UsersApi {
  const UsersApi._();

  /// [내 정보 조회] API 호출
  /// 인증된 사용자의 기본 정보를 조회합니다.
  static Future<UserResponse> getMyInformation() async {
    final response = await DioClient.instance.get<UserResponse>(
      '/api/users/me',
      fromJson: (data) => UserResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  /// [닉네임 수정] API 호출
  /// 인증된 사용자의 닉네임을 수정하고 변경된 사용자 정보를 반환합니다.
  static Future<UserResponse> updateNickname(
    UpdateNicknameRequest request,
  ) async {
    final response = await DioClient.instance.patch<UserResponse>(
      '/api/users/me/nickname',
      data: request.toJson(),
      fromJson: (data) => UserResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }

  /// [회원탈퇴] API 호출
  /// 인증된 사용자의 계정과 인증 관련 데이터를 삭제합니다.
  static Future<void> withdraw() async {
    await DioClient.instance.delete<void>('/api/users/me');
  }
}
