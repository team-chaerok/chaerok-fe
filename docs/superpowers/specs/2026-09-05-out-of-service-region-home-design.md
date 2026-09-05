# 충남 외 지역 홈 화면 설계 (이슈 #74)

**날짜:** 2026-09-05
**상태:** 초안
**이슈:** [#74 ⚙️[기능추가][위치인증] 서비스 지역 외 사용자에게 지역별 코스 둘러보기 제공](https://github.com/team-chaerok/chaerok-fe/issues/74)
**Figma:**
- [B_02 홈화면 - 충남 외부 지역 (15-521)](https://www.figma.com/design/Rki7yHSp1l2752zt6JBfcg/%EC%B1%84%EB%A1%9D?node-id=15-521&m=dev)
- [B_02 홈화면 - 충남 외부 지역 - 섹션 전환 (15-623)](https://www.figma.com/design/Rki7yHSp1l2752zt6JBfcg/%EC%B1%84%EB%A1%9D?node-id=15-623&m=dev)

---

## 목표

충청남도 외 지역에서 접속한 사용자에게, 지금의 막다른 안내 화면 대신
**홈 탭에서 4개 지역(공주·부여·서산·예산)을 지역별로 둘러볼 수 있는 화면**을
제공한다. 필름롤 시작은 여전히 충남에서만 가능하며, 이 화면은 읽기 전용
"둘러보기" 경험이다.

- 위치 인증이 "서비스 지역 외"로 끝나면 홈 탭이 `OutOfServiceHomeView`를 렌더한다.
- 상단 필름롤 스택(아코디언)에서 지역을 고르면 해당 지역의 소개·해시태그·
  장소 이미지 캐러셀·추천 채록길 배너·"이런 장소를 만나보세요" 목록이 열린다.
- 추천 채록길 배너와 "전체보기"는 모두 **채록길(Explore) 탭**으로 이동하며
  해당 지역이 선택된 상태로 진입한다.

### 현재 동작 (변경 전)

- `HomeDashboardScreen`이 마운트 시 `LocationVerificationScreen`을 push한다.
- 시·도가 충청남도가 아니면 `_Step.outOfServiceArea` → "서비스 지역이 아니에요 /
  메인으로 돌아가기" 카드가 뜨고 `Navigator.pop()`으로 **`null`을 반환**한다
  ([location_verification_screen.dart:318](../../../lib/features/location/presentation/location_verification_screen.dart#L318)).
- 그 결과 `_locationResult`가 계속 `null`이라 홈 탭은 빈 상태가 된다
  (시작 카드 비활성, 날씨 없음, 근처 장소 없음).

---

## 전체 흐름

```
HomeDashboardScreen.initState
  └─ _ensureLocationVerified()
       └─ LocationVerificationScreen.push() → LocationVerificationOutcome 반환
            ├─ LocationVerified(result)   → 기존 경로 (_onLocationVerified)
            ├─ LocationOutOfService()     → setState(_isOutOfService = true)
            └─ null (뒤로가기/취소)       → 아무것도 안 함

HomeDashboardScreen.build
  ├─ _isOutOfService == true  → OutOfServiceHomeView(onExploreRegionRequested: ...)
  └─ 그 외                    → 기존 대시보드 Column

OutOfServiceHomeView
  1. _selected = RegionCode.yesan (Figma 기본값)
  2. _ensureLoaded(_selected)
       └─ RegionsApi.resolveRegion(충청남도, {지역}시/군) → regionId
       └─ PlacesApi.getExternalPlaces(regionId) → places → 캐시에 저장
  3. 상단 필름롤 헤더 탭 → setState(_selected = 새 지역) → _ensureLoaded(새 지역)
  4. 추천 채록길 배너 / "전체보기" 탭
       └─ onExploreRegionRequested(region)
            └─ MainTabScreen: 채록길 탭으로 전환 + ExploreScreenState.selectRegion(region)
```

---

## 컴포넌트 설계

### 1. 위치 인증 결과 타입 변경

**`lib/features/location/data/location_verification_result.dart`**

`sealed class LocationVerificationOutcome`를 추가한다.

```dart
sealed class LocationVerificationOutcome {
  const LocationVerificationOutcome();
}

/// 인증 성공 — 서비스 지역(충남) 내부.
class LocationVerified extends LocationVerificationOutcome {
  const LocationVerified(this.result);
  final LocationVerificationResult result;
}

/// 서비스 지역 외 — 지역별 둘러보기 모드로 진입한다.
/// 시·도 판별 단계에서 끊기므로 regionId 등 payload는 없다.
class LocationOutOfService extends LocationVerificationOutcome {
  const LocationOutOfService();
}
```

- 세션 캐시: 기존 `static LocationVerificationResult? sessionCache`는 **그대로 둔다**
  (`my_screen.dart`, `film_roll_sync_service.dart`가 이 필드를 직접 읽으므로 이름/타입
  변경 시 광범위한 수정 발생). 대신 `location_verification_result.dart`에
  `static bool outOfServiceSessionCache = false;`를 **추가**한다.
  - `LocationVerificationScreen`이 "서비스 지역 외" 판정 시 `= true`로 설정.
  - `HomeDashboardScreen._ensureLocationVerified()`는 `sessionCache`(성공) 먼저
    확인 → 없으면 `outOfServiceSessionCache` 확인 → 둘 다 아니면 인증 화면 push.
- 이유: 홈 탭 재진입/`didChangeAppLifecycleState` 시 인증 흐름(Kakao/백엔드
  재호출)을 다시 타지 않기 위함. "서비스 지역 외" 판정도 세션 내 1회로 고정한다.

**`lib/features/location/presentation/location_verification_screen.dart`**

- 반환 타입을 `LocationVerificationResult?` → `LocationVerificationOutcome?`로 바꾼다
  (`_run()` 내부 `Navigator.pop` 호출부, `_LocationVerificationScreenState`의
  제네릭 인자 포함).
- 성공 시 `Navigator.pop(LocationVerified(result))`.
- `_Step.outOfServiceArea` 카드:
  - 안내 문구는 유지하되, "충청남도 전용 기능은 이용이 제한됩니다."에 더해
    "지역별로 둘러볼 수 있어요." 한 줄 추가.
  - 버튼 라벨 `메인으로 돌아가기` → `지역별로 둘러보기`.
  - `onPressed` → `Navigator.of(context).pop(const LocationOutOfService())`.
- `_serviceProvinceName` 체크 후 `_step = _Step.outOfServiceArea`로 가는
  분기([location_verification_screen.dart:170-176](../../../lib/features/location/presentation/location_verification_screen.dart#L170))와
  `!region.serviceArea` 분기([:205](../../../lib/features/location/presentation/location_verification_screen.dart#L205))
  둘 다 동일하게 이 카드로 수렴한다 — 그대로 둔다.
- `kDebugMode` 폴백(`_debugFallbackProvinceName`)은 변경하지 않는다.

### 2. 지역 소개 데이터 — 클라이언트 하드코딩

**신규 `lib/shared/region/region_guide.dart`**

```dart
import 'package:chaerok/shared/region/region_code.dart';

/// 충남 외 지역 홈 화면의 지역 소개 카피. 디자이너/백엔드 소스가 없어
/// 클라이언트에 하드코딩한다. Figma에 노출된 예산·서산은 그대로,
/// 공주·부여는 초안 카피.
class RegionGuide {
  const RegionGuide({
    required this.romanized,
    required this.tagline,
    required this.hashtags,
  });

  /// 자간을 벌려 표시하는 로마자 라벨. 예: "Y E S A N"
  final String romanized;

  /// 1~2줄 지역 소개 문구.
  final String tagline;

  /// 해시태그 칩 텍스트(# 제외). 정확히 3개.
  final List<String> hashtags;
}

const Map<RegionCode, RegionGuide> kRegionGuides = {
  RegionCode.gongju: RegionGuide(
    romanized: 'G O N G J U',
    tagline: '백제의 왕도, 공산성과 무령왕릉이 있는 역사의 도시',
    hashtags: ['공산성', '무령왕릉', '갑사'],
  ),
  RegionCode.buyeo: RegionGuide(
    romanized: 'B U Y E O',
    tagline: '사비 백제의 마지막 수도, 부소산과 궁남지가 있는 곳',
    hashtags: ['부소산성', '궁남지', '정림사지'],
  ),
  RegionCode.seosan: RegionGuide(
    romanized: 'S E O S A N',
    tagline: '바다와 갯벌, 노을이 어우러진 느린 여행의 도시',
    hashtags: ['해미읍성', '간월도', '서산버드랜드'],
  ),
  RegionCode.yesan: RegionGuide(
    romanized: 'Y E S A N',
    tagline: '고즈넉한 사찰과 넓은 호수, 시장의 온기가 함께 있는 곳',
    hashtags: ['수덕사', '예당호', '예산시장'],
  ),
};

extension RegionGuideX on RegionCode {
  RegionGuide get guide => kRegionGuides[this]!;
}
```

- 캐러셀 이미지·장소 목록은 **기존 API** `PlacesApi.getExternalPlaces(regionId)`
  재사용(`ExploreScreen._fetchPlaces`와 동일 경로).
- `regionId`는 `RegionsApi.resolveRegion(ResolveRegionRequest(provinceName: '충청남도',
  cityCountyName: region.cityCountyName))`로 지연 조회 후 캐시.

### 3. `OutOfServiceHomeView`

**신규 `lib/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart`**

`StatefulWidget`.

생성자 파라미터:

| 파라미터 | 타입 | 기본값 | 용도 |
|---|---|---|---|
| `onExploreRegionRequested` | `ValueChanged<RegionCode>` | (필수) | 배너/전체보기 탭 시 채록길 탭 이동 |
| `regionIdResolver` | `Future<int> Function(RegionCode)` | `_defaultResolveRegionId` | 테스트 주입 seam |
| `placesFetcher` | `Future<List<PlaceListResponse>> Function(int regionId)` | `PlacesApi.getExternalPlaces` | 테스트 주입 seam |

기본 `regionIdResolver`는 위 `RegionsApi.resolveRegion` 호출을 감싼 top-level 함수.

상태:

```dart
RegionCode _selected = RegionCode.yesan;   // Figma 15-521 기본값
final Map<RegionCode, _RegionData> _cache = {};
int _requestToken = 0;                     // 최신 요청만 반영 (기존 화면들과 동일 패턴)

class _RegionData {
  const _RegionData({required this.status, this.regionId, this.places = const [], this.error});
  final _LoadStatus status;                // loading | ready | error
  final int? regionId;
  final List<PlaceListResponse> places;
  final Object? error;
}
```

- `initState` + `_selected` 변경 시 `_ensureLoaded(_selected)` 호출.
- `_ensureLoaded`: 캐시에 `ready`면 return, 아니면 `loading`으로 setState →
  `regionIdResolver` → `placesFetcher` → 토큰 확인 후 `ready`/`error` setState.
- 지역 전환 시 이미 로드된 지역은 즉시 표시(재요청 없음).

레이아웃:

```
Scaffold(backgroundColor: ChaerokColors.background)
 └ SafeArea
    └ Column
       ├ _RegionFilmStrip(
       │     selected: _selected,
       │     onSelect: (r) => setState(() => _selected = r),
       │   )
       └ Expanded
          └ _RegionDetailPanel(
                region: _selected,
                data: _cache[_selected],
                onRetry: () => _ensureLoaded(_selected, force: true),
                onExploreRegionRequested: widget.onExploreRegionRequested,
            )
```

> 참고: Figma 상단의 배경 원(`HomeDashboardScreen`의 `sageLight` 원형 backdrop)은
> 홈 정체성 유지를 위해 동일 패턴으로 뒤에 깔 수 있다. 필수는 아니며 구현 시 판단.

### 4. `_RegionFilmStrip` (아코디언 · 단일 선택)

**신규 `.../out_of_service/region_film_strip.dart`**

- 4개 지역 헤더를 **고정 순서**(gongju → buyeo → seosan → yesan)로 세로 스택.
- 각 헤더 = 필름 스트립 느낌의 얇은 띠: 왼쪽 지역명(정림사지체 16), 오른쪽
  스프로킷 구멍(작은 사각형 3개) + 썸네일 살짝 보이는 영역.
- `selected`가 아닌 헤더는 **음수 top margin / Stack**으로 살짝 겹쳐 쌓아
  Figma의 "필름이 포개진" 모양을 근사한다. (픽셀 완벽 재현 아님 — 리스크 3 참고)
- 접힌 헤더 탭 → `onSelect(region)`. 선택된 헤더는 위로 올라와 강조.
- 상세 패널은 이 위젯이 아니라 부모(`_RegionDetailPanel`)가 그린다.

### 5. `_RegionDetailPanel`

**신규 `.../out_of_service/region_detail_panel.dart`** (또는 `out_of_service_home_view.dart` 내부 private)

`data.status`에 따라:

- `loading` → `Center(child: ChaerokLoadingIndicator())`
- `error` → 중앙 정렬 안내 텍스트 + `TextButton('다시 시도', onPressed: onRetry)`
- `ready && places.isEmpty` → `Center(child: Text('이 지역의 장소 정보가 없어요'))`
- `ready` → `SingleChildScrollView`:

```
Column(crossAxisAlignment: start)
 ├ _RegionIntro(region)
 ├ SizedBox(ChaerokSpacing.md)
 ├ _HashtagRow(region.guide.hashtags)
 ├ SizedBox(ChaerokSpacing.lg)
 ├ _RegionCarousel(places)                      // 아래 6
 ├ SizedBox(ChaerokSpacing.lg)
 ├ _RecommendedCourseBanner(region, onTap: () => onExploreRegionRequested(region))
 ├ SizedBox(ChaerokSpacing.xl)
 └ _RegionPlaceStrip(region, places, onSeeAll / onCardTap → onExploreRegionRequested(region))
```

**`_RegionIntro`**

```
Column(crossAxisAlignment: start)
 ├ Text(guide.romanized, style: caption.copyWith(letterSpacing: 2, color: primaryDark))
 ├ Text(region.displayName, style: 정림사지체 36 — 아래 리스크 2)
 └ Text(guide.tagline, style: bodyMedium.copyWith(color: textPrimary))
```

**`_HashtagRow`** — `Wrap(spacing: ChaerokSpacing.xs)`, 각 칩:

```
Container(
  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
  decoration: BoxDecoration(color: ChaerokColors.sageLight,
    borderRadius: BorderRadius.circular(ChaerokRadius.lg)),
  child: Text('# ${tag}', style: bodyMedium.copyWith(color: ChaerokColors.primaryDark)),
)
```

### 6. `_RegionCarousel`

**신규 `.../out_of_service/region_carousel.dart`**

- 입력: `List<PlaceListResponse> places` → `firstImageUrl`이 비어있지 않은
  앞쪽 **최대 5개**만 사용. 하나도 없으면 `_PlaceImagePlaceholder` 1장.
- `AspectRatio` 또는 고정 높이(≈200) `PageView`.
- 우하단 `n/total` 뱃지: `Container(bg: black54, radius 6)` + `Text('${index+1}/${count}')`.
- 이미지는 공용 `PlaceImage`(아래 8) 사용.

### 7. `_RecommendedCourseBanner`

**신규 `.../out_of_service/recommended_course_banner.dart`**

```
Material(color: Color(0xFFEBEEE3), borderRadius: ChaerokRadius.sm)
 └ InkWell(onTap)
    └ Padding(EdgeInsets.symmetric(horizontal: 16, vertical: 12))
       └ Row
          ├ Icon(Icons.map_outlined, size 24, color primaryDark)
          ├ SizedBox(16)
          ├ Expanded > Column
          │   ├ Text('${region.displayName} 추천 채록길', style: caption.bold color 0xFF3C3F2F)
          │   └ Text('${region.displayName}의 매력을 담은 코스를 확인해보세요',
          │           style: caption.copyWith(color: primaryDark))
          └ Icon(Icons.chevron_right_rounded, color textSecondary)
```

- `onTap` → `onExploreRegionRequested(region)`.
- Figma의 `bi:map` 아이콘은 머티리얼 `Icons.map_outlined`로 대체(에셋 미도입).

### 8. `_RegionPlaceStrip` + 공용 `PlaceImage`

**신규 `.../out_of_service/region_place_strip.dart`**

```
Column(crossAxisAlignment: start)
 ├ Row(mainAxisAlignment: spaceBetween)
 │   ├ Text('${region.displayName}에서 이런 장소를 만나보세요', style: bodyMedium.bold)
 │   └ InkWell(onTap: onSeeAll) > Row[ Text('전체보기', caption color textDisabled),
 │                                     Icon(chevron_right, size 12) ]
 ├ SizedBox(ChaerokSpacing.sm)
 └ SizedBox(height: ~150) > ListView.separated(
       scrollDirection: horizontal,
       itemCount: min(places.length, 10),
       itemBuilder: _RegionPlaceCard,
   )
```

`_RegionPlaceCard` (너비 ≈121):

```
InkWell(onTap: onCardTap)
 └ Column
    ├ ClipRRect(radius top 16) > SizedBox(height 81) > PlaceImage(url: place.firstImageUrl, mood: ...)
    ├ Row[ Icon(Icons.place, size 12, color primaryDark), Text(place.title, maxLines 1, ellipsis, bodyMedium 10) ]
    └ Text(place.categoryDetail, maxLines 1, ellipsis, caption 8 color black60)
```

**공용화: `lib/features/home/presentation/widgets/place_image.dart`**

- 현재 `recommended_place_card.dart` 안의 private `_PlaceImage`(TourAPI
  `http://` → `https://` 승격 + 로딩/에러 폴백)와 `_PlaceImagePlaceholder` /
  `_SummerTownPainter`를 이 파일로 이동해 `PlaceImage` / `PlaceImagePlaceholder`로
  공개.
- `recommended_place_card.dart`는 새 공용 위젯을 import해서 사용하도록 수정
  (동작 동일, 순수 리팩터링).
- `PlacePlaceholderMood`는 이미 `home_card_data.dart`의 공개 enum이라 그대로 사용.

### 9. 채록길 탭 연결

**`lib/features/explore/presentation/explore_screen.dart`**

- `ExploreScreenState`에 공개 메서드 추가:

```dart
/// 홈(충남 외 지역 둘러보기)에서 특정 지역으로 채록길 탭 진입 시 호출.
void selectRegion(RegionCode region) {
  if (!mounted) return;
  unawaited(_onRegionSelected(region));  // 기존 private 로직 재사용 (검색 초기화 + _fetchPlaces)
}
```

> `_onRegionSelected`는 `region == _selectedRegion`이면 early return하므로,
> 이미 같은 지역이면 no-op. 필요 시 `selectRegion`에서 강제 갱신 여부 판단.

**`lib/features/home/presentation/home_dashboard_screen.dart`**

- `HomeDashboardScreen`에 `final ValueChanged<RegionCode>? onExploreRegionRequested;`
  파라미터 추가.
- `_HomeDashboardScreenState`에 `bool _isOutOfService = false;` 추가.
- `_ensureLocationVerified()`를 `LocationVerificationOutcome` 스위치로 변경:

```dart
// 1) 성공 세션 캐시
final cached = LocationVerificationResult.sessionCache;
if (cached != null) {
  setState(() => _locationResult = cached);
  unawaited(_onLocationVerified(cached));
  return;
}
// 2) 서비스 지역 외 세션 캐시
if (LocationVerificationResult.outOfServiceSessionCache) {
  setState(() => _isOutOfService = true);
  return;
}
// 3) 인증 화면 push
final outcome = await Navigator.of(context).push<LocationVerificationOutcome>(
  MaterialPageRoute(builder: (_) => const LocationVerificationScreen()),
);
if (!mounted) return;
switch (outcome) {
  case LocationVerified(:final result):
    setState(() => _locationResult = result);
    unawaited(_onLocationVerified(result));
  case LocationOutOfService():
    setState(() => _isOutOfService = true);
  case null:
    break; // 뒤로가기/취소
}
```

- `build()` 최상단에서 `if (_isOutOfService) return OutOfServiceHomeView(
  onExploreRegionRequested: (r) => widget.onExploreRegionRequested?.call(r));`

**`lib/features/home/presentation/main_tab_screen.dart`**

- `HomeDashboardScreen` 생성부에 콜백 전달:

```dart
HomeDashboardScreen(
  onExploreRegionRequested: (region) {
    setState(() => _selectedIndex = _exploreTabIndex);
    _exploreKey.currentState?.selectRegion(region);
  },
),
```

- `IndexedStack`의 `HomeDashboardScreen`은 현재 `const`라 `const` 제거.

---

## 변경 / 신규 파일 목록

| 파일 | 유형 | 내용 |
|---|---|---|
| `lib/features/location/data/location_verification_result.dart` | 수정 | `LocationVerificationOutcome` sealed class 추가, `static bool outOfServiceSessionCache` 추가 (`sessionCache`는 유지) |
| `lib/features/location/presentation/location_verification_screen.dart` | 수정 | 반환 타입 outcome화, `outOfServiceArea` 버튼 → `LocationOutOfService` pop, 문구/라벨 수정 |
| `lib/shared/region/region_guide.dart` | 신규 | `RegionGuide` + `kRegionGuides`(4개) + `RegionGuideX` |
| `lib/features/home/presentation/widgets/place_image.dart` | 신규 | `recommended_place_card.dart`의 `_PlaceImage`/placeholder/painter 이관·공개 |
| `lib/features/home/presentation/widgets/recommended_place_card.dart` | 수정 | 공용 `PlaceImage` import로 교체(동작 동일) |
| `lib/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart` | 신규 | 화면 컨테이너 + 상태/캐시/로드 |
| `lib/features/home/presentation/widgets/out_of_service/region_film_strip.dart` | 신규 | 아코디언 필름 스택 헤더 |
| `lib/features/home/presentation/widgets/out_of_service/region_detail_panel.dart` | 신규 | 로딩/에러/빈값/본문 분기 + 소개·해시태그 |
| `lib/features/home/presentation/widgets/out_of_service/region_carousel.dart` | 신규 | 장소 이미지 PageView + n/total 뱃지 |
| `lib/features/home/presentation/widgets/out_of_service/recommended_course_banner.dart` | 신규 | 추천 채록길 CTA 배너 |
| `lib/features/home/presentation/widgets/out_of_service/region_place_strip.dart` | 신규 | "이런 장소를 만나보세요" 가로 목록 + 카드 |
| `lib/features/home/presentation/home_dashboard_screen.dart` | 수정 | outcome 분기, `_isOutOfService`, `onExploreRegionRequested` 파라미터, build 분기 |
| `lib/features/explore/presentation/explore_screen.dart` | 수정 | `ExploreScreenState.selectRegion(RegionCode)` 공개 메서드 |
| `lib/features/home/presentation/main_tab_screen.dart` | 수정 | 홈 → 채록길 탭 전환 + `selectRegion` 콜백 배선, `const` 제거 |

---

## 테스트

| 테스트 파일 | 내용 |
|---|---|
| `test/shared/region/region_guide_test.dart` | 모든 `RegionCode`에 guide 존재, 각 `hashtags.length == 3`, `romanized`/`tagline` 비어있지 않음 |
| `test/features/location/presentation/location_verification_outcome_test.dart` | `outOfServiceArea` 카드의 버튼 탭 시 `LocationOutOfService`가 pop 되는지 (위젯 테스트) |
| `test/features/home/presentation/out_of_service_home_view_test.dart` | 주입한 `regionIdResolver`/`placesFetcher` 스텁으로: ① 기본 선택이 예산, ② 서산 헤더 탭 시 `_RegionIntro` 제목이 "서산"으로, ③ fetcher가 지연/throw/빈 리스트일 때 로딩·에러(다시 시도)·빈 값 UI 렌더, ④ 배너 탭 시 `onExploreRegionRequested(RegionCode.seosan)` 호출 |
| `test/features/home/presentation/home_dashboard_out_of_service_test.dart` | outcome이 `LocationOutOfService`일 때 `OutOfServiceHomeView`가 렌더되는지 (인증 화면은 스텁/우회) |

- 기존 `recommended_place_card` 관련 테스트가 있으면 공용화 후에도 통과하는지 확인.
- 마지막에 `flutter analyze` + `flutter test` 전체 통과.

---

## 리스크 / 유의 사항

1. **API 정적 호출과 테스트 seam** — `PlacesApi`/`RegionsApi`는 모두 static이고
   기존 화면들은 직접 호출한다. DI 프레임워크가 없으므로 `OutOfServiceHomeView`에
   `regionIdResolver` / `placesFetcher` 함수 파라미터(기본값 = 정적 호출)를 두어
   위젯 테스트에서 스텁한다. 다른 화면의 패턴은 바꾸지 않는다.
2. **정림사지체 36px 스타일** — `ChaerokTypography`에 없는 크기.
   `ChaerokTypography.displayMedium.copyWith(fontSize: 36, letterSpacing: -0.2,
   color: ChaerokColors.primaryDark)`로 처리하거나, 재사용성이 있다고 판단되면
   `displayLarge`급 정림사지체 토큰을 `chaerok_typography.dart`에 추가.
   (폰트 패밀리 상수는 `ChaerokTypography.jeongnimsajiFontFamily`.)
3. **스택형 필름 스프로킷 비주얼** — Figma는 겹쳐 쌓인 각진 필름 띠 + 스프로킷
   구멍(내부 그림자 있는 6px 사각형)이다. `Container` 테두리 + 작은 사각형 +
   약간의 음수 margin/`Transform`으로 **근사**하며 픽셀 단위 재현은 목표하지 않는다.
   에셋(필름 프레임 PNG/SVG)이 나오면 교체 가능하도록 헤더 위젯을 독립적으로 둔다.
4. **지역 소개 카피 출처** — 디자이너/백엔드 제공 텍스트가 없다. Figma에 노출된
   예산·서산 문구는 그대로 옮기고, 공주·부여는 이 문서의 초안 카피를 사용한다.
   추후 확정 카피가 오면 `region_guide.dart`만 수정.
5. **캐러셀/장소 목록 데이터 품질** — `getExternalPlaces`는 TourAPI 실시간
   결과라 이미지가 비어있는 항목이 섞인다. 캐러셀은 `firstImageUrl` 있는 것만
   필터링하고, 장소 카드 이미지는 `PlaceImage`의 placeholder로 폴백한다.
6. **`kDebugMode` 폴백과의 상호작용** — 디버그 빌드에서는 서비스 지역 외
   좌표도 공주시로 대체되어 `LocationVerified`로 끝난다. 즉 이 화면은 디버그
   빌드에서 자동으로는 보이지 않는다. 테스트는 위젯 단위로 outcome을 직접 주입해
   검증한다. (필요 시 QA용 진입점은 별도 이슈.)

---

## 범위 외

- 추천 채록길 전용(읽기 전용) 상세 화면 신설 — 이번엔 채록길 탭으로만 이동.
- 필름 프레임 이미지 에셋 도입, 캐러셀 자동 스크롤/인디케이터 애니메이션.
- 지역 소개·해시태그·이미지의 백엔드 API화.
- 충남 외 지역에서의 북마크/코스 만들기 등 쓰기 동작 (읽기 전용 유지).
- `outOfServiceArea` 외 다른 실패 스텝(권한 거부 등)의 UI 변경.
