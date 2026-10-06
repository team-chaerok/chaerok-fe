import 'dart:io';

import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:chaerok/features/film_roll/domain/usecase/save_result_photo_to_gallery_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('save_result_photo');
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('기기에 있는 사진은 내려받지 않고 그 파일을 바로 갤러리에 저장한다', () async {
    final savedPaths = <String>[];
    var downloads = 0;
    final useCase = SaveResultPhotoToGalleryUseCase(
      download: (_) async {
        downloads++;
        return const [1];
      },
      putImage: (path) async => savedPaths.add(path),
      tempDirectory: () async => tempDir,
    );

    await useCase(
      const FilmRollResultPhoto(
        sequence: 1,
        localPath: '/docs/filtered/101.jpg',
        remoteUrl: 'https://example.com/photo-101.jpg',
      ),
    );

    expect(downloads, 0);
    expect(savedPaths, ['/docs/filtered/101.jpg']);
  });

  test('서버 사진은 임시 파일로 내려받아 저장하고, 저장 뒤 임시 파일을 지운다', () async {
    final savedBytes = <List<int>>[];
    String? savedPath;
    final useCase = SaveResultPhotoToGalleryUseCase(
      download: (url) async {
        expect(url, 'https://example.com/photo-102.jpg');
        return const [7, 8, 9];
      },
      putImage: (path) async {
        savedPath = path;
        savedBytes.add(await File(path).readAsBytes());
      },
      tempDirectory: () async => tempDir,
    );

    await useCase(
      const FilmRollResultPhoto(
        sequence: 2,
        remoteUrl: 'https://example.com/photo-102.jpg',
      ),
    );

    expect(savedBytes, [
      [7, 8, 9],
    ]);
    expect(File(savedPath!).existsSync(), isFalse);
  });

  test('갤러리 저장이 실패해도 임시 파일을 지우고 오류를 그대로 전달한다', () async {
    String? savedPath;
    final useCase = SaveResultPhotoToGalleryUseCase(
      download: (_) async => const [1, 2],
      putImage: (path) async {
        savedPath = path;
        throw Exception('권한 없음');
      },
      tempDirectory: () async => tempDir,
    );

    await expectLater(
      useCase(
        const FilmRollResultPhoto(
          sequence: 3,
          remoteUrl: 'https://example.com/photo-103.jpg',
        ),
      ),
      throwsException,
    );
    expect(File(savedPath!).existsSync(), isFalse);
  });
}
