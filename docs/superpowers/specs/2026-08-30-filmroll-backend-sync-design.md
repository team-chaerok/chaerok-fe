# 필름롤 백엔드 동기화 (1차: 생성 + 방문) 설계

작성일: 2026-08-30
관련 이슈: #41 (로컬 필름롤 아키텍처) 후속, #61 (홈 화면 API 연동 점검)
선행 문서: `docs/suh-template/plan/20260730_20260729_로컬_필름롤_아키텍처_전략.md`

## 1. 배경

현재 필름롤/코스/방문/사진은 전부 로컬(Drift + 파일 시스템)에서만 처리된다. 이는
이슈 #41에서 "오프라인에서도 조회·방문·촬영이 끊기지 않아야 한다"는 요구로 내린
의도적 결정이며, 서버 동기화는 `isSynced` 필드만 예약해두고 미구현 상태다.

`FilmRollsApi` / `VisitsApi` 는 정의되어 있으나 **어디서도 호출되지 않는다**. 서버
필름롤 모델(`filterId`·`status`·`maxPhotoCount`·현상 파이프라인 등)은 로컬 모델
(코스 추종·방문 체크·로컬 사진)과 도메인이 다르다.

## 2. 목표 (이번 pass 범위)

로컬을 계속 source of truth로 두되, **필름롤 생성과 방문 기록을 서버에 반영**하는
동기화 계층을 추가한다.

- 로컬 UUID = `clientFilmRollId` (변경 없음)
- 서버 생성 성공 시 응답 `filmRollId` → 같은 로컬 행의 `serverFilmRollId`에 저장
- 생성 재시도 시 새 UUID 만들지 않고 기존 UUID 재사용
- 방문 기록(`isVisited`)을 `POST /api/film-rolls/{serverFilmRollId}/visits`로 전송
- `serverFilmRollId == null`이어도 로컬 촬영/방문은 정상 동작, 이후 재시도로 따라잡음
- 현재 진행 중 롤 판단은 계속 로컬 기준 (`GET /film-rolls/current` 판단용 미사용)
- 서버 `status`는 로컬에 미러링만 하고 노출 (완료 게이팅 로직 변경은 이번 pass 아님)

## 3. 비목표 (다음 pass)

- **사진 서버 업로드** — 백엔드가 "사진 한 장씩 업로드하는 API"를 추가하기로
  합의됨. 엔드포인트 명세가 아직 안 나왔으므로 이번 pass에서는 **TODO로만
  남기고 구현하지 않는다** (§7.6 참고). 사진은 계속 로컬에만 저장된다.
- `exitFilmRoll` / 현상(develop) 트리거 / 처리 상태 폴링 / 결과 조회
- 서버 상태 기반 `completeFilmRoll` 게이팅 전환 (exit/develop 선행 필요)
- 오프라인 아웃박스 큐 (작업 종류 2개, 보류 상태를 행에서 도출 가능 → YAGNI)
- 기기 변경/재설치 시 데이터 복원 (서버→로컬 방향)

## 4. 접근 방식: 전용 `FilmRollSyncService`

리포지토리는 순수 로컬로 유지한다. `lib/features/film_roll/data/sync/` 아래에
서비스를 두고 `FilmRollsApi` + `VisitsApi` + `FiltersApi`를 조합한다. "무엇을
동기화할지"는 별도 큐 없이 행 컬럼으로 판단한다.

### 4.1 진입점

```dart
class FilmRollSyncService {
  /// 지정 로컬 필름롤을 서버와 동기화한다. best-effort — 네트워크/서버 오류는
  /// 삼키고 [FilmRollSyncResult]로 요약해 반환한다. 예외를 던지지 않는다.
  Future<FilmRollSyncResult> syncFilmRoll(String clientFilmRollId);
}

class FilmRollSyncResult {
  final bool created;          // 이번 호출에서 서버 생성 성공
  final int visitsPushed;      // 이번 호출에서 새로 전송된 방문 수
  final int visitsSkipped;     // serverPlaceId 없어 못 보낸 방문 수
  final String? serverStatus;  // 미러링된 서버 status (조회 실패 시 null)
  final Object? error;         // 치명 오류 (있으면 부분 실패)
}
```

### 4.2 동작 순서

`syncFilmRoll(clientId)`:

1. 로컬 행 조회. 없거나 `userId`가 현재 계정과 다르면 즉시 반환.
2. **생성**: `serverFilmRollId == null`이면
   - 필터 결정 (§5.3). 결정 불가 시 이번 호출 중단(다음 재시도).
   - 행에 `filterId` / `filterStrength` 저장 (재현 가능하게).
   - `FilmRollsApi.createFilmRoll(FilmRollCreateRequest(regionId, filterId, filterStrength))`.
   - 성공 → `serverFilmRollId`, `serverStatus` 저장.
   - **생성 충돌** (서버에 이미 미완료 롤 존재, §6.1) → `getCurrentFilmRoll()`
     1회 호출. `regionId`가 로컬 행과 일치하면 그 `filmRollId`를 채택. 불일치면
     연동하지 않고 로그만 남긴다 (이 롤은 서버 롤이 종료될 때까지 미동기화).
3. **방문 전송**: `serverFilmRollId != null`이면, 다음 조건의 로컬 장소마다
   `VisitsApi.createVisit(serverFilmRollId, VisitCreateRequest(placeId: serverPlaceId))`:
   - `isVisited == true`
   - `visitSyncedAt == null`
   - `serverPlaceId != null`  (null이면 `visitsSkipped++`, 로그)
   - 성공 또는 "이미 방문함" 응답(§6.2) → `visitSyncedAt = now`
   - 그 외 오류 → 해당 장소는 미동기화 유지, 다음 장소 계속
4. **상태 미러링**: `serverFilmRollId != null`이면 `getFilmRoll(serverFilmRollId)`
   호출, `serverStatus` 문자열 저장. 실패는 무시.

모든 서버 호출은 `ApiError`(DioException 래핑)로 실패할 수 있고, 서비스는 이를
잡아 결과에 요약한다. 화면은 실패해도 로컬 데이터로 계속 동작한다.

### 4.3 트리거 지점

| 시점 | 방식 |
|---|---|
| `EnterRegionUseCase` 성공 직후 | fire-and-forget `unawaited(sync)` |
| `CompleteVisitUseCase` 성공 직후 (Controller에서) | fire-and-forget |
| `FilmRollScreen` 로드 시 (`FilmRollController.load` 끝) | fire-and-forget |
| 화면의 수동 "동기화 재시도" (부분 실패 시 노출) | await + 스낵바 피드백 |

앱 전역 lifecycle observer는 이번 pass에서 추가하지 않는다 (현재 그런 인프라
없음, `visit_capture_screen`만 자체 observer 보유). 앱 재개 트리거는 다음 pass.

## 5. 데이터 모델 변경

### 5.1 스키마 마이그레이션 (v3 → v4)

`FilmRolls` 컬럼 추가 (모두 nullable):

| 컬럼 | 타입 | 용도 |
|---|---|---|
| `regionId` | int? | 서버 생성 요청용. 로컬 생성 시 화면에서 전달받아 저장 |
| `filterId` | text? | 서버 생성에 쓴 필터. 재현/디버깅용 |
| `filterStrength` | real? | 위와 동일 |
| `serverFilmRollId` | int? | 서버 필름롤 PK. null = 미생성 |
| `serverStatus` | text? | 마지막으로 미러링한 서버 status 원문 |

`FilmRollPlaces` 컬럼 추가:

| 컬럼 | 타입 | 용도 |
|---|---|---|
| `visitSyncedAt` | dateTime? | 방문이 서버에 반영된 시각. null = 미전송 |

`local_database.dart`: `schemaVersion` 3 → 4, `onUpgrade`에 `if (from < 4)`로
`m.addColumn` 6개. 기존 인덱스/제약 변경 없음. `local_database.g.dart` 재생성.

### 5.2 엔티티 / 매퍼

- `FilmRoll` 엔티티: `regionId`(int?), `serverFilmRollId`(int?), `serverStatus`(String?) 필드 추가. `copyWith`에도 반영.
- `FilmRollMapper.toEntity`: 새 필드 매핑.
- `FilmRollPlace` 엔티티: `visitSyncedAt`(DateTime?) 필드 추가.
- `FilmRollPlaceMapper`: 새 필드 매핑.

### 5.3 필터 기본값

로컬 생성 시점에는 필터를 모른다. `syncFilmRoll`이 생성 직전 JIT로 결정:

1. `AppPreferences.getDefaultFilterId()` 캐시 확인
2. 없으면 `FiltersApi.getFilters()` → `[0].filterId` 사용, 캐시에 저장
3. `filterStrength`는 상수 `1.0`
4. 필터 조회 실패 + 캐시 없음 → 생성 보류 (필터 없이 생성 불가), 다음 재시도

`AppPreferences`에 `getDefaultFilterId()` / `setDefaultFilterId(String?)` 추가
(`shared_preferences`, 키 `default_filter_id`).

## 6. 오류 / 멱등성

### 6.1 생성 충돌

`createFilmRoll`은 idempotency key를 받지 않는다 (`{regionId, filterId,
filterStrength}`만). 응답 유실 후 재시도하면 서버가 중복을 구분할 수 없다.
서버는 "미완료 롤이 이미 있으면 생성 불가"로 거절한다.

- **구현 기본값**: 생성이 4xx로 거절되면 `getCurrentFilmRoll()`을 1회 호출해
  `regionId` 일치 시 `serverFilmRollId`를 채택한다. 불일치 시 미연동.
- 이는 "현재 롤 판단"이 아니라 "생성 충돌 복구" 용도의 제한적 사용이다.
- 거절을 정확히 식별하려면 `ApiError.errorCode` 값이 필요하다 → **오픈 질문**.
  값을 모르면 "생성 호출이 4xx면 복구 시도"로 넓게 잡는다.

### 6.2 방문 중복

서버는 "같은 필름롤의 같은 장소는 한 번만 인증"이다. 재전송 시 중복 응답을
받으면 그것도 성공으로 간주하고 `visitSyncedAt`을 채운다. 식별에 `errorCode`
또는 특정 status(409 등)가 필요 → **오픈 질문**. 모르면 "이미 방문" 계열
메시지/코드를 넓게 매칭하고, 애매하면 미동기화로 남겨 다음 재시도.

### 6.3 계정 전환

동기화는 항상 로컬 행의 `userId`가 현재 계정(`AppPreferences.currentUserId`)과
일치할 때만 수행한다. 불일치 행은 건너뛴다.

## 7. 오픈 질문 (백엔드 협의 필요)

1. **생성 멱등성**: `createFilmRoll`에 clientFilmRollId(멱등키)를 받게 할 수
   있나? 안 되면 §6.1의 `/current` 복구 방식으로 확정.
2. **생성 충돌 식별**: 미완료 롤 존재 거절 시 HTTP status / `errorCode` 값?
3. **방문 중복 식별**: 중복 방문 인증 시 HTTP status / `errorCode` 값?
4. **완료 status 토큰**: 서버 `status`가 "현상 완료"를 나타내는 정확한 문자열?
   (미완료 집합은 CAPTURING/READY/QUEUED/PROCESSING/FAILED로 문서에 있음)
5. `regionId` 매핑: 로컬 `RegionCode`(gongju/buyeo/seosan/yesan) ↔ 서버
   `regionId` 대응이 고정인가? (현재는 화면에서 `resolveRegion`으로 획득)
6. **사진 업로드 API** (추가 합의됨, 명세 대기): "사진 한 장씩 업로드"
   엔드포인트의 경로 / 메서드 / 요청 형태(multipart vs presigned URL) /
   요청 필드(이미지, `takenAt`, `sequence` 또는 `placeId`, 멱등키 여부) /
   응답(`photoId` 등). 명세 확보 시 별도 pass에서 `syncFilmRoll`에 사진 전송
   단계를 추가하고 `Photos.isSynced`(기예약 컬럼)를 실제로 사용한다.

이번 pass는 1~3에 대해 위 "기본값" 동작으로 구현하고, 값이 확정되면 좁힌다.
4는 미러링만 하므로 당장 불필요, 5는 화면 전달값을 그대로 저장, 6은 TODO.

### 7.1 사진 업로드 TODO 표식 (이번 pass에서 코드에 남길 것)

`FilmRollSyncService.syncFilmRoll`의 방문 전송 단계 다음, 상태 미러링 앞에
아래 형태의 주석 표식을 남긴다 (구현 없음):

```dart
// TODO(#필름롤-사진업로드): 백엔드가 "사진 1장씩 업로드" API를 추가하면
//   여기서 Photos 중 isSynced == false 인 항목을 순회하며 전송하고
//   성공 시 isSynced = true 로 표시한다. 명세: spec §7.6.
```

`Photos` 테이블에는 이미 `isSynced`(기본 false) 컬럼이 있으므로 스키마 변경은
불필요하다. `PhotoRepository` / `PhotoLocalDataSource`에 `findUnsynced` /
`markSynced` 를 추가하는 것도 그 pass에서 한다 (이번 pass 아님).

## 8. 테스트 전략

`FilmRollSyncService`는 정적 `XxxApi` 대신 **함수 타입 파라미터**를 주입받아
테스트한다 (`FilmRollController`가 use case를 주입받는 패턴과 동일).

```dart
FilmRollSyncService({
  required AppDatabase db,
  Future<FilmRollResponse> Function(FilmRollCreateRequest)? createFilmRoll,
  Future<FilmRollResponse?> Function()? getCurrentFilmRoll,
  Future<FilmRollResponse> Function(int)? getFilmRoll,
  Future<VisitCreateResponse> Function(int, VisitCreateRequest)? createVisit,
  Future<List<FilterResponse>> Function()? getFilters,
  AppPreferences? preferences,
});
```

기본값은 각 정적 메서드 tear-off. 테스트는 `AppDatabase.forTesting`
(인메모리) + 가짜 함수로 다음을 검증:

- 신규 롤: 생성 호출 1회, `serverFilmRollId` 저장됨
- `serverFilmRollId` 이미 있음: 생성 호출 안 함, 방문만 전송
- 방문 전송: `isVisited && serverPlaceId != null`만, 성공 시 `visitSyncedAt` 세팅
- `serverPlaceId == null` 방문: 건너뜀, `visitsSkipped` 카운트
- 생성 충돌 → `getCurrentFilmRoll` 1회 → regionId 일치 시 채택 / 불일치 시 미연동
- 방문 중복 응답 → `visitSyncedAt` 채움
- 네트워크 오류 → 예외 안 던짐, `result.error` 채워짐, 로컬 데이터 불변
- 계정 불일치 행 → 아무 API도 호출 안 함
- 필터 캐시 없음 + `getFilters` 실패 → 생성 보류

마이그레이션: v3 DB에서 v4로 열었을 때 새 컬럼이 존재하고 기존 행이 보존되는지
테스트 (`drift`의 스키마 테스트 유틸 또는 수동 addColumn 검증).

## 9. 변경 파일 요약

**신규**
- `lib/features/film_roll/data/sync/film_roll_sync_service.dart`
- `lib/features/film_roll/data/sync/film_roll_sync_result.dart`
- `test/features/film_roll/sync/film_roll_sync_service_test.dart`
- `test/core/database/migration_v4_test.dart`

**수정**
- `lib/core/database/tables/film_rolls_table.dart` (+5 컬럼)
- `lib/core/database/tables/film_roll_places_table.dart` (+1 컬럼)
- `lib/core/database/local_database.dart` (schemaVersion 4, onUpgrade)
- `lib/core/database/local_database.g.dart` (재생성)
- `lib/core/config/app_preferences.dart` (defaultFilterId)
- `lib/features/film_roll/domain/entity/film_roll.dart` (+3 필드)
- `lib/features/film_roll/data/model/film_roll_mapper.dart`
- `lib/features/film_roll/domain/entity/film_roll_place.dart` (+1 필드)
- `lib/features/film_roll/data/model/film_roll_place_mapper.dart`
- `lib/features/film_roll/domain/repository/film_roll_repository.dart`
  (`findOrCreateActiveByRegion`에 `regionId`, 서버 연동 저장 메서드 추가)
- `lib/features/film_roll/data/repository/film_roll_repository_impl.dart`
- `lib/features/film_roll/data/local/film_roll_local_data_source.dart`
- `lib/features/film_roll/data/local/film_roll_place_local_data_source.dart`
  (`findUnsyncedVisitedPlaces`, `markVisitSynced`)
- `lib/features/film_roll/domain/usecase/enter_region_use_case.dart` (+regionId, sync 트리거)
- `lib/features/film_roll/film_roll_module.dart` (sync 서비스 조립, regionId 전달)
- `lib/features/film_roll/presentation/controller/film_roll_controller.dart`
  (load/completeVisit 후 sync, 수동 재시도 노출)
- `lib/features/film_roll/presentation/page/film_roll_screen.dart` (재시도 어피던스 - 최소)
- `lib/features/home/presentation/home_dashboard_screen.dart` (enterRegion에 regionId)
- `lib/features/explore/presentation/explore_screen.dart` (enterRegion에 regionId)

## 10. 리스크

- **생성 멱등성 부재** (§6.1): 백엔드가 멱등키를 안 받으면 `/current` 복구가
  유일한 방법이고, 이는 사용자 지시의 취지("판단용 미사용")와 경계선에 있다.
  오픈 질문 1·2 해소 전까지 이 방식으로 진행.
- **드리프트 코드젠**: `local_database.g.dart` 재생성 필요 (`dart run build_runner`).
  CI/로컬 빌드에서 확인.
- 서버 status가 실제로 진전하지 않는 상태(exit/develop 미구현)라 `serverStatus`
  미러링은 당분간 CAPTURING 고정. 다음 pass 전까지 표시 가치 낮음 — 저장만.
- **사진 로컬-only 유지** (§3, §7.6): 이번 pass 이후에도 사진이 서버에 올라가지
  않으므로, 기기 변경/재설치/앱 삭제 시 사진 소실. 백엔드 "1장씩 업로드" API가
  나오면 후속 pass에서 해소. 그 전까지는 이슈 #41과 동일한 알려진 제약.
