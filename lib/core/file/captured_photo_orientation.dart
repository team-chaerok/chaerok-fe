import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

const _jpegQuality = 95;

/// 촬영 화면은 앱이 세로로 고정된 채 UI만 시계 방향으로 [uiQuarterTurns]번 돌려
/// 그린다(사용자는 폰을 옆으로 돌려 찍는다). 그런데 카메라는 앱 방향(세로) 기준으로
/// 저장하므로, 사진은 뷰파인더에서 본 것과 90° 어긋난 채 저장된다. UI를 돌린 것과
/// 반대(반시계)로 같은 횟수만큼 사진을 돌려 뷰파인더와 같은 방향으로 맞춘다.
///
/// EXIF 방향 태그는 먼저 픽셀에 반영한 뒤 돌리고, 결과에는 태그를 남기지 않는다.
/// [uiQuarterTurns]가 0이거나 디코딩할 수 없는 바이트면 원본을 그대로 돌려준다.
Uint8List orientCapturedPhoto(
  Uint8List imageBytes, {
  required int uiQuarterTurns,
}) {
  final turns = uiQuarterTurns % 4;
  if (turns == 0) return imageBytes;

  // decodeImage는 디코딩 시 EXIF 방향 태그를 픽셀에 반영한다.
  final decoded = img.decodeImage(imageBytes);
  if (decoded == null) return imageBytes;

  // copyRotate의 angle은 시계 방향 각도라, 반시계 [turns]번 = 시계 (4 - turns)번.
  final rotated = img.copyRotate(decoded, angle: (4 - turns) * 90);
  return Uint8List.fromList(img.encodeJpg(rotated, quality: _jpegQuality));
}

/// [orientCapturedPhoto]를 별도 isolate에서 실행한다. 큰 JPEG 재인코딩이 UI
/// 스레드를 막지 않게 하기 위함이다.
Future<Uint8List> orientCapturedPhotoInBackground(
  Uint8List imageBytes, {
  required int uiQuarterTurns,
}) {
  return compute(_orientJob, (
    bytes: imageBytes,
    uiQuarterTurns: uiQuarterTurns,
  ));
}

Uint8List _orientJob(({Uint8List bytes, int uiQuarterTurns}) job) {
  return orientCapturedPhoto(job.bytes, uiQuarterTurns: job.uiQuarterTurns);
}
