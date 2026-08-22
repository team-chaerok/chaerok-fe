import 'dart:typed_data';

import 'package:chaerok/features/film_roll/domain/entity/film_roll_photo.dart';

/// 방문 인증 사진(Photos) 파일 저장/삭제 및 메타데이터를 관리하는 리포지토리.
abstract class PhotoRepository {
  /// [imageBytes]를 앱 내부 파일 시스템에 원본/썸네일로 저장하고 메타데이터를 DB에 기록한다.
  Future<FilmRollPhoto> savePhoto({
    required String filmRollId,
    required String filmRollPlaceId,
    required Uint8List imageBytes,
    double? latitude,
    double? longitude,
  });

  /// 사진 파일(원본/썸네일)과 DB 메타데이터를 함께 삭제한다.
  Future<void> deletePhoto(String photoId);

  Future<List<FilmRollPhoto>> findByPlace(String filmRollPlaceId);

  /// 필름롤 전체에서 촬영된 사진을 최신순으로 조회한다. [limit]을 지정하면
  /// 최근 [limit]장만 반환한다(홈 화면 캐러셀처럼 전체가 아닌 미리보기용).
  Future<List<FilmRollPhoto>> findByFilmRoll(String filmRollId, {int? limit});

  /// 필름롤 전체에서 촬영된 사진 수를 센다.
  Future<int> countByFilmRoll(String filmRollId);
}
