import 'package:chaerok/core/network/dio_client.dart';
import 'package:chaerok/data/models/film_roll_create_request.dart';
import 'package:chaerok/data/models/film_roll_exit_response.dart';
import 'package:chaerok/data/models/film_roll_photo_list_response.dart';
import 'package:chaerok/data/models/film_roll_response.dart';
import 'package:chaerok/data/models/photo_complete_response.dart';
import 'package:chaerok/data/models/photo_upload_url_request.dart';
import 'package:chaerok/data/models/photo_upload_url_response.dart';

/// FilmRollsApi 클래스는 필름 롤(FilmRoll) 리소스 관련 API 호출을 제공합니다.
class FilmRollsApi {
  const FilmRollsApi._();

  /// [필름 롤 생성] API 호출
  /// FE 로컬 FilmRoll의 clientFilmRollId로 서버 FilmRoll을 생성한다.
  /// 같은 사용자와 clientFilmRollId 재요청은 기존 FilmRoll을 반환한다.
  /// 이탈하지 않은 CAPTURING FilmRoll이 이미 있을 때만 새로운 FilmRoll 생성을 제한한다.
  /// 로그인 사용자의 촬영용 필름 롤을 생성한다. 사용자에게 이미 미완료 필름 롤이
  /// 있으면 새 필름 롤을 생성할 수 없다. FAILED 상태도 재시도 가능한 미완료
  /// 상태에 포함된다.
  static Future<FilmRollResponse> createFilmRoll(
    FilmRollCreateRequest request,
  ) async {
    final response = await DioClient.instance.post<FilmRollResponse>(
      '/api/film-rolls',
      data: request.toJson(),
      fromJson: (data) =>
          FilmRollResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? FilmRollResponse.empty();
  }

  /// [필름 롤 지역 이탈 확정] API 호출
  /// 프론트에서 GPS와 행정구역 판정을 완료하고 사용자가 지역 이탈을 확인한 뒤
  /// 호출한다. 백엔드는 좌표를 받지 않고 이탈 확정 시각을 저장한다. Visit 3유형
  /// 조건과 사진 1장 이상을 모두 충족한 CAPTURING 필름 롤은 1시간 뒤 현상을
  /// 예약한다. 이탈 시점에 두 조건 중 하나라도 부족하면 이탈 사실만 기록하고
  /// EXPIRED로 종료한다.
  static Future<FilmRollExitResponse> exitFilmRoll(int filmRollId) async {
    final response = await DioClient.instance.post<FilmRollExitResponse>(
      '/api/film-rolls/$filmRollId/exit',
      fromJson: (data) =>
          FilmRollExitResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? FilmRollExitResponse.empty();
  }

  /// [필름 롤 상세 조회] API 호출
  /// 로그인 사용자가 소유한 필름 롤의 현재 상태를 조회한다.
  static Future<FilmRollResponse> getFilmRoll(int filmRollId) async {
    final response = await DioClient.instance.get<FilmRollResponse>(
      '/api/film-rolls/$filmRollId',
      fromJson: (data) =>
          FilmRollResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? FilmRollResponse.empty();
  }

  /// [필름 롤 사진 목록 조회] API 호출
  /// 사용자가 소유한 필름 롤의 사진을 순서대로 조회한다. 촬영 중 앱 재진입과
  /// 업로드 진행상태 복구에 사용할 수 있다. S3 객체 키와 다운로드 URL은
  /// 노출하지 않는다.
  static Future<FilmRollPhotoListResponse> getFilmRollPhotos(
    int filmRollId,
  ) async {
    final response = await DioClient.instance.get<FilmRollPhotoListResponse>(
      '/api/film-rolls/$filmRollId/photos',
      fromJson: (data) =>
          FilmRollPhotoListResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? FilmRollPhotoListResponse.empty();
  }

  /// [사진 업로드 URL 발급] API 호출
  /// 서버가 S3 presigned PUT URL과 함께 photoId를 발급한다. 같은 sequence가
  /// UPLOADING이면 같은 photoId로 URL만 재발급되고, 이미 UPLOADED면 409다.
  static Future<PhotoUploadUrlResponse> requestPhotoUploadUrl(
    int filmRollId,
    PhotoUploadUrlRequest request,
  ) async {
    final response = await DioClient.instance.post<PhotoUploadUrlResponse>(
      '/api/film-rolls/$filmRollId/photos/upload-url',
      data: request.toJson(),
      fromJson: (data) =>
          PhotoUploadUrlResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? PhotoUploadUrlResponse.empty();
  }

  /// [사진 업로드 완료 확인] API 호출
  /// S3 PUT 성공 후 호출한다. 서버가 HeadObject로 검증 후 UPLOADED로 전환한다.
  /// 멱등: 이미 UPLOADED면 카운트 증가 없이 같은 응답을 준다.
  static Future<PhotoCompleteResponse> completePhotoUpload(
    int filmRollId,
    int photoId,
  ) async {
    final response = await DioClient.instance.post<PhotoCompleteResponse>(
      '/api/film-rolls/$filmRollId/photos/$photoId/complete',
      fromJson: (data) =>
          PhotoCompleteResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? PhotoCompleteResponse.empty();
  }

  /// [현재 진행 중인 필름 롤 조회] API 호출
  /// 로그인 사용자의 미완료 필름 롤을 조회한다. 미완료 상태는 CAPTURING, READY,
  /// QUEUED, PROCESSING, FAILED다. 진행 중인 필름 롤이 없으면 서버가 204 No
  /// Content를 반환하며, 이 경우 null을 반환한다.
  static Future<FilmRollResponse?> getCurrentFilmRoll() async {
    final response = await DioClient.instance.get<FilmRollResponse>(
      '/api/film-rolls/current',
      fromJson: (data) =>
          FilmRollResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data;
  }
}
