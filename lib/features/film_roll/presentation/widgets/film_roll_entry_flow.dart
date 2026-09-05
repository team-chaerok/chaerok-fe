import 'dart:developer';

import 'package:chaerok/features/explore/domain/explore_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/page/course_selection_result.dart';
import 'package:chaerok/features/film_roll/presentation/page/course_selection_screen.dart';
import 'package:flutter/material.dart';

const _tag = 'FilmRollEntryFlow';

/// [FilmRollModule.instance.enterRegion] 호출과 표준 예외 처리(스낵바)를 캡슐화한다.
/// Home/Explore 두 진입점이 동일한 에러 문구를 공유하도록 중복을 제거한다.
/// 실패 시 `null`을 반환한다.
Future<FilmRoll?> enterRegionWithErrorHandling(
  BuildContext context, {
  required String cityCountyName,
  required int regionId,
}) async {
  try {
    return await FilmRollModule.instance.enterRegion(
      cityCountyName,
      regionId: regionId,
    );
  } on UnsupportedRegionException {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('아직 필름롤을 지원하지 않는 지역이에요.')));
    }
    return null;
  } catch (e, st) {
    log('필름롤 진입 실패', name: _tag, error: e, stackTrace: st);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('필름롤을 불러오지 못했어요.')));
    }
    return null;
  }
}

/// 코스 선택 화면을 push하고, 사용자가 코스를 고르면
/// [FilmRollModule.instance.selectCourse]/`selectCustomCourse`로 반영한다.
/// `FilmRollScreen`/`FilmRollProgressView`의 코스 선택 버튼, 위치 인증/지역
/// 진입 직후 자동 연결 플로우, 탐색 모드 북마크의 "이 장소로 코스 만들기"
/// 진입점이 이 함수를 공유한다. [initialTab]/[initialSelectedPlace]는 북마크
/// 진입점처럼 직접 만들기 모드로 바로 열고 장소를 미리 담아 두고 싶을 때 쓴다.
/// 코스 선택을 확정하지 못했거나(뒤로가기) 서버 반영에 실패해도 예외를 던지지
/// 않고 그대로 반환한다 — 호출부가 별도 폴백 화면(코스 미선택 상태의 진행
/// 화면)으로 계속 진행할 수 있게 하기 위함.
Future<void> pushCourseSelectionAndConfirm(
  BuildContext context, {
  required String filmRollId,
  required int regionId,
  CourseSelectionInitialTab initialTab = CourseSelectionInitialTab.recommended,
  ExplorePlace? initialSelectedPlace,
}) async {
  final result = await Navigator.of(context).push<CourseSelectionResult>(
    MaterialPageRoute(
      builder: (_) => CourseSelectionScreen(
        regionId: regionId,
        initialTab: initialTab,
        initialSelectedPlace: initialSelectedPlace,
      ),
    ),
  );
  if (result == null) return;

  try {
    switch (result.outcome) {
      case CourseSelectionOutcome.recommended:
        await FilmRollModule.instance.selectCourse(
          filmRollId: filmRollId,
          course: result.recommendedCourse!,
        );
      case CourseSelectionOutcome.custom:
        await FilmRollModule.instance.selectCustomCourse(
          filmRollId: filmRollId,
          course: result.customCourse!,
          places: result.customPlaces!,
        );
    }
  } catch (e, st) {
    log('코스 선택 실패', name: _tag, error: e, stackTrace: st);
  }
}
