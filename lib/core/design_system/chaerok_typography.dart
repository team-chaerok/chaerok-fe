import 'package:flutter/material.dart';

class ChaerokTypography {
  const ChaerokTypography._();

  static const String nanumSquareRoundFontFamily = 'NanumSquareRound';
  static const String jeongnimsajiFontFamily = 'Jeongnimsaji';

  /// 28px · line-height 36/28(≈1.29) · 나눔스퀘어라운드.
  /// 화면 최상단 대표 제목.
  static const TextStyle displayLarge = TextStyle(
    fontFamily: nanumSquareRoundFontFamily,
    fontSize: 28,
    height: 36 / 28,
  );

  /// 22px · line-height 30/22(≈1.36) · 나눔스퀘어라운드.
  /// 페이지 제목.
  static const TextStyle titleLarge = TextStyle(
    fontFamily: nanumSquareRoundFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 30 / 22,
  );

  /// 18px · line-height 26/18(≈1.44) · 나눔스퀘어라운드.
  /// 섹션 제목.
  static const TextStyle titleMedium = TextStyle(
    fontFamily: nanumSquareRoundFontFamily,
    fontWeight: FontWeight.w700,
    fontSize: 18,
    height: 26 / 18,
  );

  /// 16px · line-height 24/16(1.5) · 나눔스퀘어라운드.
  /// 강조 본문.
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: nanumSquareRoundFontFamily,
    fontSize: 16,
    height: 24 / 16,
  );

  /// 14px · line-height 20/14(≈1.43) · 나눔스퀘어라운드.
  /// 기본 본문.
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: nanumSquareRoundFontFamily,
    fontSize: 14,
    height: 20 / 14,
  );

  /// 12px · line-height 16/12(≈1.33) · 나눔스퀘어라운드.
  /// 캡션/보조 라벨.
  static const TextStyle caption = TextStyle(
    fontFamily: nanumSquareRoundFontFamily,
    fontSize: 12,
    height: 16 / 12,
  );

  /// 22px · Medium(w500) · line-height 1.3 · letter-spacing -0.2 · 정림사지체.
  /// 홈 대시보드의 지역명 등 표시용 큰 텍스트. 정림사지체를 사용한다.
  static const TextStyle displayMedium = TextStyle(
    fontFamily: jeongnimsajiFontFamily,
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
  );

  /// 18px · SemiBold(w600) · line-height 1.2 · 나눔스퀘어라운드 · tabular figures.
  /// 진행률 수치(예: "12 / 36") 등 숫자 정렬이 중요한 곳에 사용.
  static const TextStyle progress = TextStyle(
    fontFamily: nanumSquareRoundFontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.2,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}
