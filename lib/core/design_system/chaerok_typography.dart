import 'package:flutter/material.dart';

class ChaerokTypography {
  const ChaerokTypography._();

  static const String jeongnimsajiFontFamily = 'Jeongnimsaji';

  static const TextStyle titleLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  /// 홈 대시보드의 지역명 등 표시용 큰 텍스트. `jeongnimsajiFontFamily`와
  /// 함께 사용하는 것을 전제로 한다.
  static const TextStyle displayMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle headingLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: -0.3,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: -0.2,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// 진행률 수치(예: "12 / 36") 등 숫자 정렬이 중요한 곳에 사용.
  static const TextStyle progress = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
