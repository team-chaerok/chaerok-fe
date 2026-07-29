import 'dart:developer';

import 'package:chaerok/core/config/app_secrets.dart';
import 'package:dio/dio.dart';

/// 좌표를 법정동 기준 행정구역명(시·도/시·군·구)으로 변환한 결과.
typedef AdministrativeRegion = ({String provinceName, String cityCountyName});

/// Kakao Local API를 이용해 좌표를 행정구역명으로 변환하는 서비스.
/// 채록 백엔드(`DioClient`)와 무관한 외부 호스트(`dapi.kakao.com`)를 호출하므로
/// 별도의 Dio 인스턴스를 사용한다.
class KakaoLocalApiService {
  const KakaoLocalApiService._();

  static const _tag = 'KakaoLocalApiService';
  static const _legalDongRegionType = 'B';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://dapi.kakao.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Authorization': 'KakaoAK ${AppSecrets.kakaoRestApiKey}'},
    ),
  );

  /// 좌표(위도/경도)를 법정동 기준 행정구역명으로 변환합니다.
  /// 조회 실패 시 null을 반환합니다.
  static Future<AdministrativeRegion?> resolveAdministrativeRegion({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/v2/local/geo/coord2regioncode.json',
        queryParameters: {'x': longitude, 'y': latitude},
      );

      final documents = response.data?['documents'] as List<dynamic>?;
      if (documents == null) return null;

      Map<String, dynamic>? legalDong;
      for (final doc in documents.cast<Map<String, dynamic>>()) {
        if (doc['region_type'] == _legalDongRegionType) {
          legalDong = doc;
          break;
        }
      }
      if (legalDong == null) return null;

      final provinceName = legalDong['region_1depth_name'] as String?;
      final cityCountyName = legalDong['region_2depth_name'] as String?;
      if (provinceName == null ||
          provinceName.isEmpty ||
          cityCountyName == null ||
          cityCountyName.isEmpty) {
        return null;
      }

      return (provinceName: provinceName, cityCountyName: cityCountyName);
    } catch (e, st) {
      log('좌표→행정구역 변환 실패', name: _tag, error: e, stackTrace: st);
      return null;
    }
  }
}
