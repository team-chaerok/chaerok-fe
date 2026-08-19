import 'package:chaerok/features/home/data/kma_weather_result.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _item({
  required String category,
  required String fcstTime,
  required String fcstValue,
  String fcstDate = '20260819',
}) {
  return {
    'category': category,
    'fcstDate': fcstDate,
    'fcstTime': fcstTime,
    'fcstValue': fcstValue,
  };
}

void main() {
  test('여러 예보 시각 중 가장 가까운 시각의 값을 카테고리별로 선택한다', () {
    final result = KmaWeatherResult.fromForecastItems([
      _item(category: 'T1H', fcstTime: '1400', fcstValue: '27'),
      _item(category: 'T1H', fcstTime: '1300', fcstValue: '26'),
      _item(category: 'SKY', fcstTime: '1300', fcstValue: '1'),
      _item(category: 'SKY', fcstTime: '1400', fcstValue: '3'),
      _item(category: 'PTY', fcstTime: '1300', fcstValue: '0'),
    ]);

    expect(result.temperature, 26.0);
    expect(result.skyStatus, KmaSkyStatus.clear);
    expect(result.precipitationType, KmaPrecipitationType.none);
    expect(result.weatherLabel, '맑음');
  });

  test('강수가 있으면 하늘 상태 대신 강수 상태를 노출한다', () {
    final result = KmaWeatherResult.fromForecastItems([
      _item(category: 'T1H', fcstTime: '1300', fcstValue: '18'),
      _item(category: 'SKY', fcstTime: '1300', fcstValue: '4'),
      _item(category: 'PTY', fcstTime: '1300', fcstValue: '1'),
    ]);

    expect(result.precipitationType, KmaPrecipitationType.rain);
    expect(result.weatherLabel, '비');
  });

  test('카테고리가 비어있으면 기본값(0도, 확인 중)으로 처리한다', () {
    final result = KmaWeatherResult.fromForecastItems([]);

    expect(result.temperature, 0.0);
    expect(result.skyStatus, KmaSkyStatus.unknown);
    expect(result.weatherLabel, '날씨 확인 중');
  });
}
