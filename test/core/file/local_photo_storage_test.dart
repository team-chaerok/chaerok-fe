import 'dart:io';
import 'dart:typed_data';

import 'package:chaerok/core/file/local_photo_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.dir);
  final Directory dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documentsDir;
  const storage = LocalPhotoStorage.instance;
  final bytes = Uint8List.fromList(List.filled(32, 7));

  setUp(() async {
    documentsDir = await Directory.systemTemp.createTemp('local_photo_storage');
    PathProviderPlatform.instance = _FakePathProviderPlatform(documentsDir);
  });

  tearDown(() async {
    await documentsDir.delete(recursive: true);
  });

  test('save()는 문서 디렉터리 기준 상대 경로를 반환한다', () async {
    final paths = await storage.save(
      filmRollId: 'fr1',
      filmRollPlaceId: 'p1',
      photoId: 'ph1',
      imageBytes: bytes,
    );

    expect(p.isAbsolute(paths.originalPath), isFalse);
    expect(p.isAbsolute(paths.thumbnailPath), isFalse);
    expect(paths.originalPath, 'film_rolls/fr1/p1/original/ph1.jpg');
    expect(paths.thumbnailPath, 'film_rolls/fr1/p1/thumbnail/ph1.jpg');
  });

  test('save()가 반환한 상대 경로를 resolve()하면 실제 저장된 파일을 가리킨다', () async {
    final paths = await storage.save(
      filmRollId: 'fr1',
      filmRollPlaceId: 'p1',
      photoId: 'ph1',
      imageBytes: bytes,
    );

    final originalAbs = await storage.resolve(paths.originalPath);
    final thumbnailAbs = await storage.resolve(paths.thumbnailPath);

    expect(p.isWithin(documentsDir.path, originalAbs), isTrue);
    expect(File(originalAbs).existsSync(), isTrue);
    expect(File(thumbnailAbs).existsSync(), isTrue);
  });

  test('resolve()는 컨테이너 UUID가 다른 구버전 절대 경로를 현재 문서 디렉터리 기준으로 되돌린다', () async {
    const legacyAbsolute =
        '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/'
        'film_rolls/fr1/p1/thumbnail/ph1.jpg';

    final resolved = await storage.resolve(legacyAbsolute);

    expect(
      resolved,
      p.join(documentsDir.path, 'film_rolls/fr1/p1/thumbnail/ph1.jpg'),
    );
  });

  test('resolve()는 이미 상대 경로인 값을 그대로 문서 디렉터리에 붙인다', () async {
    final resolved = await storage.resolve(
      'film_rolls/fr1/p1/original/ph1.jpg',
    );

    expect(
      resolved,
      p.join(documentsDir.path, 'film_rolls/fr1/p1/original/ph1.jpg'),
    );
  });

  test('delete()는 상대 경로 입력으로 실제 파일을 삭제한다', () async {
    final paths = await storage.save(
      filmRollId: 'fr1',
      filmRollPlaceId: 'p1',
      photoId: 'ph1',
      imageBytes: bytes,
    );

    await storage.delete(
      originalPath: paths.originalPath,
      thumbnailPath: paths.thumbnailPath,
    );

    expect(
      File(await storage.resolve(paths.originalPath)).existsSync(),
      isFalse,
    );
    expect(
      File(await storage.resolve(paths.thumbnailPath)).existsSync(),
      isFalse,
    );
  });

  test('delete()는 구버전 절대 경로 입력이어도 현재 문서 디렉터리의 파일을 삭제한다', () async {
    final paths = await storage.save(
      filmRollId: 'fr1',
      filmRollPlaceId: 'p1',
      photoId: 'ph1',
      imageBytes: bytes,
    );
    final originalAbs = await storage.resolve(paths.originalPath);

    await storage.delete(
      originalPath:
          '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/'
          '${paths.originalPath}',
      thumbnailPath:
          '/var/mobile/Containers/Data/Application/OLD-UUID/Documents/'
          '${paths.thumbnailPath}',
    );

    expect(File(originalAbs).existsSync(), isFalse);
  });

  test('delete()는 파일이 이미 없어도 예외를 던지지 않는다', () async {
    await expectLater(
      storage.delete(
        originalPath: 'film_rolls/fr1/p1/original/missing.jpg',
        thumbnailPath: 'film_rolls/fr1/p1/thumbnail/missing.jpg',
      ),
      completes,
    );
  });

  group('EXIF 방향 보정', () {
    /// [width]x[height] 픽셀에 EXIF [orientation]을 단 JPEG. iOS 카메라는 폰을
    /// 돌려 찍어도 센서 방향 픽셀 + EXIF 태그로 저장한다.
    Uint8List jpegWithOrientation(
      int orientation, {
      int width = 60,
      int height = 40,
    }) {
      final image = img.Image(width: width, height: height);
      image.exif.imageIfd.orientation = orientation;
      return Uint8List.fromList(img.encodeJpg(image));
    }

    Future<Uint8List> savedBytes(String storedPath) async =>
        File(await storage.resolve(storedPath)).readAsBytes();

    Future<img.Image> decodeSaved(String storedPath) async {
      final file = File(await storage.resolve(storedPath));
      return img.decodeJpg(await file.readAsBytes())!;
    }

    test('방향 태그가 있으면 원본 픽셀을 똑바로 돌려 저장하고 태그는 남기지 않는다', () async {
      // orientation 6 = 시계 방향 90° 회전해야 정방향(가로 60x40 → 세로 40x60).
      final paths = await storage.save(
        filmRollId: 'fr1',
        filmRollPlaceId: 'p1',
        photoId: 'ph1',
        imageBytes: jpegWithOrientation(6),
      );

      final original = await decodeSaved(paths.originalPath);
      expect(original.width, 40);
      expect(original.height, 60);
      // decodeJpg는 태그를 자동 적용해 버리므로, 저장된 파일에 태그가 남았는지는
      // 원본 바이트의 EXIF를 직접 읽어 확인한다(Flutter는 이 태그에 의존한다).
      final rawExif = img.decodeJpgExif(await savedBytes(paths.originalPath));
      expect(rawExif?.imageIfd.orientation, anyOf(isNull, 1));
    });

    test('썸네일도 방향이 반영된 상태로 만든다', () async {
      final paths = await storage.save(
        filmRollId: 'fr1',
        filmRollPlaceId: 'p1',
        photoId: 'ph1',
        imageBytes: jpegWithOrientation(6),
      );

      final thumbnail = await decodeSaved(paths.thumbnailPath);
      expect(thumbnail.height, greaterThan(thumbnail.width));
    });

    test('방향이 이미 정상(1)이면 원본 바이트를 그대로 저장한다', () async {
      final source = jpegWithOrientation(1);
      final paths = await storage.save(
        filmRollId: 'fr1',
        filmRollPlaceId: 'p1',
        photoId: 'ph1',
        imageBytes: source,
      );

      final saved = await File(
        await storage.resolve(paths.originalPath),
      ).readAsBytes();
      expect(saved, source);

      final thumbnail = await decodeSaved(paths.thumbnailPath);
      expect(thumbnail.width, greaterThan(thumbnail.height));
    });
  });
}
