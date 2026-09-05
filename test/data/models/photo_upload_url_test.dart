import 'package:chaerok/data/models/photo_upload_url_request.dart';
import 'package:chaerok/data/models/photo_upload_url_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhotoUploadUrlRequest', () {
    test('takenAt를 타임존·밀리초 없는 로컬 문자열로 직렬화한다', () {
      final req = PhotoUploadUrlRequest(
        sequence: 2,
        contentType: 'image/jpeg',
        contentLength: 2097152,
        takenAt: DateTime(2026, 9, 6, 14, 30, 5, 999),
      );

      expect(req.toJson(), {
        'sequence': 2,
        'contentType': 'image/jpeg',
        'contentLength': 2097152,
        'takenAt': '2026-09-06T14:30:05',
      });
    });

    test('한 자리 월/일/시도 0으로 채운다', () {
      expect(
        PhotoUploadUrlRequest.formatTakenAt(DateTime(2026, 1, 2, 3, 4, 5)),
        '2026-01-02T03:04:05',
      );
    });
  });

  group('PhotoUploadUrlResponse', () {
    test('requiredHeaders를 List<String> 맵으로 정규화한다', () {
      final res = PhotoUploadUrlResponse.fromJson({
        'photoId': 101,
        'filmRollId': 55,
        'sequence': 1,
        'objectKey': 'users/1/film-rolls/55/photos/1/original.jpg',
        'uploadUrl': 'https://bucket.s3.example.com/...&X-Amz-Signature=sig',
        'expiresAt': '2026-09-06T14:35:00Z',
        'requiredHeaders': {
          'content-type': ['image/jpeg'],
          'content-length': ['2097152'],
        },
      });

      expect(res.photoId, 101);
      expect(res.requiredHeaders['content-type'], ['image/jpeg']);
      expect(res.requiredHeaders['content-length'], ['2097152']);
    });

    test('스칼라 헤더 값도 단일 원소 리스트로 감싼다', () {
      final res = PhotoUploadUrlResponse.fromJson({
        'photoId': 1,
        'filmRollId': 1,
        'sequence': 1,
        'objectKey': 'k',
        'uploadUrl': 'u',
        'expiresAt': '2026-09-06T14:35:00Z',
        'requiredHeaders': {'content-type': 'image/jpeg'},
      });

      expect(res.requiredHeaders['content-type'], ['image/jpeg']);
    });

    test('empty()는 photoId 0 센티넬', () {
      expect(PhotoUploadUrlResponse.empty().photoId, 0);
    });
  });
}
