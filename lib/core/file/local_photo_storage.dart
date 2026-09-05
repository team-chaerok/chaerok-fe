import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _thumbnailMaxWidth = 480;
const _thumbnailJpegQuality = 80;

/// 필름롤 사진 원본/썸네일 파일을 앱 내부 영구 저장소에 저장/삭제하는 서비스.
///
/// DB에는 문서 디렉터리 기준 **상대 경로**
/// (`film_rolls/{filmRollId}/{filmRollPlaceId}/original|thumbnail/{photoId}.jpg`)만
/// 저장하고, 실제 파일 접근이 필요한 시점에 [resolve]로 절대 경로를 만든다.
/// iOS는 앱 Data 컨테이너 절대 경로(`.../Application/{UUID}/`)가 재설치·OS
/// 마이그레이션·백업 복원 시 바뀌므로, 절대 경로를 그대로 저장하면 이후
/// 파일을 찾지 못한다.
class LocalPhotoStorage {
  const LocalPhotoStorage._();

  static const LocalPhotoStorage instance = LocalPhotoStorage._();

  /// 상대 경로의 최상위 디렉터리 이름. 구버전에서 절대 경로로 저장된 값을
  /// 상대 경로로 되돌릴 때 기준이 되는 마커이기도 하다.
  static const filmRollsDirName = 'film_rolls';

  /// 원본 사진을 저장하고, 썸네일을 리사이즈해 함께 저장한 뒤 두 파일의
  /// **문서 디렉터리 기준 상대 경로**를 반환한다.
  Future<({String originalPath, String thumbnailPath})> save({
    required String filmRollId,
    required String filmRollPlaceId,
    required String photoId,
    required Uint8List imageBytes,
  }) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final placeDir = Directory(
      p.join(documentsDir.path, filmRollsDirName, filmRollId, filmRollPlaceId),
    );

    final originalDir = Directory(p.join(placeDir.path, 'original'));
    final thumbnailDir = Directory(p.join(placeDir.path, 'thumbnail'));
    await originalDir.create(recursive: true);
    await thumbnailDir.create(recursive: true);

    final originalFile = File(p.join(originalDir.path, '$photoId.jpg'));
    await originalFile.writeAsBytes(imageBytes, flush: true);

    final thumbnailFile = File(p.join(thumbnailDir.path, '$photoId.jpg'));
    await thumbnailFile.writeAsBytes(_buildThumbnail(imageBytes), flush: true);

    return (
      originalPath: _relativeToDocuments(originalFile.path, documentsDir),
      thumbnailPath: _relativeToDocuments(thumbnailFile.path, documentsDir),
    );
  }

  /// 저장된 경로([save] 반환값 또는 구버전 절대 경로)를 현재 문서 디렉터리
  /// 기준 절대 경로로 복원한다.
  Future<String> resolve(String storedPath) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    return p.join(documentsDir.path, _toRelativePath(storedPath));
  }

  /// 사진 원본/썸네일 파일을 삭제한다. 저장값이 상대/구버전 절대 경로 어느
  /// 쪽이든 처리하며, 파일이 이미 없어도 예외를 던지지 않는다.
  Future<void> delete({
    required String originalPath,
    required String thumbnailPath,
  }) async {
    await _deleteIfExists(await resolve(originalPath));
    await _deleteIfExists(await resolve(thumbnailPath));
  }

  /// 필름롤 전체 디렉터리(장소별 원본/썸네일 전부)를 삭제한다.
  Future<void> deleteFilmRollDirectory(String filmRollId) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(
      p.join(documentsDir.path, filmRollsDirName, filmRollId),
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

  String _relativeToDocuments(String absolutePath, Directory documentsDir) {
    return p.relative(absolutePath, from: documentsDir.path);
  }

  /// 절대 경로면 [filmRollsDirName] 세그먼트부터 잘라 상대 경로로 만든다.
  /// 이미 상대 경로면 그대로 반환한다. 마커가 없으면(예상 밖의 값) 원본을
  /// 그대로 두어 최소한 기존 동작을 유지한다.
  String _toRelativePath(String storedPath) {
    if (!p.isAbsolute(storedPath)) return storedPath;
    final segments = p.split(storedPath);
    final markerIndex = segments.lastIndexOf(filmRollsDirName);
    if (markerIndex == -1) return storedPath;
    return p.joinAll(segments.sublist(markerIndex));
  }

  Future<void> _deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
