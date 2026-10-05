import 'package:chaerok/data/models/film_roll_result_response.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:chaerok/features/film_roll/domain/repository/photo_repository.dart';

/// 현상 결과 화면에 보여줄 사진 목록을 촬영 순서대로 만든다.
///
/// 서버는 현상 결과를 일정 기간만 보관한다. 보관 기간 안(`COMPLETED`)에는
/// 서버의 필터 사진을 보여주되 기기에 보관본이 있으면 그 파일을 쓰고, 기간이
/// 지나면(`EXPIRED`) 기기에 보관한 필터 사진을, 보관본이 없는 사진은 촬영
/// 원본을 보여준다.
class GetFilmRollResultPhotosUseCase {
  const GetFilmRollResultPhotosUseCase(this._photoRepository);

  final PhotoRepository _photoRepository;

  Future<List<FilmRollResultPhoto>> call({
    required String filmRollId,
    required FilmRollResultResponse result,
  }) async {
    final filteredPaths = await _photoRepository.findFilteredPhotoPaths(
      filmRollId,
    );

    if (result.isCompleted) {
      return _sorted([
        for (final photo in result.filteredPhotos)
          FilmRollResultPhoto(
            sequence: photo.sequence,
            localPath: filteredPaths[photo.photoId],
            remoteUrl: photo.downloadUrl,
          ),
      ]);
    }

    final localPhotos = await _photoRepository.findByFilmRoll(filmRollId);
    return _sorted([
      for (final photo in localPhotos)
        if (filteredPaths[photo.serverPhotoId] case final filteredPath?)
          FilmRollResultPhoto(sequence: photo.sequence, localPath: filteredPath)
        else
          FilmRollResultPhoto(
            sequence: photo.sequence,
            localPath: photo.originalPath,
            isFiltered: false,
          ),
    ]);
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
