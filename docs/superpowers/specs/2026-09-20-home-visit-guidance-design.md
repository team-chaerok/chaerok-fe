# 홈 화면 방문 인증 안내 개선 — 설계 문서

- 관련 이슈: [#110](https://github.com/team-chaerok/chaerok-fe/issues/110)
  "[기능개선][Home] 홈 화면 구성 개선 · 장소 인증 안내 친절화"
- 작성일: 2026-09-20
- 범위: 방문 인증(장소 인증) 상태별 안내 문구·CTA 개선에 집중한다. 이슈가 함께 언급한 "홈 화면
  전체 구성(섹션 배치)" 개선은 이번 범위에서 제외하고 별도로 다룬다(헤더·날씨·근처 채록 장소
  섹션 순서는 변경 없음).

## 문제

- 홈 화면의 필름롤 갤러리(`RegionPhotoGallery`)는 빈 필름 칸을 탭하면 거리·GPS 정확도 확인 없이
  무조건 카메라(`VisitCaptureScreen`)를 바로 연다. 사용자가 장소에서 멀리 떨어져 있어도 인증
  불가 안내 없이 카메라부터 뜬다.
- 반대로 채록길 탭(`FilmRollProgressView`)은 이미 `evaluateVisitGate`
  (`lib/features/film_roll/domain/visit_verification.dart`)로 거리(100m)·GPS 정확도(50m) 게이트를
  평가하고, 상태별 안내 문구(`VisitGateResult.message`)와 "방문 인증하기" CTA를 담은 "다음 장소"
  카드를 이미 갖고 있다.
- 즉 "어떻게 인증하는지" 안내 체계는 이미 존재하지만 홈 화면에는 적용되어 있지 않다 — 이슈가
  말하는 "안내 부족"의 실체.

## 해결 방향

채록길 탭이 이미 검증한 게이트/문구 체계를 홈 화면에도 그대로 적용하고, 카드 UI의 공통 부분만
공유 위젯으로 추출해 두 화면의 인증 UX를 일관되게 만든다.

### 1. 신규 공유 위젯 (`lib/features/film_roll/presentation/widgets/`)

두 화면 모두 이미 `film_roll` 피처(도메인)에 의존하고 있으므로 이 피처 아래에 둔다.

- **`GuidanceCard`** — 테두리 있는 서피스 카드 컨테이너(제목 캡션 + child). 채록길 탭의
  `_buildNextSpotCard`/`_buildFreeCaptureCard`가 지금 각자 손으로 그리는 `Container` 스타일
  (`ChaerokColors.surface` 배경, `ChaerokRadius.md`, `ChaerokColors.primary` 테두리, 제목
  캡션 텍스트)을 대체한다.
- **`VisitGateMessage`** — `VisitGateResult`를 받아 `gate.message`를 상태별 색(`canVerify`면
  `ChaerokColors.primaryDark`, 아니면 `ChaerokColors.textSecondary`)으로 그리는 텍스트 위젯.
  지금 `film_roll_progress_view.dart`(카드 렌더링용)와 잠재적으로 홈에서 중복될 색 분기 로직을
  하나로 합친다.

두 위젯 다 순수 프레젠테이션(상태 없음)이며, 기존 `VisitGateResult`/`VisitGateStatus`
(`visit_verification.dart`)는 변경하지 않는다.

### 2. 채록길 탭 리팩터 (`film_roll_progress_view.dart`)

`_buildNextSpotCard`/`_buildFreeCaptureCard`의 컨테이너·제목·상태 문구 부분을 `GuidanceCard`/
`VisitGateMessage`로 교체한다. "필름 카메라 열기"/"다음 코스 둘러보기" 버튼 줄, 필터 로우, 지역
이탈 배너 등 채록길 전용 로직은 그대로 둔다 — 순수 스타일 리팩터이며 게이트 평가 로직·콜백 구조는
바꾸지 않는다.

### 3. 홈 화면 — `RegionPhotoGallery`에 안내 섹션 추가

`_buildHero`와 `_FilmStrip` 사이에 새 섹션을 추가한다.

- **미방문 장소가 있으면** (`_nextPlace != null`, 방문 순서상 아직 인증하지 않은 첫 장소):
  `GuidanceCard('다음 장소', ...)` — 장소 이름·주소·`VisitGateMessage(gate)`·"방문 인증하기"
  버튼.
- **코스 필수 3곳을 모두 인증했고 필름이 남았으면** (`_nextPlace == null` &&
  `photoCount < FilmRoll.maxExposureCount`): `GuidanceCard('자유 촬영', ...)` — 안내문·
  `photoCount/maxExposureCount` 표시·"필름 카메라 열기" 버튼(게이트 없음).
- **그 외**(장소 없음 / 필름 소진): 섹션 자체를 숨긴다. 필름 소진 여부는 이미 하단
  `"n / 24"` 카운터로 알 수 있으므로 별도 안내 불필요.

`_nextPlace`/`_mostRecentlyVisitedPlace` 게터는 `film_roll_progress_view.dart`의 동명 게터와
같은 방식(정렬 후 `isVisited` 순회)으로 `RegionPhotoGallery` 내부에 각각 구현한다 — 짧은 리스트
연산이라 공유 추출하지 않고 화면별로 둔다(두 화면의 결합도를 낮게 유지).

### 4. 위치 데이터 흐름

- `HomeDashboardScreenState`가 이미 보유한 `_locationResult?.position`
  (`home_dashboard_screen.dart:69`, 날씨 조회에도 쓰는 값)을 `RegionPhotoGallery`에
  `currentPosition` 파라미터로 그대로 전달한다 — 새 위치 조회/라이프사이클 로직 불필요.
- `RegionPhotoGallery`에 `@visibleForTesting Future<Position?> Function()?
  debugFetchCurrentPosition` 훅을 추가한다(기본값 `LocationPermissionService.getCurrentPosition`).
  `HomeDashboardScreen.debugRunLocationVerification`과 동일한 기존 관례를 재사용한다.
- "방문 인증하기"(카드 CTA)와 필름스트립의 미방문 칸 탭을 **하나의 핸들러**
  (`_onVerifyTap(place)`)로 통합한다:
  1. `debugFetchCurrentPosition`(또는 기본 서비스)으로 탭 시점 신선한 좌표를 조회해 내부 상태
     `_refreshedPosition`에 저장(이후 렌더는 `widget.currentPosition` 대신 이 값을 우선 사용).
  2. `evaluateVisitGate`로 게이트 평가.
  3. `!gate.canVerify`면 `ScaffoldMessenger`로 `gate.message`만 보여주고 종료(카메라 안 염).
  4. 통과하면 기존 `_onPlaceTileTap`과 동일하게 `VisitCaptureScreen` push →
     `FilmRollModule.instance.completeVisit(place.id)` → `filmRollSyncService.syncFilmRoll(...)` →
     `onVisitCompleted()`.
- "자유 촬영" CTA는 별도 핸들러 `_onFreeCaptureTap(place)`로, 게이트 평가 없이 바로
  `VisitCaptureScreen`을 열고, 반환 후 동기화는 하되 `completeVisit`은 호출하지 않는다(이미
  인증된 장소이므로) — 채록길의 `_onOpenCameraTap`과 동일한 의미.
- `_refreshedPosition`은 `RegionPhotoGallery` 내부 상태로만 두고 부모(`HomeDashboardScreen`)로
  올리지 않는다 — 채록길과 달리 홈은 지역 이탈 판정 등 위치를 계속 추적해야 하는 다른 용도가
  없으므로 이 범위에서는 불필요.

## 상태별 안내 문구 · CTA 매핑

`VisitGateStatus`(변경 없음)를 그대로 쓴다. 문구는 새로 만들지 않고 기존
`VisitGateResult.message`를 재사용해 채록길과 홈이 동일한 카피를 쓰게 한다.

| 상태 | 문구(기존 `gate.message`) | 홈에서 보이는 형태 |
|---|---|---|
| `ok` | "지금 방문 인증할 수 있어요" | "다음 장소" 카드, 문구 `primaryDark`, "방문 인증하기" 버튼 |
| `tooFar` | "장소에 더 가까이 가면 방문 인증할 수 있어요" | 같은 카드, 문구 `textSecondary`. 버튼 탭 시 스낵바로 재안내, 카메라 안 열림 |
| `inaccurate` | "현재 위치가 정확하지 않아요. 잠시 후 다시 시도해주세요" | 위와 동일 |
| `noPosition` | "현재 위치를 확인하는 중이에요" | 위와 동일 |
| `alreadyVisited` | — | 필름스트립에서 이미 사진이 있는 칸은 이 경로 자체를 타지 않음(기존 동작 유지) |
| 필수 3곳 인증 + 필름 잔여 | — | "자유 촬영" 카드, 게이트 없이 항상 활성 |
| 필수 3곳 인증 + 필름 소진 | — | 안내 섹션 숨김 |

## 에러 처리

- 위치 권한 거부/조회 실패는 `getCurrentPosition()`이 `null`을 반환하는 기존 동작을 그대로
  따른다 → `noPosition` 상태로 자연 처리(새 에러 문구 없음, 채록길과 동일 선례).
- 탭 중복 방지: `_onVerifyTap` 진행 중 플래그(`_isVerifyingLocation`류)로 재탭 무시 — 채록길의
  동명 패턴 재사용.
- `completeVisit`/동기화 실패 시 처리는 기존 `_onPlaceTileTap`의 정책(로그만 남기고 사진 push는
  그대로 진행)을 그대로 유지한다 — 이번 변경과 무관.

## 테스트 계획

- **깨지는 기존 테스트**: `test/features/home/presentation/widgets/region_photo_gallery_test.dart`의
  "아직 인증하지 않은 장소 타일을 누르면 그 장소를 인증하는 카메라 화면이 열린다"(197행) —
  `debugFetchCurrentPosition`으로 장소 좌표(36.0/127.0) 반경 안 좌표를 주입하도록 수정해야 통과한다.
- **신규 테스트** (`region_photo_gallery_test.dart`):
  - 반경 밖 좌표 주입 → 탭해도 `VisitCaptureScreen`이 열리지 않고 스낵바에 `tooFar` 문구가 뜸.
  - `debugFetchCurrentPosition`이 `null` 반환 → `noPosition` 문구, 카메라 안 열림.
  - 코스 필수 3곳 모두 `isVisited: true` + `photoCount < 24` → "자유 촬영" 카드 노출, 탭 시
    게이트 평가 없이 `VisitCaptureScreen`이 열림.
  - `photoCount == 24`(필름 소진) → 안내 섹션이 렌더되지 않음.
  - 미방문 장소가 있을 때 "다음 장소" 카드에 이름·주소·상태 문구가 올바르게 표시됨.
- **신규 위젯 테스트**: `guidance_card_test.dart`, `visit_gate_message_test.dart` — 상태별
  색상·문구 렌더링만 검증(순수 프레젠테이션 위젯).
- **회귀 리스크**: `film_roll_progress_view.dart`는 현재 위젯 테스트가 전혀 없다. 리팩터 후
  자동 테스트로 잡을 수 없으므로 구현 단계에서 채록길 탭 수동 스모크 테스트(다음 장소 카드·자유
  촬영 카드 렌더 확인)가 필요하다.

## 범위 밖

- 홈 화면 섹션 배치(헤더/날씨/근처 채록 장소 순서·강조) 재구성 — 이슈의 "전체 구성 개선" 부분은
  별도로 다룬다.
- 위치를 지속적으로 추적하는 스트림 도입 — 채록길 탭처럼 지역 이탈 감지가 필요 없는 홈에서는
  탭 시점 1회 조회로 충분하다고 판단.
- `_nextPlace`/`_mostRecentlyVisitedPlace` 게터의 화면 간 공통 추출 — 짧은 로직이라 중복 허용,
  대신 카드 UI(`GuidanceCard`/`VisitGateMessage`)만 공유한다.
