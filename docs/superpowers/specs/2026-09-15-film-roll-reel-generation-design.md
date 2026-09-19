# 필름롤 현상 결과 페이지 및 릴스 생성 연동 — 설계 문서

- 관련 이슈 초안: `docs/suh-template/issue/20260915_109_기능추가_필름롤_현상결과_페이지_및_릴스_생성_API_연동.md`
- 작성일: 2026-09-15

## 배경 / 문제 정의

필름롤이 지역 이탈을 확정하면(`ExitFilmRollUseCase`) 서버는 현상 조건(서로 다른 관광 유형 3개 + 사진 1장 이상)을 판정해 `developAvailableAt`(이탈 시각 +1시간)을 내려주고 상태를 `developing`으로 전환한다. 그러나:

- FE에는 이후 진행 상황을 조회하거나 완료를 감지하는 코드가 전혀 없다. `FilmRollDevelopingView`는 카운트다운만 보여주고, "완료되면 필름 컬렉션에서 직접 확인하라"는 안내로 끝난다.
- 촬영 사진을 릴스(짧은 영상)로 만들어 보여주는 화면 자체가 없다.
- 개발 단계에서는 1시간 대기 없이 이탈 즉시 릴스가 만들어지는 것을 확인하고 싶다.

### 백엔드 조사 결과 (중요 전제)

`chaerok-be`를 확인한 결과, 릴스 생성 파이프라인은 이미 백엔드에 전부 구현되어 있다:

- `lambda/render/` — FFmpeg 기반 릴스 렌더링 Lambda (템플릿 시스템 포함)
- `POST /api/film-rolls/{id}/develop` (`FilmRollDevelopmentController`) — 현상(릴스 생성) 즉시 요청 API. CAPTURING/READY/FAILED 상태에서 호출 가능, QUEUED/PROCESSING이면 기존 상태 반환.
- `GET /api/film-rolls/{id}/results` (`FilmRollResultController`) — 진행 상태 조회. `COMPLETED`면 필터 사진/zip/릴스의 짧은 만료시간 presigned URL을 반환.
- `FilmRollAutoDevelopmentScheduler`가 60초마다 폴링해 `developAvailableAt <= now`인 필름롤을 자동으로 현상 요청한다(일반 사용자 경로).
- **`User.reviewMode` 플래그**: 원래 앱스토어 심사용으로 만들어진 기능이지만, 이 플래그가 켜진 계정은 `/develop` 호출 시 `FilmRollDevelopmentTimingService`의 1시간 대기 검사가 완전히 면제된다(`filmRoll.getUser().isReviewMode()`이면 즉시 통과). 현재 사용 중인 테스트 계정은 이미 `reviewMode=true`로 설정되어 있음을 확인했다.

**결론**: "이탈 즉시 릴스 생성"은 백엔드 코드 변경 없이, FE가 이탈 확정 직후 스케줄러(60초~1시간)를 기다리지 않고 바로 `POST /develop`을 호출하는 것만으로 달성된다. 일반 계정(`reviewMode=false`)은 서버가 동일한 코드 경로에서 자동으로 1시간 대기를 강제하므로, dev/prod 분기 코드가 FE에 필요 없다 — 즉시 호출은 프로덕션에서도 안전하다.

## 전체 데이터 흐름

```
지역 이탈 확정 (ExitFilmRollUseCase) → 로컬 status = developing
        ↓
[현상 대기 화면 진입] 즉시 POST /develop 호출
        ↓
GET /results 폴링 (2~3초 간격, 웹소켓/푸시 없음 — 폴링으로 확정)
        ↓
status = COMPLETED → 로컬 FilmRollStatus.completed로 갱신 + 결과 데이터 보유
        ↓
[현상 결과 페이지]로 자동 전환
```

- 폴링 중 `FAILED` / `EXPIRED` 응답을 받으면 대기 화면에 에러 안내만 표시(복잡한 재시도 UX는 범위 밖).
- 결과(사진/릴스 presigned URL)는 만료 시간이 있으므로 로컬 DB에 영구 저장하지 않는다. 현상 결과 페이지에 진입할 때마다 `/results`를 다시 호출해 최신 URL을 받는다.

## 컴포넌트 설계

### 1. API 계층 (`lib/data/remote/film_rolls_api.dart`)

기존 `FilmRollsApi`(dio 기반 static 메서드, 수동 `fromJson`) 패턴을 그대로 따라 2개 메서드 추가:

- `static Future<FilmRollDevelopmentResponse> developFilmRoll(int filmRollId)` → `POST /api/film-rolls/{id}/develop`
- `static Future<FilmRollResultResponse> getFilmRollResult(int filmRollId)` → `GET /api/film-rolls/{id}/results`

### 2. DTO (`lib/data/models/`)

백엔드 record를 그대로 미러링:

- `FilmRollDevelopmentResponse { filmRollId, status, totalPhotoCount, requestedAt }`
- `FilmRollResultResponse { filmRollId, status, totalPhotoCount, processedPhotoCount, filteredPhotos: List<FilteredPhotoResponse>, zip: DownloadResponse?, reel: DownloadResponse?, requestedAt, completedAt, expiresAt, failure: FailureResponse? }`
  - `FilteredPhotoResponse { photoId, sequence, downloadUrl, downloadUrlExpiresAt }`
  - `DownloadResponse { downloadUrl, downloadUrlExpiresAt, fileSize }`
  - `FailureResponse { code, message }`

### 3. 도메인 계층

- `DevelopFilmRollUseCase` — `FilmRollsApi.developFilmRoll` 호출. 실패해도 로컬 상태를 바꾸지 않고 예외만 던진다(다음 단계 폴링에서 자연히 재확인됨).
- `WatchFilmRollResultUseCase` — `Stream<FilmRollResultResponse>` 반환. 2~3초 간격으로 `GET /results`를 호출해 `status`가 `COMPLETED`/`FAILED`/`EXPIRED`가 될 때까지 반복하고, 해당 상태에서 스트림을 닫는다.

### 4. `film_roll_developing_view.dart` 수정

- `initState`에서 `DevelopFilmRollUseCase` 즉시 실행 → 성공 시 `WatchFilmRollResultUseCase` 구독 시작.
- `COMPLETED` 수신 시: `FilmRollRepository`로 로컬 상태를 `FilmRollStatus.completed`로 갱신하고, 결과 데이터를 들고 현상 결과 페이지로 `Navigator.push`(자동 전환, 뒤로가기로 대기 화면에 못 돌아오게 push replacement 고려).
- `FAILED`/`EXPIRED` 수신 시: 기존 UI 톤에 맞춰 에러 안내만 표시.
- 화면 문구를 "1시간 후 완료돼요"에서 "현상 진행 중이에요" 톤으로 조정.
- 기존 `_fallbackDevelopDuration`(1시간, `ExitFilmRollUseCase`)은 그대로 유지 — 서버가 `developAvailableAt`을 안 줄 때의 표시용 폴백이며, 실제 생성 타이밍과는 무관해졌다.

### 5. 현상 결과 페이지 (신규)

`lib/features/film_roll/presentation/page/film_roll_result_screen.dart`

목업 레이아웃 매핑:

| 목업 요소 | 데이터 출처 |
|---|---|
| 타이틀 ("공주 필름 롤") | `FilmRoll.title` (로컬) |
| 지역 표기 ("GONGJU · 공주") | `FilmRoll.regionCode` + `regionName` (로컬) |
| 날짜 | `FilmRoll.completedAt` (로컬, `/results.completedAt`로 갱신) |
| 대표 이미지 | `/results.filteredPhotos`에서 `sequence` 최소(첫 장) |
| "방문 N곳" | `FilmRoll.visitedPlaceCount` (로컬, 기존 집계값) |
| "촬영 N장" | `/results.totalPhotoCount` |
| 오늘의 사진 (가로 스크롤 3장 + "전체 >") | `/results.filteredPhotos` 앞 3장. "전체 >"는 전체 그리드 화면(`film_roll_result_photos_screen.dart`, 신규)으로 이동 |
| 오늘의 릴스 카드 | 썸네일은 대표 이미지 재사용 + 재생 버튼 오버레이. 탭하면 전체화면 비디오 플레이어로 이동(카드 내 인라인 재생은 하지 않음 — 리스트 스크롤 중 리소스 낭비 방지) |
| 저장하기 | `reel.downloadUrl`을 `dio`로 `path_provider` 임시 디렉토리에 받은 뒤 `gal.putVideo()`로 갤러리 저장 |
| 공유하기 | 같은 방식으로 받은 mp4를 `share_plus`의 `Share.shareXFiles()`로 공유 시트 호출 |

둘 다 다운로드 중 로딩 인디케이터, 실패 시 스낵바 정도의 최소 에러 처리만 포함한다.

### 6. 신규 패키지 (pubspec.yaml)

- `video_player` — 릴스 전체화면 재생
- `gal` — 갤러리 저장(iOS/Android 권한 처리 내장)
- `share_plus` — OS 공유 시트

`dio`, `path_provider`는 이미 프로젝트에 있어 추가 불필요.

## 에러 처리

- `/develop` 호출 실패(네트워크 등): 상태 변경 없이 대기 화면 유지, 폴링 단계에서 다음 성공 시 정상 진행.
- `/results`가 `FAILED`를 반환: `failure.code`/`message`를 그대로 노출하는 간단한 에러 문구 표시.
- `/results`가 `EXPIRED`를 반환(결과 보관 기간 만료): 별도 처리 없이 만료 안내만 표시(다운로드 링크 없음).
- presigned URL 만료: 결과 페이지 재진입 시마다 `/results`를 다시 호출하므로 자연히 최신 URL로 갱신됨.

## 테스트 계획

- `DevelopFilmRollUseCase`, `WatchFilmRollResultUseCase`: 유닛 테스트(성공/실패/폴링 종료 조건).
- `film_roll_developing_view.dart`: 위젯 테스트로 즉시 develop 호출 → 폴링 → 완료 시 네비게이션 트리거 검증.
- `film_roll_result_screen.dart`: 위젯 테스트로 목업 데이터 기준 레이아웃 렌더링(대표 이미지/카운트/사진 3장/릴스 카드) 검증.
- 저장하기/공유하기는 플랫폼 채널 의존적이라 유닛 테스트로는 다운로드 로직까지만 검증하고, 실제 갤러리 저장/공유 시트는 수동 QA(iOS/Android 실기기)로 확인.
- 리뷰 모드 계정으로 실제 서버(`chaerok-be` 개발 환경)까지 붙여 이탈 → 즉시 릴스 생성 → 결과 페이지까지 end-to-end 수동 검증.

## 범위 밖

- 백엔드 코드 변경 (기존 `/develop`, `/results`, `reviewMode` 로직 그대로 사용)
- 웹소켓/푸시 기반 완료 알림 (폴링으로 확정)
- 릴스 생성 실패 시 자동 재시도 UX
- 원래 스펙의 "1시간 후 알림" 기능 (개발 단계 범위 밖으로 명시적으로 제외)
