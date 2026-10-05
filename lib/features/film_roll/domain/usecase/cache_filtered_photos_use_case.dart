import 'dart:developer';

import 'package:chaerok/data/models/film_roll_result_response.dart';
import 'package:chaerok/features/film_roll/domain/repository/photo_repository.dart';
import 'package:dio/dio.dart';

/// 서버가 내려준 필터 사진을 기기에 내려받아 보관한다.
///
/// 서버는 현상 결과를 일정 기간만 보관하므로, 그 뒤에도 사용자가 사진을 볼 수
/// 있게 보관 기간 안에 받아 둔다. 이미 보관한 사진은 건너뛰고, 일부가 실패해도
/// 나머지는 계속 받는다(실패분은 다음 호출 때 새 URL로 다시 시도된다).
class CacheFilteredPhotosUseCase {
  CacheFilteredPhotosUseCase(
    this._photoRepository, {
    Future<List<int>> Function(String url)? download,
  }) : _download = download ?? _downloadBytes;

  static const _tag = 'CacheFilteredPhotosUseCase';

  final PhotoRepository _photoRepository;
  final Future<List<int>> Function(String url) _download;

  Future<void> call({
    required String filmRollId,
    required List<FilteredPhotoResponse> photos,
  }) async {
    if (photos.isEmpty) return;

    final cachedPaths = await _photoRepository.findFilteredPhotoPaths(
      filmRollId,
    );
    for (final photo in photos) {
      if (cachedPaths.containsKey(photo.photoId)) continue;
      try {
        final bytes = await _download(photo.downloadUrl);
        if (bytes.isEmpty) continue;
        await _photoRepository.saveFilteredPhoto(
          filmRollId: filmRollId,
          serverPhotoId: photo.photoId,
          bytes: bytes,
        );
      } catch (e, st) {
        log(
          '필터 사진 보관 실패(photoId=${photo.photoId})',
          name: _tag,
          error: e,
          stackTrace: st,
        );
      }
    }
  }

  static Future<List<int>> _downloadBytes(String url) async {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data ?? const [];
  }
}
