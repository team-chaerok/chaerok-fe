import 'dart:developer';

import 'package:chaerok/core/config/app_secrets.dart';
import 'package:chaerok/features/home/data/kma_grid_converter.dart';
import 'package:chaerok/features/home/data/kma_weather_result.dart';
import 'package:dio/dio.dart';

/// 기상청 공공데이터 단기예보 API(초단기예보)를 이용해 현재 위치의 날씨를
/// 조회하는 서비스. 채록 백엔드(`DioClient`)와 무관한 외부 호스트를
/// 호출하므로 `KakaoLocalApiService`와 동일하게 별도 Dio 인스턴스를 사용한다.
class WeatherApiService {
  const WeatherApiService._();

  static const _tag = 'WeatherApiService';

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  /// 좌표(위도/경도)를 기준으로 가장 가까운 예보 시각의 날씨를 조회합니다.
  /// 조회 실패 시 null을 반환합니다.
  static Future<KmaWeatherResult?> getCurrentWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final grid = KmaGridConverter.toGrid(
        latitude: latitude,
        longitude: longitude,
      );
      final baseDateTime = _resolveBaseDateTime(DateTime.now());

      final response = await _dio.get<Map<String, dynamic>>(
        '/getUltraSrtFcst',
        queryParameters: {
          'serviceKey': AppSecrets.kmaServiceKey,
          'pageNo': 1,
          'numOfRows': 60,
          'dataType': 'JSON',
          'base_date': baseDateTime.baseDate,
          'base_time': baseDateTime.baseTime,
          'nx': grid.nx,
          'ny': grid.ny,
        },
      );

      final items =
          response.data?['response']?['body']?['items']?['item']
              as List<dynamic>?;
      if (items == null) return null;

      return KmaWeatherResult.fromForecastItems(
        items.cast<Map<String, dynamic>>(),
      );
    } catch (e, st) {
      log('날씨 조회 실패', name: _tag, error: e, stackTrace: st);
      return null;
    }
  }

  /// 초단기예보는 매시 30분에 생성되어 약 10~15분 뒤 제공된다.
  /// 아직 이번 시간대 발표값이 제공되지 않았을 시각(45분 이전)이면
  /// 직전 시간대의 발표값을 사용한다.
  static ({String baseDate, String baseTime}) _resolveBaseDateTime(
    DateTime now,
  ) {
    final effective = now.minute < 45
        ? now.subtract(const Duration(hours: 1))
        : now;

    final baseDate =
        '${effective.year.toString().padLeft(4, '0')}'
        '${effective.month.toString().padLeft(2, '0')}'
        '${effective.day.toString().padLeft(2, '0')}';
    final baseTime = '${effective.hour.toString().padLeft(2, '0')}30';
    return (baseDate: baseDate, baseTime: baseTime);
  }
}
