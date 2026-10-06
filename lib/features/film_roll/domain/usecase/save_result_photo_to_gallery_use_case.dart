import 'dart:io';

import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:dio/dio.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';

/// 현상 결과 사진 한 장을 기기 갤러리에 저장한다. 기기에 있는 파일이면 바로
/// 저장하고, 서버 사진이면 임시 파일로 내려받아 저장한 뒤 임시 파일을 지운다.
///
/// 실패하면 예외를 그대로 던진다. 갤러리 권한이 없으면 [GalException]
/// (`GalExceptionType.accessDenied`)이 전달된다.
class SaveResultPhotoToGalleryUseCase {
  SaveResultPhotoToGalleryUseCase({
    Future<List<int>> Function(String url)? download,
    Future<void> Function(String path)? putImage,
    Future<Directory> Function()? tempDirectory,
  }) : _download = download ?? _downloadBytes,
       _putImage = putImage ?? Gal.putImage,
       _tempDirectory = tempDirectory ?? getTemporaryDirectory;

  final Future<List<int>> Function(String url) _download;
  final Future<void> Function(String path) _putImage;
  final Future<Directory> Function() _tempDirectory;

  Future<void> call(FilmRollResultPhoto photo) async {
    final localPath = photo.localPath;
    if (localPath != null) {
      await _putImage(localPath);
      return;
    }

    final bytes = await _download(photo.remoteUrl!);
    final dir = await _tempDirectory();
    final file = File(
      '${dir.path}/chaerok-photo-${photo.sequence}-'
      '${DateTime.now().microsecondsSinceEpoch}.jpg',
    );
    await file.writeAsBytes(bytes, flush: true);
    try {
      await _putImage(file.path);
    } finally {
      if (await file.exists()) await file.delete();
    }
  }

  static Future<List<int>> _downloadBytes(String url) async {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('사진을 내려받지 못했습니다: $url');
    }
    return data;
  }
}
