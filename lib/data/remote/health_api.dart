import 'package:chaerok/core/network/dio_client.dart';

/// HealthApi 클래스는 서버의 상태를 확인하는 API를 제공합니다.
class HealthApi {
  const HealthApi._();

  /// 서버 상태를 확인하는 API 호출
  static Future<String> checkHealth() async {
    final response = await DioClient.instance.get<String>(
      '/api/health',
      fromJson: (data) => data.toString(),
    );
    return response.data ?? '';
  }
}
