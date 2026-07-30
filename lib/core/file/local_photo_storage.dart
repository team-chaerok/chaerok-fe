import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _thumbnailMaxWidth = 480;
const _thumbnailJpegQuality = 80;

/// 필름롤 사진 원본/썸네일 파일을 앱 내부 영구 저장소에 저장/삭제하는 서비스.
/// 저장 경로: `app_documents/film_rolls/{filmRollId}/{filmRollPlaceId}/original|thumbnail/{photoId}.jpg`
class LocalPhotoStorage {
  const LocalPhotoStorage._();

  static const LocalPhotoStorage instance = LocalPhotoStorage._();

  /// 원본 사진을 저장하고, 썸네일을 리사이즈해 함께 저장한 뒤 두 파일의 경로를 반환한다.
  Future<({String originalPath, String thumbnailPath})> save({
    required String filmRollId,
    required String filmRollPlaceId,
    required String photoId,
    required Uint8List imageBytes,
  }) async {
    final placeDir = await _placeDirectory(
      filmRollId: filmRollId,
      filmRollPlaceId: filmRollPlaceId,
    );

    final originalDir = Directory(p.join(placeDir.path, 'original'));
    final thumbnailDir = Directory(p.join(placeDir.path, 'thumbnail'));
    await originalDir.create(recursive: true);
    await thumbnailDir.create(recursive: true);

    final originalFile = File(p.join(originalDir.path, '$photoId.jpg'));
    await originalFile.writeAsBytes(imageBytes, flush: true);

    final thumbnailFile = File(p.join(thumbnailDir.path, '$photoId.jpg'));
    await thumbnailFile.writeAsBytes(_buildThumbnail(imageBytes), flush: true);

    return (originalPath: originalFile.path, thumbnailPath: thumbnailFile.path);
  }

  /// 사진 원본/썸네일 파일을 삭제한다. 파일이 이미 없어도 예외를 던지지 않는다.
  Future<void> delete({
    required String originalPath,
    required String thumbnailPath,
  }) async {
    await _deleteIfExists(originalPath);
    await _deleteIfExists(thumbnailPath);
  }

  /// 필름롤 전체 디렉터리(장소별 원본/썸네일 전부)를 삭제한다.
  Future<void> deleteFilmRollDirectory(String filmRollId) async {
    final dir = Directory(
      p.join((await _filmRollsRootDirectory()).path, filmRollId),
    );
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Uint8List _buildThumbnail(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      // 디코딩 실패 시 원본을 그대로 썸네일로 사용(리사이즈 생략).
      return imageBytes;
    }
    final resized = img.copyResize(decoded, width: _thumbnailMaxWidth);
    return Uint8List.fromList(
      img.encodeJpg(resized, quality: _thumbnailJpegQuality),
    );
  }

  Future<Directory> _placeDirectory({
    required String filmRollId,
    required String filmRollPlaceId,
  }) async {
    final root = await _filmRollsRootDirectory();
    return Directory(p.join(root.path, filmRollId, filmRollPlaceId));
  }

  Future<Directory> _filmRollsRootDirectory() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(documentsDir.path, 'film_rolls'));
  }

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
