import 'dart:typed_data';

import 'package:chaerok/core/file/captured_photo_orientation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

/// 40x20 흰 바탕의 왼쪽 위 20x10 영역만 빨간색인 JPEG. 회전 방향을 픽셀로 확인한다.
Uint8List _markedJpeg({int? exifOrientation}) {
  final image = img.Image(width: 40, height: 20);
  img.fill(image, color: img.ColorRgb8(255, 255, 255));
  img.fillRect(
    image,
    x1: 0,
    y1: 0,
    x2: 19,
    y2: 9,
    color: img.ColorRgb8(255, 0, 0),
  );
  if (exifOrientation != null) {
    image.exif.imageIfd.orientation = exifOrientation;
  }
  return Uint8List.fromList(img.encodeJpg(image, quality: 100));
}

bool _isRed(img.Image image, int x, int y) {
  final p = image.getPixel(x, y);
  return p.r > 200 && p.g < 80 && p.b < 80;
}

bool _isWhite(img.Image image, int x, int y) {
  final p = image.getPixel(x, y);
  return p.r > 200 && p.g > 200 && p.b > 200;
}

void main() {
  test('UI를 시계 방향으로 1번 돌렸으면 사진은 반시계 90°로 돌린다', () {
    final out = img.decodeJpg(
      orientCapturedPhoto(_markedJpeg(), uiQuarterTurns: 1),
    )!;

    // 40x20 → 20x40. 왼쪽 위 빨강이 반시계 회전으로 왼쪽 아래로 간다.
    expect(out.width, 20);
    expect(out.height, 40);
    expect(_isRed(out, 5, 35), isTrue);
    expect(_isWhite(out, 5, 5), isTrue);
    expect(_isWhite(out, 15, 35), isTrue);
  });

  test('uiQuarterTurns가 0이면 원본 바이트를 그대로 돌려준다', () {
    final source = _markedJpeg();

    expect(orientCapturedPhoto(source, uiQuarterTurns: 0), source);
  });

  test('EXIF 방향 태그가 있으면 태그를 먼저 반영한 뒤 UI 회전을 적용한다', () {
    // 태그 6 = 시계 방향 90°로 세워야 정방향(40x20 → 20x40, 빨강은 오른쪽 위).
    // 여기에 반시계 90°를 더하면 결국 센서 원본(40x20, 빨강 왼쪽 위)과 같다.
    final out = img.decodeJpg(
      orientCapturedPhoto(_markedJpeg(exifOrientation: 6), uiQuarterTurns: 1),
    )!;

    expect(out.width, 40);
    expect(out.height, 20);
    expect(_isRed(out, 5, 3), isTrue);
    expect(_isWhite(out, 35, 15), isTrue);
  });

  test('디코딩할 수 없는 바이트는 그대로 돌려준다', () {
    final garbage = Uint8List.fromList(List.filled(32, 7));

    expect(orientCapturedPhoto(garbage, uiQuarterTurns: 1), garbage);
  });

  test('회전 결과에는 EXIF 방향 태그가 남지 않는다', () {
    final out = orientCapturedPhoto(_markedJpeg(), uiQuarterTurns: 1);

    final orientation = img.decodeJpgExif(out)?.imageIfd.orientation;
    expect(orientation, anyOf(isNull, 1));
  });
}
