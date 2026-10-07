import 'package:chaerok/data/models/film_roll_result_response.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_place_repository.dart';
import 'package:chaerok/features/film_roll/domain/repository/photo_repository.dart';

/// 현상 결과 화면에 보여줄 사진 목록을 촬영 순서대로 만든다.
///
/// 서버는 현상 결과를 일정 기간만 보관한다. 보관 기간 안(`COMPLETED`)에는
/// 서버의 필터 사진을 보여주되 기기에 보관본이 있으면 그 파일을 쓰고, 기간이
/// 지나면(`EXPIRED`) 기기에 보관한 필터 사진을, 보관본이 없는 사진은 촬영
/// 원본을 보여준다. 기기에 촬영 기록이 있으면 사진마다 촬영 장소를 함께 담아
/// 장소별 대표 컷([pickPlaceRepresentatives])을 고를 수 있게 한다.
class GetFilmRollResultPhotosUseCase {
  const GetFilmRollResultPhotosUseCase(
    this._photoRepository, {
    FilmRollPlaceRepository? placeRepository,
  }) : _placeRepository = placeRepository;

  final PhotoRepository _photoRepository;
  final FilmRollPlaceRepository? _placeRepository;

  Future<List<FilmRollResultPhoto>> call({
    required String filmRollId,
    required FilmRollResultResponse result,
  }) async {
    final filteredPaths = await _photoRepository.findFilteredPhotoPaths(
      filmRollId,
    );
    final localPhotos = await _photoRepository.findByFilmRoll(filmRollId);
    final placeNames = await _findPlaceNames(filmRollId);

    if (result.isCompleted) {
      final localByServerId = {
        for (final photo in localPhotos)
          if (photo.serverPhotoId case final serverPhotoId?)
            serverPhotoId: photo,
      };
      return _sorted([
        for (final photo in result.filteredPhotos)
          FilmRollResultPhoto(
            sequence: photo.sequence,
            localPath: filteredPaths[photo.photoId],
            remoteUrl: photo.downloadUrl,
            filmRollPlaceId: localByServerId[photo.photoId]?.filmRollPlaceId,
            placeName:
                placeNames[localByServerId[photo.photoId]?.filmRollPlaceId],
          ),
      ]);
    }

    return _sorted([
      for (final photo in localPhotos)
        if (filteredPaths[photo.serverPhotoId] case final filteredPath?)
          FilmRollResultPhoto(
            sequence: photo.sequence,
            localPath: filteredPath,
            filmRollPlaceId: photo.filmRollPlaceId,
            placeName: placeNames[photo.filmRollPlaceId],
          )
        else
          FilmRollResultPhoto(
            sequence: photo.sequence,
            localPath: photo.originalPath,
            isFiltered: false,
            filmRollPlaceId: photo.filmRollPlaceId,
            placeName: placeNames[photo.filmRollPlaceId],
          ),
    ]);
  }

  /// 장소 id → 장소 이름. 이름은 부가 정보라 조회에 실패해도 사진 목록은
  /// 그대로 보여줄 수 있도록 빈 결과로 대신한다.
  Future<Map<String, String>> _findPlaceNames(String filmRollId) async {
    final placeRepository = _placeRepository;
    if (placeRepository == null) return const {};
    try {
      final places = await placeRepository.findByFilmRoll(filmRollId);
      return {for (final place in places) place.id: place.name};
    } catch (_) {
      return const {};
    }
  }

  /// 촬영 순서로 정렬된 [photos]에서 장소마다 처음 찍은 사진을 한 장씩,
  /// 최대 [limit]장 고른다. 장소를 알 수 없는 사진(다른 기기에서 찍은 롤 등)은
  /// 각각 다른 장소로 보아, 그때는 앞에서부터 [limit]장이 된다.
  static List<FilmRollResultPhoto> pickPlaceRepresentatives(
    List<FilmRollResultPhoto> photos, {
    int limit = 3,
  }) {
    final seenPlaceIds = <String>{};
    final picked = <FilmRollResultPhoto>[];
    for (final photo in photos) {
      if (picked.length >= limit) break;
      final placeId = photo.filmRollPlaceId;
      if (placeId != null && !seenPlaceIds.add(placeId)) continue;
      picked.add(photo);
    }
    return picked;
  }

  /// 기기를 조회하지 않고 서버 응답만으로 만든 목록. 기기 조회가 끝나기 전이나
  /// 실패했을 때 화면이 바로 그릴 수 있게 한다.
  static List<FilmRollResultPhoto> fromServer(FilmRollResultResponse result) {
    return _sorted([
      for (final photo in result.filteredPhotos)
        FilmRollResultPhoto(
          sequence: photo.sequence,
          remoteUrl: photo.downloadUrl,
        ),
    ]);
  }

  static List<FilmRollResultPhoto> _sorted(List<FilmRollResultPhoto> photos) {
    return photos..sort((a, b) => a.sequence.compareTo(b.sequence));
  }
}
