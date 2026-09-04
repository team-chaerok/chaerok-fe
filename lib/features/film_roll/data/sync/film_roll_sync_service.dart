import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/film_roll_create_request.dart';
import 'package:chaerok/data/models/film_roll_response.dart';
import 'package:chaerok/data/models/visit_create_request.dart';
import 'package:chaerok/data/models/visit_create_response.dart';
import 'package:chaerok/data/remote/film_rolls_api.dart';
import 'package:chaerok/data/remote/visits_api.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_result.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_place_repository.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/region/region_normalizer.dart';
import 'package:dio/dio.dart';

const _defaultFilterStrength = 1.0;

/// 이번 세션에서 마지막으로 위치 인증된 지역([RegionCode]). 인증 이력이 없거나
/// 지원 지역이 아니면 null. 기본 구현은 [LocationVerificationResult.sessionCache]를 읽는다.
RegionCode? _sessionVerifiedRegion() {
  final cityCountyName =
      LocationVerificationResult.sessionCache?.region.cityCountyName;
  if (cityCountyName == null) return null;
  return RegionNormalizer.fromCityCountyName(cityCountyName);
}

/// 로컬 필름롤(생성/방문)을 백엔드에 반영하는 동기화 서비스.
///
/// 로컬 DB가 source of truth이며, 이 서비스는 best-effort로 다음을 수행한다:
/// 1. `serverFilmRollId`가 없으면 서버에 생성(`clientFilmRollId` 멱등키 사용)
/// 2. 방문 처리됐지만 미전송인 장소를 `POST /visits`로 전송
/// 3. 서버 필름롤 status를 로컬에 미러링
///
/// 네트워크/서버 오류는 삼켜 [FilmRollSyncResult]로 요약하고, 로컬 데이터는
/// 절대 변경하지 않는다. 정적 `XxxApi` 대신 함수 타입을 주입받아 테스트한다.
class FilmRollSyncService {
  FilmRollSyncService({
    required FilmRollRepository filmRollRepository,
    required FilmRollPlaceRepository filmRollPlaceRepository,
    AppPreferences? preferences,
    Future<FilmRollResponse> Function(FilmRollCreateRequest)? createFilmRoll,
    Future<FilmRollResponse> Function(int filmRollId)? getFilmRoll,
    Future<VisitCreateResponse> Function(int filmRollId, VisitCreateRequest)?
    createVisit,
    RegionCode? Function()? currentRegion,
  }) : _filmRollRepository = filmRollRepository,
       _placeRepository = filmRollPlaceRepository,
       _preferences = preferences ?? AppPreferences.instance,
       _createFilmRoll = createFilmRoll ?? FilmRollsApi.createFilmRoll,
       _getFilmRoll = getFilmRoll ?? FilmRollsApi.getFilmRoll,
       _createVisit = createVisit ?? VisitsApi.createVisit,
       _currentRegion = currentRegion ?? _sessionVerifiedRegion;

  final FilmRollRepository _filmRollRepository;
  final FilmRollPlaceRepository _placeRepository;
  final AppPreferences _preferences;
  final Future<FilmRollResponse> Function(FilmRollCreateRequest)
  _createFilmRoll;
  final Future<FilmRollResponse> Function(int) _getFilmRoll;
  final Future<VisitCreateResponse> Function(int, VisitCreateRequest)
  _createVisit;

  /// 현재 위치가 속한 지역을 반환한다(동기화는 이 지역과 필름롤 지역이 일치할 때만).
  final RegionCode? Function() _currentRegion;

  /// [skipRegionCheck]가 true면 아래 지역 일치 검사를 건너뛴다. 지역 이탈을
  /// 확정(`exitFilmRoll`)하려는데 서버 필름롤이 아직 없는 경우처럼, 이미
  /// 필름롤 지역을 벗어난 상태에서도 서버 생성/미전송 방문 반영이 필요한
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

    var visitsPushed = 0;
    var visitsSkipped = 0;
    Object? error;

    final pending = await _placeRepository.findUnsyncedVisitedPlaces(
      clientFilmRollId,
    );
    for (final place in pending) {
      final serverPlaceId = place.serverPlaceId;
      if (serverPlaceId == null) {
        visitsSkipped++;
        continue;
      }
      try {
        await _createVisit(
          serverId,
          VisitCreateRequest(placeId: serverPlaceId),
        );
        await _placeRepository.markVisitSynced(place.id, at: DateTime.now());
        visitsPushed++;
      } catch (e) {
        if (_isAlreadyVisited(e)) {
          await _placeRepository.markVisitSynced(place.id, at: DateTime.now());
          visitsPushed++;
        } else {
          error ??= e;
        }
      }
    }

    // TODO(필름롤-사진업로드): 백엔드가 "사진 1장씩 업로드" API를 추가하면
    //   여기서 이 필름롤의 Photos 중 isSynced == false 인 항목을 순회하며
    //   serverId로 전송하고 성공 시 isSynced = true 로 표시한다.
    //   명세/범위: docs/superpowers/specs/2026-08-30-filmroll-backend-sync-design.md §7.6

    String? serverStatus;
    try {
      final latest = await _getFilmRoll(serverId);
      serverStatus = latest.status;
      await _filmRollRepository.updateServerStatus(
        clientFilmRollId: clientFilmRollId,
        serverStatus: latest.status,
      );
    } catch (_) {
      // 상태 미러링 실패는 무시 — 다음 동기화에서 다시 시도된다.
    }

    return FilmRollSyncResult(
      created: created,
      visitsPushed: visitsPushed,
      visitsSkipped: visitsSkipped,
      serverStatus: serverStatus,
      error: error,
    );
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

  /// 오픈 질문 3 확정 전까지: 409이거나, 4xx이면서 메시지/코드에 중복 뉘앙스가
  /// 있으면 "이미 방문 인증됨"으로 간주해 동기화 완료로 처리한다.
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
