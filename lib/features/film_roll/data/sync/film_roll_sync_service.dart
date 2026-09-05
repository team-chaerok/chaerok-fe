import 'dart:io';
import 'dart:typed_data';

import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/network/s3_put_client.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/film_roll_create_request.dart';
import 'package:chaerok/data/models/film_roll_photo_list_response.dart';
import 'package:chaerok/data/models/film_roll_response.dart';
import 'package:chaerok/data/models/photo_complete_response.dart';
import 'package:chaerok/data/models/photo_upload_url_request.dart';
import 'package:chaerok/data/models/photo_upload_url_response.dart';
import 'package:chaerok/data/models/visit_create_request.dart';
import 'package:chaerok/data/models/visit_create_response.dart';
import 'package:chaerok/data/remote/film_rolls_api.dart';
import 'package:chaerok/data/remote/visits_api.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_result.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_photo.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_place_repository.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/features/film_roll/domain/repository/photo_repository.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/region/region_normalizer.dart';
import 'package:dio/dio.dart';

const _defaultFilterStrength = 1.0;
const _photoContentType = 'image/jpeg';

/// 서버 사진 상태 중 "업로드까지는 끝난" 것으로 볼 수 있는 값들.
/// 409(이미 쓰인 sequence) 복구 시 `GET /photos`에서 이 상태의 사진을 찾는다.
const _uploadedPhotoStatuses = {'UPLOADED', 'PROCESSING', 'COMPLETED'};

/// 이번 세션에서 마지막으로 위치 인증된 지역([RegionCode]). 인증 이력이 없거나
/// 지원 지역이 아니면 null. 기본 구현은 [LocationVerificationResult.sessionCache]를 읽는다.
RegionCode? _sessionVerifiedRegion() {
  final cityCountyName =
      LocationVerificationResult.sessionCache?.region.cityCountyName;
  if (cityCountyName == null) return null;
  return RegionNormalizer.fromCityCountyName(cityCountyName);
}

Future<Uint8List> _readFileBytes(String path) => File(path).readAsBytes();

/// S3 presigned URL로 원본을 PUT하는 서명. 기본 구현은 [S3PutClient].
typedef PutPhotoToS3 =
    Future<void> Function({
      required String uploadUrl,
      required Uint8List bytes,
      required Map<String, List<String>> requiredHeaders,
    });

/// 로컬 필름롤(생성/사진/방문)을 백엔드에 반영하는 동기화 서비스.
///
/// 로컬 DB가 source of truth이며, 이 서비스는 best-effort로 다음을 순서대로 한다:
/// 1. `serverFilmRollId`가 없으면 서버에 생성(`clientFilmRollId` 멱등키 사용)
/// 2. 미업로드 사진을 S3 presigned URL로 업로드하고 서버 photoId를 로컬에 저장
/// 3. 방문 처리됐지만 미전송인 장소를 `POST /visits`(placeId + photoId)로 전송
/// 4. 서버 필름롤 status를 로컬에 미러링
///
/// 네트워크/서버 오류는 삼켜 [FilmRollSyncResult]로 요약하고, 로컬 데이터는
/// 절대 변경하지 않는다. 정적 `XxxApi` 대신 함수 타입을 주입받아 테스트한다.
class FilmRollSyncService {
  FilmRollSyncService({
    required FilmRollRepository filmRollRepository,
    required FilmRollPlaceRepository filmRollPlaceRepository,
    required PhotoRepository photoRepository,
    AppPreferences? preferences,
    Future<FilmRollResponse> Function(FilmRollCreateRequest)? createFilmRoll,
    Future<FilmRollResponse> Function(int filmRollId)? getFilmRoll,
    Future<VisitCreateResponse> Function(int filmRollId, VisitCreateRequest)?
    createVisit,
    Future<PhotoUploadUrlResponse> Function(
      int filmRollId,
      PhotoUploadUrlRequest,
    )?
    requestPhotoUploadUrl,
    Future<PhotoCompleteResponse> Function(int filmRollId, int photoId)?
    completePhotoUpload,
    Future<FilmRollPhotoListResponse> Function(int filmRollId)?
    getFilmRollPhotos,
    PutPhotoToS3? putPhotoToS3,
    Future<Uint8List> Function(String path)? readPhotoBytes,
    RegionCode? Function()? currentRegion,
  }) : _filmRollRepository = filmRollRepository,
       _placeRepository = filmRollPlaceRepository,
       _photoRepository = photoRepository,
       _preferences = preferences ?? AppPreferences.instance,
       _createFilmRoll = createFilmRoll ?? FilmRollsApi.createFilmRoll,
       _getFilmRoll = getFilmRoll ?? FilmRollsApi.getFilmRoll,
       _createVisit = createVisit ?? VisitsApi.createVisit,
       _requestPhotoUploadUrl =
           requestPhotoUploadUrl ?? FilmRollsApi.requestPhotoUploadUrl,
       _completePhotoUpload =
           completePhotoUpload ?? FilmRollsApi.completePhotoUpload,
       _getFilmRollPhotos = getFilmRollPhotos ?? FilmRollsApi.getFilmRollPhotos,
       _putPhotoToS3 = putPhotoToS3 ?? S3PutClient().put,
       _readPhotoBytes = readPhotoBytes ?? _readFileBytes,
       _currentRegion = currentRegion ?? _sessionVerifiedRegion;

  final FilmRollRepository _filmRollRepository;
  final FilmRollPlaceRepository _placeRepository;
  final PhotoRepository _photoRepository;
  final AppPreferences _preferences;
  final Future<FilmRollResponse> Function(FilmRollCreateRequest)
  _createFilmRoll;
  final Future<FilmRollResponse> Function(int) _getFilmRoll;
  final Future<VisitCreateResponse> Function(int, VisitCreateRequest)
  _createVisit;
  final Future<PhotoUploadUrlResponse> Function(int, PhotoUploadUrlRequest)
  _requestPhotoUploadUrl;
  final Future<PhotoCompleteResponse> Function(int, int) _completePhotoUpload;
  final Future<FilmRollPhotoListResponse> Function(int) _getFilmRollPhotos;
  final PutPhotoToS3 _putPhotoToS3;
  final Future<Uint8List> Function(String) _readPhotoBytes;

  /// 현재 위치가 속한 지역을 반환한다(동기화는 이 지역과 필름롤 지역이 일치할 때만).
  final RegionCode? Function() _currentRegion;

  /// [skipRegionCheck]가 true면 아래 지역 일치 검사를 건너뛴다. 지역 이탈을
  /// 확정(`exitFilmRoll`)하려는데 서버 필름롤이 아직 없는 경우처럼, 이미
  /// 필름롤 지역을 벗어난 상태에서도 서버 생성/미전송 반영이 필요한
  /// 호출부(`ExitFilmRollUseCase`)를 위한 탈출구다. 기본값은 false로, 기존
  /// 호출부(`EnterRegionUseCase`, `FilmRollController`)는 영향받지 않는다.
  Future<FilmRollSyncResult> syncFilmRoll(
    String clientFilmRollId, {
    bool skipRegionCheck = false,
  }) async {
    final filmRoll = await _filmRollRepository.findById(clientFilmRollId);
    // findById는 현재 로그인 계정으로 스코핑돼 있으므로, null이면 없는
    // 필름롤이거나 다른 계정 소유다. 어느 쪽이든 동기화하지 않는다.
    if (filmRoll == null) return const FilmRollSyncResult();

    final currentUserId = await _preferences.getCurrentUserId();
    if (currentUserId == null) return const FilmRollSyncResult();

    // 현재 위치가 이 필름롤의 지역과 일치할 때만 동기화한다. 필름 컬렉션에서
    // 다른 지역 필름롤을 열어봐도 서버 생성/방문 요청이 나가지 않도록 한다.
    // 위치 인증 이력이 없으면(sessionCache null) 확인 불가로 보고 보류한다.
    if (!skipRegionCheck && _currentRegion() != filmRoll.regionCode) {
      return const FilmRollSyncResult();
    }

    var serverId = filmRoll.serverFilmRollId;
    var created = false;

    if (serverId == null) {
      try {
        serverId = await _ensureServerFilmRoll(filmRoll);
      } on DioException catch (e) {
        if (_isClientError(e)) {
          // 이탈하지 않은 다른 CAPTURING 필름롤이 서버에 있음 — 이번엔 보류하고
          // 다음 재시도에서 따라잡는다. 오류로 취급하지 않는다.
          return const FilmRollSyncResult();
        }
        return FilmRollSyncResult(error: e);
      } catch (e) {
        return FilmRollSyncResult(error: e);
      }
      if (serverId == null) {
        // 필터 미결정 등으로 생성 보류.
        return const FilmRollSyncResult();
      }
      created = true;
    }

    final photoResult = await _pushPhotos(serverId, clientFilmRollId);
    final visitResult = await _pushVisits(
      serverId,
      clientFilmRollId,
      error: photoResult.error,
    );

    final serverStatus = await _mirrorServerStatus(serverId, clientFilmRollId);

    return FilmRollSyncResult(
      created: created,
      photosPushed: photoResult.pushed,
      photosSkipped: photoResult.skipped,
      visitsPushed: visitResult.pushed,
      visitsSkipped: visitResult.skipped,
      serverStatus: serverStatus,
      error: visitResult.error,
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // 사진 업로드
  // ─────────────────────────────────────────────────────────────────────

  Future<_PushOutcome> _pushPhotos(
    int serverFilmRollId,
    String clientFilmRollId,
  ) async {
    var pushed = 0;
    var skipped = 0;
    Object? error;

    final unuploaded = await _photoRepository.findUnuploadedByFilmRoll(
      clientFilmRollId,
    );
    for (final photo in unuploaded) {
      try {
        final serverPhotoId = await _uploadPhoto(serverFilmRollId, photo);
        if (serverPhotoId == null) {
          skipped++;
          continue;
        }
        await _photoRepository.markUploaded(
          photo.id,
          serverPhotoId: serverPhotoId,
        );
        pushed++;
      } catch (e) {
        if (_isPhotoSequenceConflict(e)) {
          final recovered = await _recoverServerPhotoId(
            serverFilmRollId,
            photo.sequence,
          );
          if (recovered != null) {
            await _photoRepository.markUploaded(
              photo.id,
              serverPhotoId: recovered,
            );
            pushed++;
            continue;
          }
        }
        if (_isPhotoUploadUnavailable(e)) {
          // S3 미설정 환경(404) 등 — 재시도해도 소용없다. 오류로 취급하지 않아
          // 지역 이탈 확정이 막히지 않게 한다.
          skipped++;
          continue;
        }
        error ??= e;
      }
    }

    return _PushOutcome(pushed: pushed, skipped: skipped, error: error);
  }

  /// upload-url 발급 → S3 PUT → complete. 서버 photoId를 반환한다.
  /// upload-url이 센티넬(빈 응답)이면 null.
  Future<int?> _uploadPhoto(int serverFilmRollId, FilmRollPhoto photo) async {
    final bytes = await _readPhotoBytes(photo.originalPath);

    final urlResponse = await _requestPhotoUploadUrl(
      serverFilmRollId,
      PhotoUploadUrlRequest(
        sequence: photo.sequence,
        contentType: _photoContentType,
        contentLength: bytes.length,
        takenAt: photo.takenAt,
      ),
    );
    if (urlResponse.photoId == 0) return null;

    await _putPhotoToS3(
      uploadUrl: urlResponse.uploadUrl,
      bytes: bytes,
      requiredHeaders: urlResponse.requiredHeaders,
    );

    // complete는 멱등이며 응답의 photoId는 upload-url이 준 것과 같다.
    await _completePhotoUpload(serverFilmRollId, urlResponse.photoId);
    return urlResponse.photoId;
  }

  /// 이미 UPLOADED라 409가 난 경우, `GET /photos`에서 같은 sequence의 서버
  /// photoId를 찾아 복구한다.
  Future<int?> _recoverServerPhotoId(int serverFilmRollId, int sequence) async {
    try {
      final list = await _getFilmRollPhotos(serverFilmRollId);
      for (final photo in list.photos) {
        if (photo.sequence == sequence &&
            _uploadedPhotoStatuses.contains(photo.status)) {
          return photo.photoId;
        }
      }
    } catch (_) {
      // 복구 조회 실패는 무시 — 다음 pass에서 다시 시도된다.
    }
    return null;
  }

  // ─────────────────────────────────────────────────────────────────────
  // 방문 전송
  // ─────────────────────────────────────────────────────────────────────

  Future<_PushOutcome> _pushVisits(
    int serverFilmRollId,
    String clientFilmRollId, {
    Object? error,
  }) async {
    var pushed = 0;
    var skipped = 0;
    var carriedError = error;

    final pending = await _placeRepository.findUnsyncedVisitedPlaces(
      clientFilmRollId,
    );
    for (final place in pending) {
      final serverPlaceId = place.serverPlaceId;
      if (serverPlaceId == null) {
        skipped++;
        continue;
      }
      // 방문 인증은 업로드된 사진 1장을 요구한다. 아직 없으면 다음 pass로 미룬다.
      final photo = await _photoRepository.findUploadedByPlace(place.id);
      final serverPhotoId = photo?.serverPhotoId;
      if (serverPhotoId == null) {
        skipped++;
        continue;
      }
      try {
        await _createVisit(
          serverFilmRollId,
          VisitCreateRequest(placeId: serverPlaceId, photoId: serverPhotoId),
        );
        await _placeRepository.markVisitSynced(place.id, at: DateTime.now());
        pushed++;
      } catch (e) {
        if (_isAlreadyVisited(e)) {
          await _placeRepository.markVisitSynced(place.id, at: DateTime.now());
          pushed++;
        } else if (_isPhotoUploadPending(e)) {
          // 업로드된 사진이 있는데도 서버가 photoId 필수(400)로 거부한 예외
          // 상황. 오류로 취급하지 않고 미동기화로 남겨 다음 pass에서 따라잡게 한다.
          skipped++;
        } else {
          carriedError ??= e;
        }
      }
    }

    return _PushOutcome(pushed: pushed, skipped: skipped, error: carriedError);
  }

  Future<String?> _mirrorServerStatus(
    int serverFilmRollId,
    String clientFilmRollId,
  ) async {
    try {
      final latest = await _getFilmRoll(serverFilmRollId);
      await _filmRollRepository.updateServerStatus(
        clientFilmRollId: clientFilmRollId,
        serverStatus: latest.status,
      );
      return latest.status;
    } catch (_) {
      // 상태 미러링 실패는 무시 — 다음 동기화에서 다시 시도된다.
      return null;
    }
  }

  /// 서버 필름롤을 생성(또는 멱등 반환)하고 로컬에 연결한다.
  /// [regionId]가 없으면 null을 반환한다(생성 보류).
  Future<int?> _ensureServerFilmRoll(FilmRoll filmRoll) async {
    final regionId = filmRoll.regionId;
    if (regionId == null) return null;

    // 필터는 지역과 1:1로 대응한다(filterId == RegionCode.name):
    //   1 gongju / 2 buyeo / 3 seosan / 4 yesan. 서버가 regionId와 filterId의
    //   일치를 요구하므로 필름롤 지역에서 직접 유도한다.
    final filterId = filmRoll.regionCode.name;

    final res = await _createFilmRoll(
      FilmRollCreateRequest(
        clientFilmRollId: filmRoll.id,
        regionId: regionId,
        filterId: filterId,
        filterStrength: _defaultFilterStrength,
      ),
    );
    await _filmRollRepository.linkServerFilmRoll(
      clientFilmRollId: filmRoll.id,
      serverFilmRollId: res.filmRollId,
      serverStatus: res.status,
      filterId: filterId,
      filterStrength: _defaultFilterStrength,
    );
    return res.filmRollId;
  }

  bool _isClientError(Object e) {
    if (e is DioException && e.error is ApiError) {
      final code = (e.error as ApiError).statusCode;
      return code >= 400 && code < 500;
    }
    return false;
  }

  /// 사진 업로드가 불가능한 환경(S3 미설정 등)이나 필름롤을 찾을 수 없어(404)
  /// 재시도가 무의미한 경우.
  bool _isPhotoUploadUnavailable(Object e) {
    return e is DioException &&
        e.error is ApiError &&
        (e.error as ApiError).statusCode == 404;
  }

  /// 같은 sequence 사진이 이미 UPLOADED라 409(`PHOTO_SEQUENCE_ALREADY_IN_USE`)가
  /// 난 경우인지.
  bool _isPhotoSequenceConflict(Object e) {
    if (e is! DioException || e.error is! ApiError) return false;
    final err = e.error as ApiError;
    if (err.statusCode != 409) return false;
    final code = (err.errorCode ?? '').toUpperCase();
    return code.contains('PHOTO_SEQUENCE') || err.message.contains('이미');
  }

  /// 업로드된 사진이 있는데도 방문 인증(`POST /visits`)이 `photoId` 필수 요건
  /// 때문에 400으로 거부된 예외 상황인지. 오류가 아니라 미동기화로 남긴다.
  bool _isPhotoUploadPending(Object e) {
    if (e is! DioException || e.error is! ApiError) return false;
    final err = e.error as ApiError;
    return err.statusCode == 400 && err.fields.contains('photoId');
  }

  /// 409이거나, 4xx이면서 메시지/코드에 중복 뉘앙스가 있으면 "이미 방문 인증됨"으로
  /// 간주해 동기화 완료로 처리한다.
  bool _isAlreadyVisited(Object e) {
    if (e is! DioException || e.error is! ApiError) return false;
    final err = e.error as ApiError;
    if (err.statusCode == 409) return true;
    if (err.statusCode >= 400 && err.statusCode < 500) {
      if (err.message.contains('이미')) return true;
      if ((err.errorCode ?? '').toUpperCase().contains('DUPLICATE')) {
        return true;
      }
    }
    return false;
  }
}

/// 사진/방문 push 한 단계의 집계.
class _PushOutcome {
  const _PushOutcome({
    required this.pushed,
    required this.skipped,
    required this.error,
  });

  final int pushed;
  final int skipped;
  final Object? error;
}
