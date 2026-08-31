# 필름롤 백엔드 동기화 (1차: 생성 + 방문) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 로컬을 source of truth로 유지한 채, 필름롤 생성과 방문 기록을 백엔드(`FilmRollsApi`/`VisitsApi`)에 반영하는 동기화 계층을 추가한다.

**Architecture:** 리포지토리는 순수 로컬로 두고, 별도 `FilmRollSyncService`가 서버 API를 조합한다. "무엇을 동기화할지"는 큐 테이블 없이 로컬 행 컬럼(`serverFilmRollId`, `visitSyncedAt`)으로 도출한다. 동기화는 best-effort — 실패해도 예외를 던지지 않고 로컬 동작에 영향을 주지 않으며, 정해진 트리거 지점에서 fire-and-forget으로 호출된다.

**Tech Stack:** Flutter / Dart, Drift (로컬 DB, build_runner 코드젠), Dio (`DioClient`), shared_preferences. 신규 의존성 없음.

**Spec:** `docs/superpowers/specs/2026-08-30-filmroll-backend-sync-design.md`

## Global Constraints

- 신규 패키지 추가 금지 (기존 `drift`, `dio`, `shared_preferences`만 사용).
- 상태관리 라이브러리 도입 금지 — 기존 `StatefulWidget` + `setState` + Controller 패턴 유지.
- `GET /api/film-rolls/current`는 이번 pass에서 **일절 호출하지 않는다**. 생성은 `clientFilmRollId` 멱등키로 처리되고, 현재 진행 롤 판단은 로컬 기준.
- 동기화는 로컬 행의 `userId`가 `AppPreferences.getCurrentUserId()`와 일치할 때만 수행.
- `FilmRollSyncService`의 공개 메서드는 예외를 던지지 않는다 (결과 객체로 요약).
- 서버 호출 실패로 로컬 DB 상태가 바뀌면 안 된다.
- 디자인 토큰(`ChaerokSpacing`/`ChaerokColors`/`ChaerokTypography`) 사용, px 하드코딩 금지 (UI 변경 시).
- `filterStrength` 기본값 상수 `1.0`.
- 코드/주석 스타일은 주변 파일을 따른다 (한국어 도메인 주석).
- **사진 업로드는 이번 계획 범위 밖.** 백엔드가 "사진 1장씩 업로드" API를
  추가하기로 합의됐으나 명세 미확보 → Task 8에서 `syncFilmRoll`에 `TODO` 주석
  표식만 남기고 구현하지 않는다 (spec §7.6). `Photos` 테이블/`PhotoRepository`
  변경 없음.

---

## File Structure

**신규**
- `lib/features/film_roll/data/sync/film_roll_sync_result.dart` — 동기화 결과 값 객체
- `lib/features/film_roll/data/sync/film_roll_sync_service.dart` — 동기화 핵심 로직
- `test/features/film_roll/sync/film_roll_sync_service_test.dart`
- `test/core/database/migration_v4_test.dart`

**수정 (책임)**
- `lib/core/database/tables/film_rolls_table.dart` — `regionId`/`filterId`/`filterStrength`/`serverFilmRollId`/`serverStatus` 컬럼
- `lib/core/database/tables/film_roll_places_table.dart` — `visitSyncedAt` 컬럼
- `lib/core/database/local_database.dart` — `schemaVersion` 4, `onUpgrade` v4 분기
- `lib/core/database/local_database.g.dart` — build_runner 재생성 (수기 편집 금지)
- `lib/core/config/app_preferences.dart` — `defaultFilterId` 접근자
- `lib/data/models/film_roll_create_request.dart` — `clientFilmRollId` 필드 + `toJson`
- `lib/features/film_roll/domain/entity/film_roll.dart` — `regionId`/`serverFilmRollId`/`serverStatus`
- `lib/features/film_roll/data/model/film_roll_mapper.dart`
- `lib/features/film_roll/domain/entity/film_roll_place.dart` — `visitSyncedAt`
- `lib/features/film_roll/data/model/film_roll_place_mapper.dart`
- `lib/features/film_roll/domain/repository/film_roll_repository.dart` — `findOrCreateActiveByRegion(regionId)`, `linkServerFilmRoll`, `updateServerStatus`
- `lib/features/film_roll/data/repository/film_roll_repository_impl.dart`
- `lib/features/film_roll/data/local/film_roll_local_data_source.dart`
- `lib/features/film_roll/data/local/film_roll_place_local_data_source.dart` — `findUnsyncedVisitedPlaces`, `markVisitSynced`
- `lib/features/film_roll/domain/repository/film_roll_place_repository.dart` — 위 두 메서드 노출
- `lib/features/film_roll/data/repository/film_roll_place_repository_impl.dart`
- `lib/features/film_roll/domain/usecase/enter_region_use_case.dart` — `regionId` 파라미터 + sync 트리거
- `lib/features/film_roll/film_roll_module.dart` — sync 서비스 조립, `enterRegion` 시그니처
- `lib/features/film_roll/presentation/controller/film_roll_controller.dart` — load/completeVisit 후 sync, `retrySync`
- `lib/features/film_roll/presentation/page/film_roll_screen.dart` — 동기화 실패 시 재시도 어피던스
- `lib/features/home/presentation/home_dashboard_screen.dart` — `enterRegion(..., regionId:)`
- `lib/features/explore/presentation/explore_screen.dart` — `enterRegion(..., regionId:)`

---

## Task 1: 스키마 v4 마이그레이션 (컬럼 추가)

**Files:**
- Modify: `lib/core/database/tables/film_rolls_table.dart`
- Modify: `lib/core/database/tables/film_roll_places_table.dart`
- Modify: `lib/core/database/local_database.dart:27` (schemaVersion), `:36-54` (onUpgrade)
- Regenerate: `lib/core/database/local_database.g.dart`
- Test: `test/core/database/migration_v4_test.dart`

**Interfaces:**
- Produces: `FilmRollRow` gains nullable `regionId int?`, `filterId String?`, `filterStrength double?`, `serverFilmRollId int?`, `serverStatus String?`. `FilmRollPlaceRow` gains nullable `visitSyncedAt DateTime?`. `AppDatabase.schemaVersion == 4`.

- [ ] **Step 1: 마이그레이션 실패 테스트 작성**

`test/core/database/migration_v4_test.dart`:

```dart
import 'package:chaerok/core/database/local_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('v4 스키마: 신규 컬럼이 존재하고 기본값은 null', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // 스키마가 열리면 schemaVersion이 4여야 한다.
    expect(db.schemaVersion, 4);

    // 새 컬럼을 포함한 insert가 성공해야 한다.
    await db.into(db.filmRolls).insert(
      FilmRollsCompanion.insert(
        id: 't1',
        regionCode: RegionCode.gongju,
        regionName: '공주시',
        title: '공주 필름롤',
        status: FilmRollStatus.inProgress,
        createdAt: DateTime(2026, 8, 30),
        updatedAt: DateTime(2026, 8, 30),
        regionId: const Value(11),
      ),
    );

    final row = await db.select(db.filmRolls).getSingle();
    expect(row.regionId, 11);
    expect(row.serverFilmRollId, isNull);
    expect(row.serverStatus, isNull);
    expect(row.filterId, isNull);
    expect(row.filterStrength, isNull);
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/core/database/migration_v4_test.dart`
Expected: 컴파일 실패 — `FilmRollsCompanion.insert`에 `regionId` 파라미터 없음 / `schemaVersion` 4 아님.

- [ ] **Step 3: 테이블 컬럼 추가**

`film_rolls_table.dart`의 `FilmRolls` 클래스에 `completedAt` 아래 추가:

```dart
  IntColumn get regionId => integer().nullable()();
  TextColumn get filterId => text().nullable()();
  RealColumn get filterStrength => real().nullable()();
  IntColumn get serverFilmRollId => integer().nullable()();
  TextColumn get serverStatus => text().nullable()();
```

`film_roll_places_table.dart`의 `FilmRollPlaces` 클래스에 `visitedAt` 아래 추가:

```dart
  DateTimeColumn get visitSyncedAt => dateTime().nullable()();
```

- [ ] **Step 4: schemaVersion / onUpgrade 수정**

`local_database.dart`:

```dart
  @override
  int get schemaVersion => 4;
```

`onUpgrade` 안, `if (from < 3) { ... }` 블록 다음에 추가:

```dart
        // v4: 필름롤 서버 동기화(생성/방문)를 위한 컬럼 추가.
        // 전부 nullable이며 기존 행은 null로 남는다 — serverFilmRollId가 null이면
        // "아직 서버에 생성되지 않음"으로 취급된다.
        if (from < 4) {
          await m.addColumn(filmRolls, filmRolls.regionId);
          await m.addColumn(filmRolls, filmRolls.filterId);
          await m.addColumn(filmRolls, filmRolls.filterStrength);
          await m.addColumn(filmRolls, filmRolls.serverFilmRollId);
          await m.addColumn(filmRolls, filmRolls.serverStatus);
          await m.addColumn(filmRollPlaces, filmRollPlaces.visitSyncedAt);
        }
```

- [ ] **Step 5: 코드젠 재생성**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/core/database/local_database.g.dart` 갱신, 에러 없음.

- [ ] **Step 6: 테스트 통과 확인**

Run: `flutter test test/core/database/migration_v4_test.dart`
Expected: PASS

- [ ] **Step 7: analyze**

Run: `flutter analyze lib/core/database`
Expected: No issues found

- [ ] **Step 8: Commit**

```bash
git add lib/core/database test/core/database/migration_v4_test.dart
git commit -m "feat: 필름롤 서버 동기화용 스키마 v4 컬럼 추가

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 2: AppPreferences.defaultFilterId

**Files:**
- Modify: `lib/core/config/app_preferences.dart`
- Test: `test/core/config/app_preferences_default_filter_test.dart` (Create)

**Interfaces:**
- Produces: `AppPreferences.getDefaultFilterId() -> Future<String?>`, `AppPreferences.setDefaultFilterId(String?) -> Future<void>`.

- [ ] **Step 1: 실패 테스트 작성**

`test/core/config/app_preferences_default_filter_test.dart`:

```dart
import 'package:chaerok/core/config/app_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('defaultFilterId 저장/조회/삭제', () async {
    final prefs = AppPreferences.instance;
    expect(await prefs.getDefaultFilterId(), isNull);

    await prefs.setDefaultFilterId('vintage-01');
    expect(await prefs.getDefaultFilterId(), 'vintage-01');

    await prefs.setDefaultFilterId(null);
    expect(await prefs.getDefaultFilterId(), isNull);
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/core/config/app_preferences_default_filter_test.dart`
Expected: 컴파일 실패 — `getDefaultFilterId` 미정의.

- [ ] **Step 3: 구현**

`app_preferences.dart` 상단 키 상수 추가:

```dart
const _keyDefaultFilterId = 'default_filter_id';
```

클래스 안에 메서드 추가 (`setMockRegionCodeName` 아래):

```dart
  /// 필름롤 서버 생성에 사용할 기본 필터 ID. 최초 1회 `FiltersApi.getFilters()`
  /// 결과의 첫 필터를 캐시해두고 이후 재사용한다 (필터 선택 UI 도입 전까지).
  Future<String?> getDefaultFilterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultFilterId);
  }

  Future<void> setDefaultFilterId(String? filterId) async {
    final prefs = await SharedPreferences.getInstance();
    if (filterId == null) {
      await prefs.remove(_keyDefaultFilterId);
    } else {
      await prefs.setString(_keyDefaultFilterId, filterId);
    }
  }
```

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/core/config/app_preferences_default_filter_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/core/config/app_preferences.dart test/core/config/app_preferences_default_filter_test.dart
git commit -m "feat: AppPreferences에 defaultFilterId 캐시 추가

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 3: 엔티티/매퍼에 서버 동기화 필드 반영

**Files:**
- Modify: `lib/features/film_roll/domain/entity/film_roll.dart`
- Modify: `lib/features/film_roll/data/model/film_roll_mapper.dart`
- Modify: `lib/features/film_roll/domain/entity/film_roll_place.dart`
- Modify: `lib/features/film_roll/data/model/film_roll_place_mapper.dart`
- Test: `test/features/film_roll/data/model/film_roll_mapper_test.dart` (Create or extend)

**Interfaces:**
- Consumes: `FilmRollRow` 신규 컬럼 (Task 1), `FilmRollPlaceRow.visitSyncedAt` (Task 1).
- Produces: `FilmRoll` gains `final int? regionId`, `final int? serverFilmRollId`, `final String? serverStatus`; `copyWith` accepts them. `FilmRollPlace` gains `final DateTime? visitSyncedAt`. `FilmRollMapper.toEntity` and `FilmRollPlaceMapper.toEntity` populate them.

- [ ] **Step 1: 실패 테스트 작성**

`test/features/film_roll/data/model/film_roll_mapper_test.dart`:

```dart
import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/data/model/film_roll_mapper.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toEntity가 서버 동기화 필드를 매핑한다', () {
    final row = FilmRollRow(
      id: 'r1',
      userId: 7,
      regionCode: RegionCode.buyeo,
      regionName: '부여군',
      title: '부여 필름롤',
      status: FilmRollStatus.inProgress,
      createdAt: DateTime(2026, 8, 30),
      updatedAt: DateTime(2026, 8, 30),
      regionId: 22,
      serverFilmRollId: 555,
      serverStatus: 'CAPTURING',
    );

    final entity = row.toEntity(totalPlaceCount: 0, visitedPlaceCount: 0);

    expect(entity.regionId, 22);
    expect(entity.serverFilmRollId, 555);
    expect(entity.serverStatus, 'CAPTURING');
  });
}
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/features/film_roll/data/model/film_roll_mapper_test.dart`
Expected: 컴파일 실패 — `FilmRoll`에 `regionId` 없음.

- [ ] **Step 3: FilmRoll 엔티티 수정**

`film_roll.dart`:
- 생성자에 `this.regionId`, `this.serverFilmRollId`, `this.serverStatus` (named, nullable) 추가.
- 필드 선언 추가: `final int? regionId; final int? serverFilmRollId; final String? serverStatus;`
- `copyWith` 시그니처에 `int? regionId, int? serverFilmRollId, String? serverStatus` 추가하고 본문에서 `regionId: regionId ?? this.regionId` 등으로 반영.

- [ ] **Step 4: FilmRollMapper 수정**

`film_roll_mapper.dart`의 `toEntity` 반환부에 추가:

```dart
      regionId: regionId,
      serverFilmRollId: serverFilmRollId,
      serverStatus: serverStatus,
```

- [ ] **Step 5: FilmRollPlace 엔티티 + 매퍼 수정**

`film_roll_place.dart`: 생성자에 `this.visitSyncedAt` (nullable) 추가, `final DateTime? visitSyncedAt;` 선언. `copyWith`가 있으면 반영.

`film_roll_place_mapper.dart`의 `toEntity` 반환부에 `visitSyncedAt: visitSyncedAt,` 추가.

- [ ] **Step 6: 통과 확인 + 회귀 확인**

Run: `flutter test test/features/film_roll/`
Expected: PASS (신규 + 기존 전부)

- [ ] **Step 7: analyze**

Run: `flutter analyze lib/features/film_roll`
Expected: No issues found

- [ ] **Step 8: Commit**

```bash
git add lib/features/film_roll/domain/entity lib/features/film_roll/data/model test/features/film_roll/data/model
git commit -m "feat: FilmRoll/FilmRollPlace 엔티티에 서버 동기화 필드 추가

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 4: findOrCreateActiveByRegion에 regionId 전달 + 저장

**Files:**
- Modify: `lib/features/film_roll/domain/repository/film_roll_repository.dart`
- Modify: `lib/features/film_roll/data/repository/film_roll_repository_impl.dart:39-101`
- Modify: `lib/features/film_roll/data/local/film_roll_local_data_source.dart`
- Modify: `lib/features/film_roll/domain/usecase/enter_region_use_case.dart`
- Modify: `lib/features/film_roll/film_roll_module.dart` (enterRegion 노출 시그니처 없음 — use case 그대로, 단 호출부 위해 확인)
- Modify: `lib/features/home/presentation/home_dashboard_screen.dart:245`
- Modify: `lib/features/explore/presentation/explore_screen.dart:111`
- Test: `test/features/film_roll/data/repository/film_roll_repository_region_id_test.dart` (Create)

**Interfaces:**
- Consumes: `FilmRoll.regionId` (Task 3).
- Produces: `FilmRollRepository.findOrCreateActiveByRegion({required RegionCode regionCode, required String regionName, required int regionId})`. `EnterRegionUseCase.call(String cityCountyName, {required int regionId})`.

- [ ] **Step 1: 실패 테스트 작성**

`test/features/film_roll/data/repository/film_roll_repository_region_id_test.dart`:

```dart
// 기존 리포지토리 테스트의 셋업 헬퍼를 참고해 in-memory AppDatabase + 데이터소스를 구성.
// (기존 test/features/film_roll/ 하위 리포지토리 테스트 파일의 setUp 패턴을 복사)

test('신규 생성 시 regionId를 저장한다', () async {
  final filmRoll = await repository.findOrCreateActiveByRegion(
    regionCode: RegionCode.seosan,
    regionName: '서산시',
    regionId: 33,
  );
  expect(filmRoll.regionId, 33);
});

test('기존 행에 regionId가 없으면(레거시) 재사용 시 백필한다', async {
  // status=inProgress 행을 regionId=null로 직접 insert 후
  final reused = await repository.findOrCreateActiveByRegion(
    regionCode: RegionCode.seosan, regionName: '서산시', regionId: 33,
  );
  expect(reused.regionId, 33);
});
```

> 실제 setUp은 기존 `test/features/film_roll/` 리포지토리 테스트 파일(예: `film_roll_repository_impl_test.dart`)의 헬퍼를 그대로 재사용할 것. 새 헬퍼를 만들지 말 것.

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/features/film_roll/data/repository/film_roll_repository_region_id_test.dart`
Expected: 컴파일 실패 — `findOrCreateActiveByRegion`에 `regionId` 없음.

- [ ] **Step 3: 인터페이스 수정**

`film_roll_repository.dart`:

```dart
  Future<FilmRoll> findOrCreateActiveByRegion({
    required RegionCode regionCode,
    required String regionName,
    required int regionId,
  });
```

- [ ] **Step 4: 구현 수정**

`film_roll_repository_impl.dart` `findOrCreateActiveByRegion`:
- 시그니처에 `required int regionId` 추가.
- `FilmRollsCompanion.insert(...)`에 `regionId: Value(regionId)` 추가.
- `existing != null` 분기에서, `existing.regionId == null`이면 백필:

```dart
      if (existing != null) {
        if (existing.regionId == null) {
          await _filmRollDs.update(
            existing.id,
            FilmRollsCompanion(
              regionId: Value(regionId),
              updatedAt: Value(DateTime.now()),
            ),
          );
          final refreshed = await _filmRollDs.findById(existing.id);
          return _toEntity(refreshed!);
        }
        return _toEntity(existing);
      }
```

`film_roll_local_data_source.dart`에 `update`가 이미 있으면 그대로 사용. 없으면
기존 `update`/`insert` 패턴을 따라 최소 추가.

- [ ] **Step 5: EnterRegionUseCase 수정**

`enter_region_use_case.dart` `call`:

```dart
  Future<FilmRoll> call(String cityCountyName, {required int regionId}) async {
    final regionCode = RegionNormalizer.fromCityCountyName(cityCountyName);
    if (regionCode == null) {
      throw UnsupportedRegionException(cityCountyName);
    }
    final filmRoll = await _filmRollRepository.findOrCreateActiveByRegion(
      regionCode: regionCode,
      regionName: cityCountyName,
      regionId: regionId,
    );
    final preferences = _appPreferences ?? AppPreferences.instance;
    await preferences.setLastActiveFilmRollId(filmRoll.id);
    return filmRoll;
  }
```

- [ ] **Step 6: 호출부 수정**

`home_dashboard_screen.dart:245`:

```dart
      final filmRoll = await FilmRollModule.instance.enterRegion(
        locationResult.region.cityCountyName,
        regionId: locationResult.region.regionId,
      );
```

`explore_screen.dart:111`:

```dart
      final filmRoll = await FilmRollModule.instance.enterRegion(
        _selectedRegion.cityCountyName,
        regionId: _regionId,
      );
```

`film_roll_module.dart`: `enterRegion`은 `EnterRegionUseCase` 인스턴스이므로
`call`의 새 시그니처가 자동 반영됨 (별도 수정 없음, 확인만).

- [ ] **Step 7: 테스트 + analyze**

Run: `flutter test test/features/film_roll/` 및 `flutter analyze lib`
Expected: PASS / No issues

- [ ] **Step 8: Commit**

```bash
git add lib/features/film_roll lib/features/home lib/features/explore test/features/film_roll/data/repository
git commit -m "feat: 필름롤 생성 시 서버 regionId를 로컬에 저장

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 5: 리포지토리 동기화 지원 메서드

**Files:**
- Modify: `lib/features/film_roll/domain/repository/film_roll_repository.dart`
- Modify: `lib/features/film_roll/data/repository/film_roll_repository_impl.dart`
- Modify: `lib/features/film_roll/data/local/film_roll_local_data_source.dart`
- Modify: `lib/features/film_roll/domain/repository/film_roll_place_repository.dart`
- Modify: `lib/features/film_roll/data/repository/film_roll_place_repository_impl.dart`
- Modify: `lib/features/film_roll/data/local/film_roll_place_local_data_source.dart`
- Test: `test/features/film_roll/data/repository/film_roll_sync_support_test.dart` (Create)

**Interfaces:**
- Produces:
  - `FilmRollRepository.linkServerFilmRoll({required String clientFilmRollId, required int serverFilmRollId, String? serverStatus, String? filterId, double? filterStrength}) -> Future<void>`
  - `FilmRollRepository.updateServerStatus({required String clientFilmRollId, required String serverStatus}) -> Future<void>`
  - `FilmRollPlaceRepository.findUnsyncedVisitedPlaces(String filmRollId) -> Future<List<FilmRollPlace>>` (isVisited && visitSyncedAt == null)
  - `FilmRollPlaceRepository.markVisitSynced(String filmRollPlaceId, {required DateTime at}) -> Future<void>`

- [ ] **Step 1: 실패 테스트 작성**

`test/features/film_roll/data/repository/film_roll_sync_support_test.dart` (기존 리포지토리 테스트 setUp 헬퍼 재사용):

```dart
test('linkServerFilmRoll이 serverFilmRollId/status/filter를 저장한다', () async {
  final fr = await repository.findOrCreateActiveByRegion(
    regionCode: RegionCode.gongju, regionName: '공주시', regionId: 11);
  await repository.linkServerFilmRoll(
    clientFilmRollId: fr.id, serverFilmRollId: 900,
    serverStatus: 'CAPTURING', filterId: 'f1', filterStrength: 1.0);
  final updated = await repository.findById(fr.id);
  expect(updated!.serverFilmRollId, 900);
  expect(updated.serverStatus, 'CAPTURING');
});

test('findUnsyncedVisitedPlaces는 방문했고 미동기화인 장소만 반환', () async {
  // 코스 선택으로 장소 2개 생성 → 1개 markVisited → 1개 markVisited + markVisitSynced
  final pending = await placeRepository.findUnsyncedVisitedPlaces(filmRollId);
  expect(pending.map((p) => p.id), [visitedNotSyncedId]);
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/features/film_roll/data/repository/film_roll_sync_support_test.dart`
Expected: 컴파일 실패.

- [ ] **Step 3: FilmRollRepository 구현**

인터페이스에 두 메서드 선언 추가. `film_roll_repository_impl.dart`:

```dart
  @override
  Future<void> linkServerFilmRoll({
    required String clientFilmRollId,
    required int serverFilmRollId,
    String? serverStatus,
    String? filterId,
    double? filterStrength,
  }) async {
    await _filmRollDs.update(
      clientFilmRollId,
      FilmRollsCompanion(
        serverFilmRollId: Value(serverFilmRollId),
        serverStatus: serverStatus == null
            ? const Value.absent()
            : Value(serverStatus),
        filterId: filterId == null ? const Value.absent() : Value(filterId),
        filterStrength: filterStrength == null
            ? const Value.absent()
            : Value(filterStrength),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> updateServerStatus({
    required String clientFilmRollId,
    required String serverStatus,
  }) async {
    await _filmRollDs.update(
      clientFilmRollId,
      FilmRollsCompanion(
        serverStatus: Value(serverStatus),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }
```

`film_roll_local_data_source.dart`에 `update(String id, FilmRollsCompanion companion)`가 없으면 기존 패턴대로 추가 (계정 스코핑 유지 — 기존 `update`/`deleteById`가 `user_id` 조건을 거는 방식을 따를 것).

- [ ] **Step 4: FilmRollPlaceRepository 구현**

인터페이스에 두 메서드 선언 추가. `film_roll_place_repository_impl.dart`:

```dart
  @override
  Future<List<FilmRollPlace>> findUnsyncedVisitedPlaces(String filmRollId) async {
    final rows = await _placeDs.findByFilmRoll(filmRollId);
    final result = <FilmRollPlace>[];
    for (final row in rows) {
      if (row.isVisited && row.visitSyncedAt == null) {
        final photoCount = await _photoDs.countByPlace(row.id);
        result.add(row.toEntity(photoCount: photoCount));
      }
    }
    return result;
  }

  @override
  Future<void> markVisitSynced(String filmRollPlaceId, {required DateTime at}) {
    return _placeDs.update(
      filmRollPlaceId,
      FilmRollPlacesCompanion(visitSyncedAt: Value(at)),
    );
  }
```

`film_roll_place_local_data_source.dart`의 `update`가 이미 있으면 그대로 사용
(Task 있음: `markVisited`에서 이미 `_placeDs.update` 호출 중이므로 존재함).

- [ ] **Step 5: 통과 확인**

Run: `flutter test test/features/film_roll/`
Expected: PASS

- [ ] **Step 6: analyze**

Run: `flutter analyze lib/features/film_roll`
Expected: No issues found

- [ ] **Step 7: Commit**

```bash
git add lib/features/film_roll test/features/film_roll/data/repository/film_roll_sync_support_test.dart
git commit -m "feat: 필름롤 동기화 지원 리포지토리 메서드 추가

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 6: FilmRollCreateRequest.clientFilmRollId + FilmRollSyncService 생성 경로

**Files:**
- Modify: `lib/data/models/film_roll_create_request.dart` (+`clientFilmRollId`)
- Create: `lib/features/film_roll/data/sync/film_roll_sync_result.dart`
- Create: `lib/features/film_roll/data/sync/film_roll_sync_service.dart`
- Create: `test/features/film_roll/sync/film_roll_sync_service_test.dart`

**Interfaces:**
- Consumes: `FilmRollRepository` (`findById`, `linkServerFilmRoll`, `updateServerStatus`), `FilmRollPlaceRepository` (`findUnsyncedVisitedPlaces`, `markVisitSynced`), `AppPreferences` (`getCurrentUserId`, `getDefaultFilterId`, `setDefaultFilterId`), `FilmRollsApi`, `VisitsApi`, `FiltersApi` DTOs.
- Produces:
  ```dart
  // FilmRollCreateRequest에 필드 추가:
  //   final String clientFilmRollId;  // 로컬 UUID (멱등키)
  //   toJson()에 'clientFilmRollId': clientFilmRollId 포함
  //   생성자 첫 파라미터로 required this.clientFilmRollId

  class FilmRollSyncResult {
    const FilmRollSyncResult({
      this.created = false, this.visitsPushed = 0, this.visitsSkipped = 0,
      this.serverStatus, this.error,
    });
    final bool created;
    final int visitsPushed;
    final int visitsSkipped;
    final String? serverStatus;
    final Object? error;
    bool get hasError => error != null;
  }

  class FilmRollSyncService {
    FilmRollSyncService({
      required FilmRollRepository filmRollRepository,
      required FilmRollPlaceRepository filmRollPlaceRepository,
      AppPreferences? preferences,
      Future<FilmRollResponse> Function(FilmRollCreateRequest)? createFilmRoll,
      Future<FilmRollResponse> Function(int filmRollId)? getFilmRoll,
      Future<VisitCreateResponse> Function(int filmRollId, VisitCreateRequest)? createVisit,
      Future<List<FilterResponse>> Function()? getFilters,
    });
    Future<FilmRollSyncResult> syncFilmRoll(String clientFilmRollId);
  }
  ```
  이 Task는 `syncFilmRoll`의 **생성 경로만** 구현한다 (방문/미러링은 Task 8~9).
  create API는 `clientFilmRollId` 멱등키를 받으므로 응답 유실 후 재요청은
  기존 롤을 그대로 반환한다 → `/current` 복구 불필요 (`getCurrentFilmRoll`
  주입 파라미터 없음).

- [ ] **Step 1: 실패 테스트 작성**

`test/features/film_roll/sync/film_roll_sync_service_test.dart`:

```dart
// 기존 리포지토리 테스트 setUp 헬퍼로 in-memory AppDatabase + 실제 리포지토리 구성.
// API는 함수 파라미터로 가짜 주입.

FilmRollResponse fakeResponse({int id = 900, String status = 'CAPTURING'}) =>
    FilmRollResponse(
      filmRollId: id, regionId: 11, filterId: 'f1', filterStrength: 1.0,
      filterVersion: 1, status: status, totalPhotoCount: 0, processedPhotoCount: 0,
      maxPhotoCount: 24, exitConfirmed: false, developAvailable: false,
      createdAt: DateTime(2026), updatedAt: DateTime(2026),
    );

test('serverFilmRollId가 없으면 서버에 생성하고 저장한다 (요청에 clientFilmRollId 포함)', () async {
  await prefs.setCurrentUserId(7);
  await prefs.setDefaultFilterId('f1');
  final fr = await repository.findOrCreateActiveByRegion(
    regionCode: RegionCode.gongju, regionName: '공주시', regionId: 11);
  // 로컬 행 userId를 7로 맞춘다 (헬퍼 or 직접 update).

  var createCalls = 0;
  FilmRollCreateRequest? sent;
  final service = FilmRollSyncService(
    filmRollRepository: repository,
    filmRollPlaceRepository: placeRepository,
    preferences: prefs,
    createFilmRoll: (req) async { createCalls++; sent = req; return fakeResponse(); },
  );

  final result = await service.syncFilmRoll(fr.id);

  expect(createCalls, 1);
  expect(sent!.clientFilmRollId, fr.id);          // 로컬 UUID를 멱등키로 전송
  expect(sent!.toJson()['clientFilmRollId'], fr.id);
  expect(result.created, isTrue);
  expect((await repository.findById(fr.id))!.serverFilmRollId, 900);
});

test('serverFilmRollId가 이미 있으면 생성하지 않는다', () async {
  // linkServerFilmRoll로 미리 연결 후 syncFilmRoll → createCalls == 0
});

test('계정 불일치 행이면 아무 API도 호출하지 않는다', () async {
  await prefs.setCurrentUserId(999);
  var createCalls = 0;
  final service = FilmRollSyncService(/* createFilmRoll: (_) { createCalls++; ... } */);
  final result = await service.syncFilmRoll(fr.id);
  expect(createCalls, 0);
});

test('필터 캐시 없음 + getFilters 실패 시 생성 보류', () async {
  await prefs.setDefaultFilterId(null);
  final service = FilmRollSyncService(
    /* getFilters: () async => throw Exception('net'), createFilmRoll: ... */);
  final result = await service.syncFilmRoll(fr.id);
  expect(result.created, isFalse);
  expect((await repository.findById(fr.id))!.serverFilmRollId, isNull);
});

test('생성 중 네트워크 오류는 예외를 던지지 않고 result.error에 담긴다', () async {
  final service = FilmRollSyncService(
    /* createFilmRoll: (_) async => throw DioException(...), */);
  final result = await service.syncFilmRoll(fr.id);
  expect(result.hasError, isTrue);
  expect((await repository.findById(fr.id))!.serverFilmRollId, isNull);
});

test('멱등 재요청: 서버가 기존 롤을 반환하면 그 id를 저장한다', () async {
  // createFilmRoll: (_) async => fakeResponse(id: 555, status: 'CAPTURING')
  // (서버가 신규 생성이 아니라 기존 롤을 반환한 상황 — 응답 형태는 동일)
  final result = await service.syncFilmRoll(fr.id);
  expect((await repository.findById(fr.id))!.serverFilmRollId, 555);
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/features/film_roll/sync/film_roll_sync_service_test.dart`
Expected: 컴파일 실패 — `FilmRollCreateRequest.clientFilmRollId` / 클래스 미정의.

- [ ] **Step 3a: FilmRollCreateRequest에 clientFilmRollId 추가**

`lib/data/models/film_roll_create_request.dart`:

```dart
class FilmRollCreateRequest {
  const FilmRollCreateRequest({
    required this.clientFilmRollId,
    required this.regionId,
    required this.filterId,
    required this.filterStrength,
  });

  final String clientFilmRollId;
  final int regionId;
  final String filterId;
  final double filterStrength;

  Map<String, dynamic> toJson() => {
    'clientFilmRollId': clientFilmRollId,
    'regionId': regionId,
    'filterId': filterId,
    'filterStrength': filterStrength,
  };
}
```

- [ ] **Step 3b: FilmRollSyncResult 작성**

`film_roll_sync_result.dart`에 위 Interfaces의 값 객체를 그대로 작성.

- [ ] **Step 4: FilmRollSyncService 생성 경로 구현**

`film_roll_sync_service.dart`:

```dart
import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/data/models/film_roll_create_request.dart';
import 'package:chaerok/data/models/film_roll_response.dart';
import 'package:chaerok/data/models/filter_response.dart';
import 'package:chaerok/data/models/visit_create_request.dart';
import 'package:chaerok/data/models/visit_create_response.dart';
import 'package:chaerok/data/remote/film_rolls_api.dart';
import 'package:chaerok/data/remote/filters_api.dart';
import 'package:chaerok/data/remote/visits_api.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_result.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_place_repository.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';

const _defaultFilterStrength = 1.0;

class FilmRollSyncService {
  FilmRollSyncService({
    required FilmRollRepository filmRollRepository,
    required FilmRollPlaceRepository filmRollPlaceRepository,
    AppPreferences? preferences,
    Future<FilmRollResponse> Function(FilmRollCreateRequest)? createFilmRoll,
    Future<FilmRollResponse> Function(int)? getFilmRoll,
    Future<VisitCreateResponse> Function(int, VisitCreateRequest)? createVisit,
    Future<List<FilterResponse>> Function()? getFilters,
  })  : _filmRollRepository = filmRollRepository,
        _placeRepository = filmRollPlaceRepository,
        _preferences = preferences ?? AppPreferences.instance,
        _createFilmRoll = createFilmRoll ?? FilmRollsApi.createFilmRoll,
        _getFilmRoll = getFilmRoll ?? FilmRollsApi.getFilmRoll,
        _createVisit = createVisit ?? VisitsApi.createVisit,
        _getFilters = getFilters ?? FiltersApi.getFilters;

  final FilmRollRepository _filmRollRepository;
  final FilmRollPlaceRepository _placeRepository;
  final AppPreferences _preferences;
  final Future<FilmRollResponse> Function(FilmRollCreateRequest) _createFilmRoll;
  final Future<FilmRollResponse> Function(int) _getFilmRoll;
  final Future<VisitCreateResponse> Function(int, VisitCreateRequest) _createVisit;
  final Future<List<FilterResponse>> Function() _getFilters;

  Future<FilmRollSyncResult> syncFilmRoll(String clientFilmRollId) async {
    final filmRoll = await _filmRollRepository.findById(clientFilmRollId);
    if (filmRoll == null) return const FilmRollSyncResult();

    final currentUserId = await _preferences.getCurrentUserId();
    // 로컬 엔티티에 userId가 없으므로 계정 스코핑은 findById가 이미 현재 계정으로
    // 필터링한다는 전제(FilmRollLocalDataSource.findById가 user_id 조건 사용).
    // currentUserId가 null이면 로그인 미완료 — 동기화 보류.
    if (currentUserId == null) return const FilmRollSyncResult();

    var serverId = filmRoll.serverFilmRollId;
    var created = false;
    Object? error;

    if (serverId == null) {
      try {
        serverId = await _ensureServerFilmRoll(filmRoll);
        created = serverId != null;
      } catch (e) {
        return FilmRollSyncResult(error: e);
      }
      if (serverId == null) {
        // 필터 미결정 등으로 생성 보류.
        return const FilmRollSyncResult();
      }
    }

    // 생성 4xx(다른 CAPTURING 롤) 세분화는 Task 7, 방문 전송은 Task 8,
    // 상태 미러링은 Task 9에서 채운다.
    return FilmRollSyncResult(created: created, error: error);
  }

  /// 서버 필름롤을 생성(또는 멱등 반환)하고 로컬에 연결한다.
  /// 필터를 결정할 수 없으면 null을 반환한다(생성 보류).
  /// create API는 `clientFilmRollId`(로컬 UUID)를 멱등키로 받으므로, 응답 유실
  /// 후 재요청도 같은 롤을 그대로 돌려준다 → 별도 복구 로직 불필요.
  Future<int?> _ensureServerFilmRoll(filmRoll) async {
    final regionId = filmRoll.regionId;
    if (regionId == null) return null; // regionId 없이는 생성 불가.

    final filterId = await _resolveFilterId();
    if (filterId == null) return null;

    final res = await _createFilmRoll(FilmRollCreateRequest(
      clientFilmRollId: filmRoll.id,
      regionId: regionId,
      filterId: filterId,
      filterStrength: _defaultFilterStrength,
    ));
    await _filmRollRepository.linkServerFilmRoll(
      clientFilmRollId: filmRoll.id,
      serverFilmRollId: res.filmRollId,
      serverStatus: res.status,
      filterId: filterId,
      filterStrength: _defaultFilterStrength,
    );
    return res.filmRollId;
  }

  Future<String?> _resolveFilterId() async {
    final cached = await _preferences.getDefaultFilterId();
    if (cached != null && cached.isNotEmpty) return cached;
    final filters = await _getFilters(); // 실패 시 예외 → 상위에서 result.error
    if (filters.isEmpty) return null;
    final first = filters.first.filterId;
    await _preferences.setDefaultFilterId(first);
    return first;
  }
}
```

> 구현 노트: `filterId`/`filterStrength`는 생성 성공 후 `linkServerFilmRoll`에서
> `serverFilmRollId`와 함께 저장한다(사전 저장 단계 없음). `_resolveFilterId`
> 실패(예외)는 `syncFilmRoll`의 try/catch가 `result.error`로 잡고,
> `filters.isEmpty` 또는 `regionId == null`은 null 반환 → 생성 보류.
> `_createFilmRoll`이 4xx를 던지는 경우(다른 CAPTURING 롤 존재)는 Task 7에서
> "미연동 후 재시도"로 처리한다. 이 Task의 try/catch는 그 4xx도 일단
> `result.error`로 잡는다(Task 7에서 세분화).

- [ ] **Step 5: 통과 확인**

Run: `flutter test test/features/film_roll/sync/film_roll_sync_service_test.dart`
Expected: PASS

- [ ] **Step 6: analyze**

Run: `flutter analyze lib/features/film_roll/data/sync`
Expected: No issues found

- [ ] **Step 7: Commit**

```bash
git add lib/features/film_roll/data/sync test/features/film_roll/sync
git commit -m "feat: FilmRollSyncService 서버 생성 경로 구현

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 7: 생성 제한(다른 CAPTURING 롤) 처리

**Files:**
- Modify: `lib/features/film_roll/data/sync/film_roll_sync_service.dart`
- Modify: `test/features/film_roll/sync/film_roll_sync_service_test.dart`

**배경:** create API는 `clientFilmRollId` 멱등키를 받으므로, 우리 롤의 재요청은
항상 기존 롤을 반환한다(Task 6에서 이미 처리됨). `_createFilmRoll`이 4xx를
던지는 경우는 "우리 것이 아닌 다른 진행 CAPTURING 롤이 서버에 있음" 뿐이다.
이때는 **연동하지 않고(`serverFilmRollId` null 유지) 조용히 보류**한다 —
`result.error`로 취급하지 않는다(정상적인 "아직 못 함" 상태). `/current` 는
호출하지 않는다.

**Interfaces:**
- Produces: `syncFilmRoll`이 `_ensureServerFilmRoll` 호출을 `try`로 감싸,
  4xx(`DioException` + `ApiError` statusCode 400~499)면 `serverId = null` 유지
  하고 `error` 를 설정하지 않은 채 정상 반환(`FilmRollSyncResult()` 빈 결과).
  4xx가 아닌 오류는 기존대로 `result.error`.

- [ ] **Step 1: 실패 테스트 추가**

```dart
test('다른 CAPTURING 롤 존재로 생성이 4xx 거절되면 미연동·무오류로 보류한다', () async {
  final service = FilmRollSyncService(
    // createFilmRoll: (_) async => throw DioException(
    //   requestOptions: RequestOptions(path: '/api/film-rolls'),
    //   error: const ApiError(statusCode: 409, message: '이탈하지 않은 필름롤이 있습니다'),
    // ),
  );
  final result = await service.syncFilmRoll(fr.id);
  expect((await repository.findById(fr.id))!.serverFilmRollId, isNull);
  expect(result.hasError, isFalse);   // 정상 보류 — 다음 재시도에서 따라잡음
  expect(result.created, isFalse);
});

test('4xx가 아닌 5xx는 result.error로 남긴다', () async {
  // createFilmRoll: (_) async => throw DioException(error: ApiError(statusCode: 500, ...))
  final result = await service.syncFilmRoll(fr.id);
  expect(result.hasError, isTrue);
  expect((await repository.findById(fr.id))!.serverFilmRollId, isNull);
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/features/film_roll/sync/film_roll_sync_service_test.dart`
Expected: 새 테스트 FAIL (현재는 4xx도 `result.error`로 잡힘).

- [ ] **Step 3: 4xx 분기 구현**

`syncFilmRoll`의 생성 블록을 교체:

```dart
    if (serverId == null) {
      try {
        serverId = await _ensureServerFilmRoll(filmRoll);
      } on DioException catch (e) {
        if (_isClientError(e)) {
          // 다른 진행 CAPTURING 롤이 서버에 있음 — 이번엔 보류, 다음 재시도.
          return const FilmRollSyncResult();
        }
        return FilmRollSyncResult(error: e);
      } catch (e) {
        return FilmRollSyncResult(error: e);
      }
      if (serverId == null) return const FilmRollSyncResult(); // 필터 미결정 등
      created = true;
    }
```

헬퍼 추가:

```dart
import 'package:chaerok/data/models/api_error.dart';
import 'package:dio/dio.dart';

bool _isClientError(Object e) {
  if (e is DioException && e.error is ApiError) {
    final code = (e.error as ApiError).statusCode;
    return code >= 400 && code < 500;
  }
  return false;
}
```

> 오픈 질문 2(정확한 errorCode) 확정 전까지 "생성이 4xx면 제한으로 간주"로 넓게
> 잡는다. 확정되면 `errorCode`/특정 status로 좁힐 것.

- [ ] **Step 4: 통과 확인**

Run: `flutter test test/features/film_roll/sync/film_roll_sync_service_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/film_roll/data/sync test/features/film_roll/sync
git commit -m "feat: 다른 진행 필름롤 존재 시 생성 보류 처리

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 8: 방문 전송

**Files:**
- Modify: `lib/features/film_roll/data/sync/film_roll_sync_service.dart`
- Modify: `test/features/film_roll/sync/film_roll_sync_service_test.dart`

**Interfaces:**
- Consumes: `_placeRepository.findUnsyncedVisitedPlaces` / `markVisitSynced` (Task 5), `_createVisit` (Task 6).
- Produces: `syncFilmRoll`이 `serverId != null`일 때, `findUnsyncedVisitedPlaces` 각 장소에 대해 `serverPlaceId != null`이면 `_createVisit(serverId, VisitCreateRequest(placeId: serverPlaceId))` 호출 후 `markVisitSynced`; `serverPlaceId == null`이면 `visitsSkipped++`. 결과에 `visitsPushed`/`visitsSkipped` 반영. "이미 방문" 4xx 응답도 성공으로 처리.

- [ ] **Step 1: 실패 테스트 추가**

```dart
test('방문했고 serverPlaceId 있는 장소만 전송하고 visitSyncedAt을 채운다', () async {
  // 서버 연결된 필름롤 + 장소 3개: A(visited, serverPlaceId=1), B(visited, serverPlaceId=null),
  // C(not visited). createVisit 호출을 기록.
  final result = await service.syncFilmRoll(fr.id);
  expect(visitCalls, [1]);              // A만
  expect(result.visitsPushed, 1);
  expect(result.visitsSkipped, 1);      // B
  final places = await placeRepository.findByFilmRoll(fr.id);
  expect(places.firstWhere((p) => p.serverPlaceId == 1).visitSyncedAt, isNotNull);
});

test('이미 방문함(4xx) 응답도 synced로 처리한다', () async {
  // createVisit: (_, __) async => throw DioException(error: ApiError(409, '이미 인증된 장소'))
  final result = await service.syncFilmRoll(fr.id);
  expect(result.visitsPushed, 1);
  // visitSyncedAt 채워짐
});

test('방문 전송 중 5xx는 해당 장소만 미동기화로 남기고 계속 진행', () async {
  // 장소 2개(serverPlaceId 1, 2). createVisit(1) → 500, createVisit(2) → OK
  final result = await service.syncFilmRoll(fr.id);
  expect(result.visitsPushed, 1);
  expect(result.hasError, isTrue);
  // 장소1 visitSyncedAt == null, 장소2 != null
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/features/film_roll/sync/film_roll_sync_service_test.dart`
Expected: 새 테스트 FAIL.

- [ ] **Step 3: 방문 전송 구현**

`syncFilmRoll`의 "방문 전송 / 상태 미러링" 자리 교체:

```dart
    var visitsPushed = 0;
    var visitsSkipped = 0;
    final pending = await _placeRepository.findUnsyncedVisitedPlaces(clientFilmRollId);
    for (final place in pending) {
      final serverPlaceId = place.serverPlaceId;
      if (serverPlaceId == null) {
        visitsSkipped++;
        continue;
      }
      try {
        await _createVisit(serverId, VisitCreateRequest(placeId: serverPlaceId));
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

    return FilmRollSyncResult(
      created: created,
      visitsPushed: visitsPushed,
      visitsSkipped: visitsSkipped,
      error: error,
    );
```

헬퍼:

```dart
bool _isAlreadyVisited(Object e) {
  // 오픈 질문 3 확정 전까지: 4xx면서 메시지에 방문/인증 중복 뉘앙스가 있으면 true.
  if (e is DioException && e.error is ApiError) {
    final err = e.error as ApiError;
    if (err.statusCode == 409) return true;
    if (err.statusCode >= 400 &&
        err.statusCode < 500 &&
        (err.message.contains('이미') || (err.errorCode ?? '').contains('DUPLICATE'))) {
      return true;
    }
  }
  return false;
}
```

- [ ] **Step 4: 사진 업로드 TODO 표식 추가 (구현 없음)**

`syncFilmRoll` 안, 방문 전송 `for` 루프 종료 직후·`return FilmRollSyncResult(...)`
직전에 아래 주석만 남긴다. 코드/테스트 변경 없음.

```dart
    // TODO(필름롤-사진업로드): 백엔드가 "사진 1장씩 업로드" API를 추가하면
    //   여기서 이 필름롤의 Photos 중 isSynced == false 인 항목을 순회하며
    //   serverId로 전송하고 성공 시 isSynced = true 로 표시한다.
    //   명세/범위: docs/superpowers/specs/2026-08-30-filmroll-backend-sync-design.md §7.6
```

- [ ] **Step 5: 통과 확인**

Run: `flutter test test/features/film_roll/sync/film_roll_sync_service_test.dart`
Expected: PASS (주석만 추가했으므로 변화 없음)

- [ ] **Step 6: Commit**

```bash
git add lib/features/film_roll/data/sync test/features/film_roll/sync
git commit -m "feat: 로컬 방문 기록을 서버로 전송

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 9: 서버 status 미러링

**Files:**
- Modify: `lib/features/film_roll/data/sync/film_roll_sync_service.dart`
- Modify: `test/features/film_roll/sync/film_roll_sync_service_test.dart`

**Interfaces:**
- Consumes: `_getFilmRoll` (Task 6), `_filmRollRepository.updateServerStatus` (Task 5).
- Produces: `syncFilmRoll`이 마지막에 `serverId != null`이면 `_getFilmRoll(serverId)` 호출, `updateServerStatus`로 저장, `result.serverStatus` 채움. 조회 실패는 무시(로그만).

- [ ] **Step 1: 실패 테스트 추가**

```dart
test('동기화 끝에 서버 status를 조회해 로컬에 저장한다', () async {
  // getFilmRoll: (id) async => fakeResponse(id: id, status: 'READY')
  final result = await service.syncFilmRoll(fr.id);
  expect(result.serverStatus, 'READY');
  expect((await repository.findById(fr.id))!.serverStatus, 'READY');
});

test('status 조회 실패는 전체 결과를 실패로 만들지 않는다', () async {
  // getFilmRoll: (_) async => throw DioException(...)
  final result = await service.syncFilmRoll(fr.id);
  expect(result.serverStatus, isNull);
  // 생성/방문이 성공했다면 그 카운트는 유지, hasError는 방문 오류가 없었다면 false
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/features/film_roll/sync/film_roll_sync_service_test.dart`
Expected: 새 테스트 FAIL.

- [ ] **Step 3: 미러링 구현**

`return FilmRollSyncResult(...)` 직전에 삽입:

```dart
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
```

그리고 `return`에 `serverStatus: serverStatus,` 추가.

- [ ] **Step 4: 통과 확인 + 전체 sync 테스트**

Run: `flutter test test/features/film_roll/`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/film_roll/data/sync test/features/film_roll/sync
git commit -m "feat: 서버 필름롤 status를 로컬에 미러링

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 10: 모듈 조립 + 트리거 연결

**Files:**
- Modify: `lib/features/film_roll/film_roll_module.dart`
- Modify: `lib/features/film_roll/domain/usecase/enter_region_use_case.dart`
- Modify: `lib/features/film_roll/presentation/controller/film_roll_controller.dart`
- Test: `test/features/film_roll/presentation/film_roll_controller_sync_test.dart` (Create)
- Test: `test/features/film_roll/domain/usecase/enter_region_use_case_test.dart` (extend if exists)

**Interfaces:**
- Consumes: `FilmRollSyncService` (Task 6~9).
- Produces:
  - `FilmRollModule.filmRollSyncService` (public getter).
  - `EnterRegionUseCase`는 생성자에 `FilmRollSyncService? syncService` (nullable, 기본 `FilmRollModule.instance.filmRollSyncService`) 를 받고, `call` 성공 후 `unawaited(_syncService.syncFilmRoll(filmRoll.id))`.
  - `FilmRollController`는 생성자에 `FilmRollSyncService? syncService` 주입, `load()` 끝과 `completeVisit()` 끝에서 `unawaited(_syncService.syncFilmRoll(filmRollId))`, 그리고 `Future<FilmRollSyncResult> retrySync()` 공개(수동 재시도, await).
  - `FilmRollState`에 `lastSyncHadError` bool 추가(기본 false), `retrySync` 결과로 갱신.

- [ ] **Step 1: 실패 테스트 작성**

`test/features/film_roll/presentation/film_roll_controller_sync_test.dart`:

```dart
class _FakeSyncService implements FilmRollSyncService {
  int calls = 0;
  FilmRollSyncResult next = const FilmRollSyncResult();
  @override
  Future<FilmRollSyncResult> syncFilmRoll(String id) async { calls++; return next; }
}

test('load()가 끝나면 syncFilmRoll을 fire-and-forget 호출한다', () async {
  final fake = _FakeSyncService();
  final controller = FilmRollController(
    filmRollId: seededId,
    onStateChanged: (_) {},
    // 기존 주입 파라미터 + syncService: fake,
  );
  await controller.load();
  await Future<void>.delayed(Duration.zero);
  expect(fake.calls, 1);
});

test('completeVisit 후에도 syncFilmRoll을 호출한다', () async { /* ... */ });

test('retrySync는 결과의 hasError를 state.lastSyncHadError에 반영', () async {
  fake.next = const FilmRollSyncResult(error: 'boom');
  await controller.retrySync();
  expect(controller.state.lastSyncHadError, isTrue);
});
```

`enter_region_use_case_test.dart` (기존 파일 있으면 확장):

```dart
test('지역 진입 성공 후 syncFilmRoll을 호출한다', () async {
  final fake = _FakeSyncService();
  final useCase = EnterRegionUseCase(
    filmRollRepository: repo, syncService: fake,
    appPreferences: prefs,
  );
  await useCase('공주시', regionId: 11);
  await Future<void>.delayed(Duration.zero);
  expect(fake.calls, 1);
});
```

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/features/film_roll/presentation/film_roll_controller_sync_test.dart test/features/film_roll/domain/usecase/enter_region_use_case_test.dart`
Expected: 컴파일 실패.

- [ ] **Step 3: 모듈 조립**

`film_roll_module.dart`:
- import 추가.
- 생성자 이니셜라이저에 `filmRollSyncService = FilmRollSyncService(filmRollRepository: <위에서 만든 repo>, filmRollPlaceRepository: <위 repo>)` 추가. (이니셜라이저 리스트에서 다른 필드를 참조할 수 없으면, `late final`로 선언하고 생성자 본문에서 `filmRollSyncService = FilmRollSyncService(...)` 로 할당 — `enterRegion` 등과 같은 위치.)
- `late final FilmRollSyncService filmRollSyncService;` 필드.
- `enterRegion = EnterRegionUseCase(filmRollRepository: filmRollRepository, syncService: filmRollSyncService);`

- [ ] **Step 4: EnterRegionUseCase 트리거**

```dart
import 'dart:async';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_service.dart';

class EnterRegionUseCase {
  const EnterRegionUseCase({
    required FilmRollRepository filmRollRepository,
    FilmRollSyncService? syncService,
    AppPreferences? appPreferences,
  })  : _filmRollRepository = filmRollRepository,
        _syncService = syncService,
        _appPreferences = appPreferences;

  final FilmRollSyncService? _syncService;
  // ...

  Future<FilmRoll> call(String cityCountyName, {required int regionId}) async {
    // ... 기존 로직 ...
    await preferences.setLastActiveFilmRollId(filmRoll.id);

    final sync = _syncService ?? FilmRollModule.instance.filmRollSyncService;
    unawaited(sync.syncFilmRoll(filmRoll.id));

    return filmRoll;
  }
}
```

> `FilmRollModule` import가 순환참조를 만들면(_module이 use case를 만들고 use
> case가 module을 참조), 생성자에서 `syncService`를 **필수**로 받도록 바꾸고
> module에서 항상 주입한다. 테스트는 이미 주입하므로 문제 없음.

- [ ] **Step 5: FilmRollController 트리거 + retrySync**

- 생성자에 `FilmRollSyncService? syncService` 추가, `_syncService = syncService ?? FilmRollModule.instance.filmRollSyncService`.
- 데이터 조회부를 `_reload()`(동기화 트리거 없음)로 분리하고, `load()`는 `await _reload()` 후 로드 성공 시에만 `_triggerSync()` 호출. `completeVisit()` 등은 `load()`를 그대로 써서 방문 후 동기화가 걸리게 한다.
- `FilmRollState`에 `final bool lastSyncHadError;` (기본 false) + `copyWith` 반영.
- 신규 메서드 — 재시도는 `load()`가 아니라 `_reload()`를 써서 **추가 백그라운드 동기화·lastSyncHadError 재변경을 피한다**:

```dart
  Future<FilmRollSyncResult> retrySync() async {
    final result = await _syncService.syncFilmRoll(filmRollId);
    await _reload();
    _emit(_state.copyWith(lastSyncHadError: result.hasError));
    return result;
  }
```

- [ ] **Step 6: 통과 확인 + 전체 회귀**

Run: `flutter test`
Expected: PASS (전체)

- [ ] **Step 7: analyze**

Run: `flutter analyze lib`
Expected: No issues found

- [ ] **Step 8: Commit**

```bash
git add lib/features/film_roll test/features/film_roll
git commit -m "feat: 지역 진입/필름롤 로드/방문 후 동기화 트리거 연결

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 11: FilmRollScreen 동기화 재시도 어피던스 (최소)

**Files:**
- Modify: `lib/features/film_roll/presentation/page/film_roll_screen.dart`

**Interfaces:**
- Consumes: `FilmRollController.retrySync()`, `FilmRollState.lastSyncHadError` (Task 10).

- [ ] **Step 1: UI 로직 추가**

`_FilmRollScreenState`에:
- `_state.lastSyncHadError == true`일 때만 보이는 인라인 배너/버튼을 `build`의
  적절한 위치(예: 장소 리스트 상단)에 추가. 디자인 토큰 사용:

```dart
if (_state.lastSyncHadError)
  Padding(
    padding: const EdgeInsets.all(ChaerokSpacing.sm),
    child: Row(
      children: [
        const Icon(Icons.cloud_off_rounded,
            size: ChaerokSpacing.md, color: ChaerokColors.textSecondary),
        const SizedBox(width: ChaerokSpacing.xs),
        Expanded(
          child: Text('서버 동기화에 실패했어요. 로컬 기록은 안전합니다.',
              style: ChaerokTypography.caption
                  .copyWith(color: ChaerokColors.textSecondary)),
        ),
        TextButton(
          onPressed: _isSyncing ? null : _onRetrySyncTap,
          child: const Text('재시도'),
        ),
      ],
    ),
  ),
```

- `_isSyncing` bool 상태 + 핸들러:

```dart
  Future<void> _onRetrySyncTap() async {
    setState(() => _isSyncing = true);
    try {
      final result = await _controller.retrySync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result.hasError ? '아직 동기화하지 못했어요.' : '동기화 완료'),
      ));
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }
```

- [ ] **Step 2: analyze + 수동 확인**

Run: `flutter analyze lib/features/film_roll/presentation/page/film_roll_screen.dart`
Expected: No issues found

Run: `flutter run` — 필름롤 화면 진입, 네트워크 끊고 방문 인증 → 배너 노출 →
네트워크 복구 후 "재시도" → "동기화 완료" 스낵바.

- [ ] **Step 3: Commit**

```bash
git add lib/features/film_roll/presentation/page/film_roll_screen.dart
git commit -m "feat: 필름롤 화면에 동기화 재시도 어피던스 추가

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 12: 전체 검증

- [ ] **Step 1: 전체 테스트**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 2: 전체 analyze**

Run: `flutter analyze`
Expected: No issues found

- [ ] **Step 3: 코드젠 최신화 확인**

Run: `dart run build_runner build --delete-conflicting-outputs`
Expected: `git status`에 변경 없음 (이미 커밋됨)

- [ ] **Step 4: 수동 시나리오**

1. 온라인 상태로 지역 진입 → 로그에 서버 생성 성공, 로컬 `serverFilmRollId` 채워짐
2. 방문 인증 → 서버 visit 호출 성공, `visitSyncedAt` 채워짐
3. 오프라인으로 지역 진입/방문 → 로컬만 진행, 화면 배너 노출
4. 온라인 복귀 + 재시도 → 생성/방문 따라잡음
5. 계정 전환 → 이전 계정 필름롤은 동기화 시도 안 함

- [ ] **Step 5: 최종 Commit (필요 시)**

```bash
git add -A
git commit -m "chore: 필름롤 백엔드 동기화 1차 마무리 검증

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Self-Review 메모

- **Spec 커버리지**: §2 목표(생성·방문·미러링·트리거·계정스코프) → Task 1~10. §5 스키마 → Task 1. §5.3 필터 → Task 2, 6. §6.1 생성 멱등/제한 → Task 6(멱등키 전송)·Task 7(4xx 보류). §6.2 방문 중복 → Task 8. §8 테스트 전략 → 각 Task의 TDD 스텝.
- **비목표 확인**: 사진 업로드/exit/develop/상태기반 완료 게이팅은 Task에 없음 (의도). 사진 업로드는 백엔드 "1장씩 업로드" API 합의됨 — Task 8 Step 4에서 TODO 주석만 남김 (spec §7.6).
- **멱등키 반영**: `FilmRollCreateRequest.clientFilmRollId` 추가(Task 6 Step 3a). `getCurrentFilmRoll` 주입/사용 없음. `/current` 호출 없음. Task 7은 "다른 CAPTURING 롤" 4xx를 무오류 보류로 처리(복구 로직 아님).
- **타입 일관성**: `syncFilmRoll(String)`, `FilmRollSyncResult` 필드명(`created`/`visitsPushed`/`visitsSkipped`/`serverStatus`/`error`/`hasError`)은 Task 6에서 정의, 7~11에서 동일 사용. `linkServerFilmRoll` 파라미터명 Task 5에서 정의, Task 6~7에서 동일.
- **오픈 질문(spec §7)**: 생성 제한/방문 중복 식별 코드 미확정 → Task 7·8에서 "넓게 매칭(4xx)" 기본값으로 구현하고 주석에 명시. 백엔드 확정 시 좁히는 후속 필요.
