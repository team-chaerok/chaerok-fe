import 'package:chaerok/core/network/dio_client.dart';

/// UsersApi 클래스는 사용자 리소스 관련 API 호출을 제공합니다.
class UsersApi {
  const UsersApi._();

  /// [회원탈퇴] API 호출
  /// 인증된 사용자의 계정과 인증 관련 데이터를 삭제합니다.
  static Future<void> withdraw() async {
    await DioClient.instance.delete<void>('/api/users/me');
  }
}
