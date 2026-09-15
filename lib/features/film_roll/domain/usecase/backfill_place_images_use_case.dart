import 'dart:developer';

import 'package:chaerok/features/film_roll/domain/repository/film_roll_place_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/select_course_use_case.dart';

const _tag = 'BackfillPlaceImagesUseCase';

/// [SelectCourseUseCase]의 이미지 보충 기능이 생기기 전에 이미 코스가 확정된
/// 필름롤은 장소에 [FilmRollPlace.imageUrl]이 계속 비어있다. 홈 진입 시 한 번,
/// 서버 DB 장소([FilmRollPlace.serverPlaceId] 있음)만 장소 상세 API로 소급
/// 보충한다. 외부(TourAPI/Kakao) 전용 장소는 여전히 채울 방법이 없어 그대로
/// 둔다(일러스트 폴백 유지). 이미 이미지가 있는 장소는 건드리지 않으므로,
/// 여러 번 호출해도 매번 남은 것만 다시 시도한다(멱등).
class BackfillPlaceImagesUseCase {
  const BackfillPlaceImagesUseCase(
    this._placeRepository, {
    this.placeImageFetcher = defaultPlaceImageFetcher,
  });

  final FilmRollPlaceRepository _placeRepository;

  /// [SelectCourseUseCase]와 동일한 seam — 테스트에서 네트워크 없이 주입한다.
  final Future<String?> Function(int placeId) placeImageFetcher;

  Future<void> call(String filmRollId) async {
    final places = await _placeRepository.findByFilmRoll(filmRollId);
    final targets = places.where(
      (place) => place.imageUrl == null && place.serverPlaceId != null,
    );

    await Future.wait(
      targets.map((place) async {
        try {
          final imageUrl = await placeImageFetcher(place.serverPlaceId!);
          if (imageUrl == null) return;
          await _placeRepository.updateImageUrl(place.id, imageUrl);
        } catch (e, st) {
          log(
            '장소 이미지 소급 보충 실패(placeId=${place.id})',
            name: _tag,
            error: e,
            stackTrace: st,
          );
        }
      }),
    );
  }
}
