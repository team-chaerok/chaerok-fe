import 'package:chaerok/core/network/dio_client.dart';
import 'package:chaerok/data/models/region_response.dart';
import 'package:chaerok/data/models/resolve_region_request.dart';

/// RegionsApi 클래스는 지역(Region) 검증 관련 API 호출을 제공합니다.
class RegionsApi {
  const RegionsApi._();

  /// [현재 지역 검증] API 호출
  /// 시·도명, 시·군·구명을 기준으로 채록 서비스 대상 지역 여부를 검증합니다.
  static Future<RegionResponse> resolveRegion(
    ResolveRegionRequest request,
  ) async {
    final response = await DioClient.instance.post<RegionResponse>(
      '/api/regions/resolve',
      data: request.toJson(),
      fromJson: (data) => RegionResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data!;
  }
}
