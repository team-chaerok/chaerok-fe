/// 기상청 초단기예보(getUltraSrtFcst) 조회 결과 중 홈 화면에 필요한 값만 담은 모델.
class KmaWeatherResult {
  const KmaWeatherResult({
    required this.temperature,
    required this.skyStatus,
    required this.precipitationType,
  });

  /// 가장 가까운 예보 시각의 기온(T1H, ℃).
  final double temperature;
  final KmaSkyStatus skyStatus;
  final KmaPrecipitationType precipitationType;

  /// 강수가 있으면 강수 상태를, 없으면 하늘 상태를 우선 노출한다.
  String get weatherLabel => precipitationType == KmaPrecipitationType.none
      ? skyStatus.label
      : precipitationType.label;

  /// [items]는 기상청 API 응답의 `response.body.items.item` 배열이다.
  /// 카테고리(T1H/SKY/PTY)별로 가장 가까운 예보 시각(fcstDate+fcstTime)의
  /// 값을 골라 사용한다.
  factory KmaWeatherResult.fromForecastItems(List<Map<String, dynamic>> items) {
    final nearestByCategory = <String, String>{};
    final nearestOrderByCategory = <String, String>{};

    for (final item in items) {
      final category = item['category'] as String?;
      final fcstValue = item['fcstValue'] as String?;
      final fcstDate = item['fcstDate'] as String?;
      final fcstTime = item['fcstTime'] as String?;
      if (category == null || fcstValue == null) continue;

      final order = '${fcstDate ?? ''}${fcstTime ?? ''}';
      final currentOrder = nearestOrderByCategory[category];
      if (currentOrder == null || order.compareTo(currentOrder) < 0) {
        nearestByCategory[category] = fcstValue;
        nearestOrderByCategory[category] = order;
      }
    }

    return KmaWeatherResult(
      temperature: double.tryParse(nearestByCategory['T1H'] ?? '') ?? 0.0,
      skyStatus: KmaSkyStatus.fromCode(nearestByCategory['SKY']),
      precipitationType: KmaPrecipitationType.fromCode(
        nearestByCategory['PTY'],
      ),
    );
  }
}

/// 기상청 SKY(하늘상태) 코드: 1=맑음, 3=구름많음, 4=흐림.
enum KmaSkyStatus {
  clear,
  mostlyCloudy,
  cloudy,
  unknown;

  factory KmaSkyStatus.fromCode(String? code) {
    switch (code) {
      case '1':
        return KmaSkyStatus.clear;
      case '3':
        return KmaSkyStatus.mostlyCloudy;
      case '4':
        return KmaSkyStatus.cloudy;
      default:
        return KmaSkyStatus.unknown;
    }
  }

  String get label => switch (this) {
    KmaSkyStatus.clear => '맑음',
    KmaSkyStatus.mostlyCloudy => '구름많음',
    KmaSkyStatus.cloudy => '흐림',
    KmaSkyStatus.unknown => '날씨 확인 중',
  };
}

/// 기상청 PTY(강수형태) 코드: 0=없음, 1=비, 2=비/눈, 3=눈, 4=소나기.
enum KmaPrecipitationType {
  none,
  rain,
  rainSnow,
  snow,
  shower,
  unknown;

  factory KmaPrecipitationType.fromCode(String? code) {
    switch (code) {
      case '0':
        return KmaPrecipitationType.none;
      case '1':
        return KmaPrecipitationType.rain;
      case '2':
        return KmaPrecipitationType.rainSnow;
      case '3':
        return KmaPrecipitationType.snow;
      case '4':
        return KmaPrecipitationType.shower;
      default:
        return KmaPrecipitationType.unknown;
    }
  }

  String get label => switch (this) {
    KmaPrecipitationType.none => '',
    KmaPrecipitationType.rain => '비',
    KmaPrecipitationType.rainSnow => '비/눈',
    KmaPrecipitationType.snow => '눈',
    KmaPrecipitationType.shower => '소나기',
    KmaPrecipitationType.unknown => '날씨 확인 중',
  };
}
