import 'package:chaerok/data/models/api_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson은 errors[].field를 fields 목록으로 뽑고 code를 errorCode로 읽는다', () {
    final error = ApiError.fromJson({
      'code': 'COMMON_001',
      'message': '요청값이 올바르지 않습니다.',
      'path': '/api/film-rolls/37/visits',
      'errors': [
        {'field': 'photoId', 'message': '방문 인증 사진 ID는 필수입니다.'},
      ],
    }, 400);

    expect(error.statusCode, 400);
    expect(error.errorCode, 'COMMON_001');
    expect(error.fields, ['photoId']);
  });

  test('errors가 없으면 fields는 빈 목록이고 errorCode는 errorCode 키를 우선한다', () {
    final error = ApiError.fromJson({
      'errorCode': 'AUTH_001',
      'code': 'IGNORED',
      'message': '인증이 필요합니다.',
    }, 401);

    expect(error.fields, isEmpty);
    expect(error.errorCode, 'AUTH_001');
  });
}
