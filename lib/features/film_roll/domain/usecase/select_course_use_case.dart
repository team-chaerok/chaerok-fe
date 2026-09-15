import 'dart:developer';

import 'package:chaerok/data/models/course_response.dart';
import 'package:chaerok/data/remote/places_api.dart';
import 'package:chaerok/features/film_roll/domain/entity/course_candidate_place.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';

const _tag = 'SelectCourseUseCase';

/// [SelectCourseUseCase]의 기본 이미지 보충 함수. `/api/courses/recommend`
/// 응답([CoursePlaceResponse])엔 이미지가 없어서, 서버 DB에 있는 장소
/// ([CourseCandidatePlace.serverPlaceId])라면 장소 상세 API로 한 번 더
/// 조회해 대표 사진만 얻는다. 실패해도 코스 확정 자체는 막지 않는다.
Future<String?> defaultPlaceImageFetcher(int placeId) async {
  try {
    final detail = await PlacesApi.getPlaceDetail(placeId);
    return detail.firstImageUrl;
  } catch (e, st) {
    log('장소 이미지 보충 실패(placeId=$placeId)', name: _tag, error: e, stackTrace: st);
    return null;
  }
}

/// 추천 코스 후보([CourseResponse])를 확정해 필름롤에 스냅샷으로 저장한다.
/// 이미 방문/사진 기록이 있는 상태에서 다른 코스로 변경하려 하면
/// [CourseChangeBlockedException]을 던진다(안전 기본값 정책).
class SelectCourseUseCase {
  const SelectCourseUseCase(
    this._filmRollRepository, {
    this.placeImageFetcher = defaultPlaceImageFetcher,
  });

  final FilmRollRepository _filmRollRepository;

  /// 서버 장소 ID로 대표 사진을 보충하는 함수. 테스트에서 네트워크 호출
  /// 없이 주입할 수 있도록 seam으로 뺐다.
  final Future<String?> Function(int placeId) placeImageFetcher;

  Future<void> call({
    required String filmRollId,
    required CourseResponse course,
  }) async {
    final places = <CourseCandidatePlace>[];
    for (var i = 0; i < course.places.length; i++) {
      places.add(
        CourseCandidatePlace.fromCoursePlaceResponse(
          course.places[i],
          visitOrder: i,
        ),
      );
    }

    final enriched = await Future.wait(places.map(_withImageIfAvailable));

    return _filmRollRepository.selectCourse(
      filmRollId: filmRollId,
      courseId: course.courseId,
      courseTitle: course.title,
      places: enriched,
    );
  }

  /// [place]에 이미지가 없고 서버 DB 장소(id가 있음)라면 상세 API로 보충한다.
  Future<CourseCandidatePlace> _withImageIfAvailable(
    CourseCandidatePlace place,
  ) async {
    final serverPlaceId = place.serverPlaceId;
    if (place.imageUrl != null || serverPlaceId == null) return place;

    final imageUrl = await placeImageFetcher(serverPlaceId);
    return imageUrl == null ? place : place.copyWith(imageUrl: imageUrl);
  }
}
