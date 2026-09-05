# 충남 외 지역 홈 화면 구현 플랜 (이슈 #74)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 충청남도 외 지역 사용자가 홈 탭에서 공주·부여·서산·예산 4개 지역을 아코디언으로 전환하며 소개·해시태그·장소 이미지·추천 채록길 배너·장소 목록을 둘러볼 수 있게 한다.

**Architecture:** 위치 인증 화면이 `LocationVerificationOutcome`(sealed)를 반환하도록 바꾸고, "서비스 지역 외"면 `HomeDashboardScreen`이 대시보드 대신 `OutOfServiceHomeView`를 렌더한다. 이 뷰는 4개 지역을 지연 로드(`RegionsApi.resolveRegion` → `PlacesApi.getExternalPlaces`)해 지역별로 캐시하며, 추천 채록길 배너/전체보기는 `MainTabScreen`을 통해 채록길 탭으로 전환하고 해당 지역을 선택한다. 지역 소개 카피는 `region_guide.dart`에 하드코딩한다.

**Tech Stack:** Flutter (Dart), `flutter_test`. 상태관리 프레임워크 없음 — `StatefulWidget` + `setState`, 정적 API 클래스(`PlacesApi`/`RegionsApi`), 싱글턴 모듈. 디자인 토큰 `ChaerokColors`/`ChaerokTypography`/`ChaerokSpacing`/`ChaerokRadius`/`ChaerokShadows`.

**Spec:** [docs/superpowers/specs/2026-09-05-out-of-service-region-home-design.md](../specs/2026-09-05-out-of-service-region-home-design.md)

## Global Constraints

- **레이아웃 raw 숫자 금지** — 간격/반경은 `ChaerokSpacing`/`ChaerokRadius` 토큰 사용 (Figma 세부 수치 근사에 필요한 경우만 예외적으로 raw 허용, 주석 필수).
- **색상은 `ChaerokColors` 우선** — 토큰에 없는 Figma 색은 `Color(0x...)` 리터럴 + 주석.
- **정림사지체 폰트 패밀리** = `ChaerokTypography.jeongnimsajiFontFamily` (`'Jeongnimsaji'`). 36px 지역명 타이틀은 `fontWeight: FontWeight.w600` (pubspec의 `Jeongnimsaji-L` = weight 600).
- **API 호출은 주입 seam 경유** — `OutOfServiceHomeView`는 `regionIdResolver`/`placesFetcher` 파라미터(기본값 = 정적 호출)로만 API를 부른다. 다른 화면의 정적 호출 패턴은 바꾸지 않는다.
- **`LocationVerificationResult.sessionCache`는 이름/타입 유지** — `my_screen.dart`·`film_roll_sync_service.dart`가 직접 읽는다. "서비스 지역 외" 상태는 새 필드 `outOfServiceSessionCache`로 별도 관리.
- **지역 해시태그는 지역당 정확히 3개.** 예산/서산 카피는 Figma 그대로, 공주/부여는 스펙의 초안 카피 사용.
- 커밋 메시지 말미에 다음 줄을 붙인다:
  `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`
- 각 태스크 끝에서 `flutter analyze`가 새 경고 0, 관련 테스트 통과여야 한다.

---

## 파일 구조

### 신규

| 파일 | 책임 |
|---|---|
| `lib/shared/region/region_guide.dart` | 지역별 소개 카피(로마자·태그라인·해시태그) 하드코딩 테이블 + `RegionCode.guide` 확장 |
| `lib/features/home/presentation/widgets/place_image.dart` | 관광지 대표 사진 렌더(http→https 승격, 로딩/에러 폴백) + mood 기반 플레이스홀더. `recommended_place_card.dart`에서 이관·공개 |
| `lib/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart` | 충남 외 지역 홈 화면 컨테이너 — 선택 지역 상태, 지역별 로드/캐시, 필름 스트립 + 상세 패널 조립 |
| `lib/features/home/presentation/widgets/out_of_service/region_film_strip.dart` | 상단 4개 지역 아코디언 헤더(단일 선택) |
| `lib/features/home/presentation/widgets/out_of_service/region_detail_panel.dart` | 선택 지역 상세 — 로딩/에러/빈값 분기, 소개(`_RegionIntro`)·해시태그(`_HashtagRow`) + 하위 섹션 조립. `RegionLoadStatus` enum 정의 |
| `lib/features/home/presentation/widgets/out_of_service/region_carousel.dart` | 장소 이미지 `PageView` + `n/total` 뱃지 |
| `lib/features/home/presentation/widgets/out_of_service/recommended_course_banner.dart` | "OO 추천 채록길" CTA 배너 |
| `lib/features/home/presentation/widgets/out_of_service/region_place_strip.dart` | "OO에서 이런 장소를 만나보세요" 헤더 + 가로 장소 카드 목록 |
| `test/shared/region/region_guide_test.dart` | `RegionGuide` 테이블 완전성 |
| `test/features/location/presentation/location_verification_outcome_test.dart` | `outOfServiceArea` 버튼 → `LocationOutOfService` pop |
| `test/features/home/presentation/widgets/place_image_test.dart` | `PlaceImage` 폴백 스모크 |
| `test/features/home/presentation/widgets/region_film_strip_test.dart` | 아코디언 선택 콜백 |
| `test/features/home/presentation/widgets/region_detail_panel_test.dart` | 로딩/에러/빈값/본문 렌더 + 배너 탭 콜백 |
| `test/features/home/presentation/out_of_service_home_view_test.dart` | 기본 예산, 지역 전환, 주입 seam 동작 |
| `test/features/home/presentation/home_dashboard_out_of_service_test.dart` | 세션 캐시가 out-of-service면 `OutOfServiceHomeView` 렌더 |
| `test/features/explore/presentation/explore_select_region_test.dart` | `ExploreScreenState.selectRegion` |

### 수정

| 파일 | 변경 |
|---|---|
| `lib/features/location/data/location_verification_result.dart` | `LocationVerificationOutcome` sealed class + `LocationVerified`/`LocationOutOfService`, `static bool outOfServiceSessionCache = false;` 추가 |
| `lib/features/location/presentation/location_verification_screen.dart` | pop 타입을 `LocationVerificationOutcome`으로, 성공 시 `LocationVerified`, `outOfServiceArea` 버튼 → `outOfServiceSessionCache=true` + `LocationOutOfService` pop, 문구/라벨 수정 |
| `lib/features/home/presentation/widgets/recommended_place_card.dart` | 내부 `_PlaceImage`/`_PlaceImagePlaceholder`/`_SummerTownPainter` 제거, `place_image.dart`의 `PlaceImage` 사용 |
| `lib/features/home/presentation/home_dashboard_screen.dart` | `onExploreRegionRequested` 파라미터, `_isOutOfService` 상태, `_ensureLocationVerified` outcome 분기, `build`에서 분기 렌더 |
| `lib/features/explore/presentation/explore_screen.dart` | `ExploreScreenState.selectRegion(RegionCode)` 공개 메서드 |
| `lib/features/home/presentation/main_tab_screen.dart` | `HomeDashboardScreen`에 콜백 배선(홈→채록길 탭 전환 + `selectRegion`), `const` 제거 |

---

## Task 1: `RegionGuide` 데이터 테이블

**Files:**
- Create: `lib/shared/region/region_guide.dart`
- Test: `test/shared/region/region_guide_test.dart`

**Interfaces:**
- Consumes: `RegionCode` (`lib/shared/region/region_code.dart`) — enum `{ gongju, buyeo, seosan, yesan }`
- Produces:
  - `class RegionGuide { final String romanized; final String tagline; final List<String> hashtags; const RegionGuide({required this.romanized, required this.tagline, required this.hashtags}); }`
  - `const Map<RegionCode, RegionGuide> kRegionGuides`
  - `extension RegionGuideX on RegionCode { RegionGuide get guide; }`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/shared/region/region_guide_test.dart`:

```dart
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/region/region_guide.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('모든 RegionCode에 guide가 정의돼 있다', () {
    for (final region in RegionCode.values) {
      expect(kRegionGuides.containsKey(region), isTrue, reason: '$region 누락');
    }
  });

  test('각 guide는 해시태그 정확히 3개, 비어있지 않은 romanized/tagline', () {
    for (final region in RegionCode.values) {
      final guide = region.guide;
      expect(guide.hashtags.length, 3, reason: '$region 해시태그 개수');
      expect(guide.hashtags.every((t) => t.trim().isNotEmpty), isTrue);
      expect(guide.romanized.trim(), isNotEmpty);
      expect(guide.tagline.trim(), isNotEmpty);
    }
  });

  test('예산/서산 카피는 Figma 문구와 일치한다', () {
    expect(RegionCode.yesan.guide.tagline, '고즈넉한 사찰과 넓은 호수, 시장의 온기가 함께 있는 곳');
    expect(RegionCode.yesan.guide.hashtags, ['수덕사', '예당호', '예산시장']);
    expect(RegionCode.seosan.guide.tagline, '바다와 갯벌, 노을이 어우러진 느린 여행의 도시');
    expect(RegionCode.seosan.guide.hashtags, ['해미읍성', '간월도', '서산버드랜드']);
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/shared/region/region_guide_test.dart`
Expected: FAIL — `region_guide.dart` 없음 / `guide` 미정의

- [ ] **Step 3: 최소 구현**

`lib/shared/region/region_guide.dart`:

```dart
import 'package:chaerok/shared/region/region_code.dart';

/// 충남 외 지역 홈 화면의 지역 소개 카피. 디자이너/백엔드 소스가 없어
/// 클라이언트에 하드코딩한다. Figma에 노출된 예산·서산은 그대로,
/// 공주·부여는 초안 카피(추후 확정 시 이 파일만 수정).
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

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/shared/region/region_guide_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: analyze**

Run: `flutter analyze lib/shared/region/region_guide.dart test/shared/region/region_guide_test.dart`
Expected: No issues

- [ ] **Step 6: 커밋**

```bash
git add lib/shared/region/region_guide.dart test/shared/region/region_guide_test.dart
git commit -m "feat(region): 충남 외 지역 홈용 지역 소개 카피 테이블 추가

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 2: `LocationVerificationOutcome` + 위치 인증 화면 배선

**Files:**
- Modify: `lib/features/location/data/location_verification_result.dart`
- Modify: `lib/features/location/presentation/location_verification_screen.dart`
- Test: `test/features/location/presentation/location_verification_outcome_test.dart`

**Interfaces:**
- Consumes: 기존 `LocationVerificationResult`
- Produces:
  - `sealed class LocationVerificationOutcome { const LocationVerificationOutcome(); }`
  - `class LocationVerified extends LocationVerificationOutcome { const LocationVerified(this.result); final LocationVerificationResult result; }`
  - `class LocationOutOfService extends LocationVerificationOutcome { const LocationOutOfService(); }`
  - `LocationVerificationResult.outOfServiceSessionCache` (`static bool`, 기본 `false`)
  - `LocationVerificationScreen`은 `Navigator.pop`으로 `LocationVerificationOutcome?`를 반환 (성공→`LocationVerified`, 서비스 지역 외→`LocationOutOfService`, 뒤로가기→`null`)

- [ ] **Step 1: 실패하는 테스트 작성**

`test/features/location/presentation/location_verification_outcome_test.dart`:

```dart
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/features/location/presentation/location_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'outOfServiceArea 상태에서 "지역별로 둘러보기" 탭 시 LocationOutOfService를 pop 한다',
    (tester) async {
      LocationVerificationResult.outOfServiceSessionCache = false;
      LocationVerificationOutcome? popped;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () async {
                    popped = await Navigator.of(context)
                        .push<LocationVerificationOutcome>(
                          MaterialPageRoute(
                            builder: (_) => const LocationVerificationScreen(),
                          ),
                        );
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // idle 뷰에서 debugSetStep이 없으므로, 이 테스트는 outOfServiceArea 스텝을
      // 직접 렌더하는 헬퍼가 필요하다 → Step 3에서 @visibleForTesting 생성자 인자 추가.
      // 여기서는 그 인자로 스텝을 강제한다(Step 3 참고).
      expect(find.text('지역별로 둘러보기'), findsOneWidget);
      await tester.tap(find.text('지역별로 둘러보기'));
      await tester.pumpAndSettle();

      expect(popped, isA<LocationOutOfService>());
      expect(LocationVerificationResult.outOfServiceSessionCache, isTrue);
    },
  );
}
```

> 참고: `LocationVerificationScreen`은 기본 진입이 `_Step.idle`이라 테스트에서 실제
> 위치 흐름을 태우기 어렵다. Step 3에서 `@visibleForTesting` 초기 스텝 인자를 추가한다.

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/features/location/presentation/location_verification_outcome_test.dart`
Expected: FAIL — `LocationVerificationOutcome`/`outOfServiceSessionCache` 미정의, 초기 스텝 인자 없음

- [ ] **Step 3: 구현**

**`lib/features/location/data/location_verification_result.dart`** — 파일 하단에 추가:

```dart
/// 위치 인증 화면의 종료 결과.
sealed class LocationVerificationOutcome {
  const LocationVerificationOutcome();
}

/// 인증 성공 — 서비스 지역(충남) 내부.
class LocationVerified extends LocationVerificationOutcome {
  const LocationVerified(this.result);
  final LocationVerificationResult result;
}

/// 서비스 지역 외 — 지역별 둘러보기(충남 외 지역 홈)로 진입한다.
/// 시·도 판별 단계에서 끊기므로 regionId 등 payload는 없다.
class LocationOutOfService extends LocationVerificationOutcome {
  const LocationOutOfService();
}
```

그리고 `class LocationVerificationResult` 안에 정적 필드 추가 (`sessionCache` 아래):

```dart
  /// 이번 세션에서 위치 인증이 "서비스 지역 외"로 끝났는지 여부.
  /// 홈 탭 재진입 시 인증 흐름을 다시 타지 않기 위한 캐시.
  static bool outOfServiceSessionCache = false;
```

**`lib/features/location/presentation/location_verification_screen.dart`**:

1. 위젯에 테스트용 초기 스텝 인자 추가:

```dart
class LocationVerificationScreen extends StatefulWidget {
  const LocationVerificationScreen({super.key, @visibleForTesting this.debugInitialOutOfServiceArea = false});

  /// 테스트에서 outOfServiceArea 스텝을 바로 렌더하기 위한 플래그.
  @visibleForTesting
  final bool debugInitialOutOfServiceArea;
```

(`import 'package:flutter/foundation.dart';`는 이미 있음.)

2. `_LocationVerificationScreenState.initState`에서:

```dart
  @override
  void initState() {
    super.initState();
    if (widget.debugInitialOutOfServiceArea) {
      _step = _Step.outOfServiceArea;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _mapEnabled = true);
    });
    unawaited(_loadPreviewPosition());
  }
```

3. `_run()` 성공 pop 변경 ([location_verification_screen.dart:220](../../../lib/features/location/presentation/location_verification_screen.dart#L220) 부근):

```dart
      LocationVerificationResult.sessionCache = result;
      Navigator.of(context).pop(LocationVerified(result));
```

같은 함수 상단의 세션 캐시 재사용부([:116-121](../../../lib/features/location/presentation/location_verification_screen.dart#L116)):

```dart
    final cached = LocationVerificationResult.sessionCache;
    if (cached != null) {
      log('세션 캐시된 위치 인증 결과 재사용', name: _tag);
      if (!mounted) return;
      Navigator.of(context).pop(LocationVerified(cached));
      return;
    }
```

4. 두 곳의 `setState(() => _step = _Step.outOfServiceArea);`
   ([:174](../../../lib/features/location/presentation/location_verification_screen.dart#L174),
   [:206](../../../lib/features/location/presentation/location_verification_screen.dart#L206)) 직전에
   `LocationVerificationResult.outOfServiceSessionCache = true;` 추가. (`:174`는
   `if (isOutOfServiceArea && !useDebugFallbackRegion)` 블록 안.)

5. `_buildContent()`의 `_Step.outOfServiceArea` 케이스 문구/버튼 교체:

```dart
      _Step.outOfServiceArea => _buildInfoCard(
        title: '서비스 지역이 아니에요',
        description:
            '채록의 필름롤은 현재 충청남도 지역에서만 시작할 수 있어요.\n'
            '대신 공주·부여·서산·예산을 지역별로 둘러볼 수 있어요.',
        buttonText: '지역별로 둘러보기',
        onPressed: () =>
            Navigator.of(context).pop(const LocationOutOfService()),
      ),
```

6. 클래스 문서 주석([:48](../../../lib/features/location/presentation/location_verification_screen.dart#L48))의
   "성공 시 [LocationVerificationResult]를 반환" → "종료 시 [LocationVerificationOutcome]를 반환"으로 수정.

- [ ] **Step 4: 테스트 통과 확인**

`location_verification_outcome_test.dart`의 push 호출에 `debugInitialOutOfServiceArea: true`를 넘기도록 테스트를 마무리한다:

```dart
builder: (_) => const LocationVerificationScreen(debugInitialOutOfServiceArea: true),
```

Run: `flutter test test/features/location/presentation/location_verification_outcome_test.dart`
Expected: PASS

- [ ] **Step 5: 회귀 확인**

Run: `flutter test test/features/auth/presentation/signup_navigation_test.dart`
Expected: PASS (signup 흐름은 pop 값을 무시하므로 영향 없음)

Run: `flutter analyze lib/features/location`
Expected: No issues

- [ ] **Step 6: 커밋**

```bash
git add lib/features/location test/features/location/presentation/location_verification_outcome_test.dart
git commit -m "feat(location): 위치 인증 결과를 LocationVerificationOutcome로 반환

서비스 지역 외 판정 시 LocationOutOfService를 pop하고 세션 캐시에 기록해
홈 탭이 지역별 둘러보기 화면으로 분기할 수 있게 한다.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 3: 공용 `PlaceImage` 추출

**Files:**
- Create: `lib/features/home/presentation/widgets/place_image.dart`
- Modify: `lib/features/home/presentation/widgets/recommended_place_card.dart`
- Test: `test/features/home/presentation/widgets/place_image_test.dart`

**Interfaces:**
- Consumes: `PlacePlaceholderMood` (`lib/features/home/presentation/models/home_card_data.dart`) — enum `{ stream, wall, forest }`
- Produces:
  - `class PlaceImage extends StatelessWidget { const PlaceImage({super.key, required this.imageUrl, required this.mood}); final String? imageUrl; final PlacePlaceholderMood mood; }`
  - `class PlaceImagePlaceholder extends StatelessWidget { const PlaceImagePlaceholder({super.key, required this.mood}); final PlacePlaceholderMood mood; }`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/features/home/presentation/widgets/place_image_test.dart`:

```dart
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/place_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('imageUrl이 null이면 PlaceImagePlaceholder를 그린다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: PlaceImage(imageUrl: null, mood: PlacePlaceholderMood.forest),
          ),
        ),
      ),
    );

    expect(find.byType(PlaceImagePlaceholder), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('imageUrl이 빈 문자열이어도 플레이스홀더로 폴백한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: PlaceImage(imageUrl: '  ', mood: PlacePlaceholderMood.wall),
          ),
        ),
      ),
    );

    expect(find.byType(PlaceImagePlaceholder), findsOneWidget);
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/features/home/presentation/widgets/place_image_test.dart`
Expected: FAIL — `place_image.dart` 없음

- [ ] **Step 3: 구현**

`lib/features/home/presentation/widgets/place_image.dart` 생성 — `recommended_place_card.dart`의
현재 private `_PlaceImage`(라인 203-253), `_PlaceImagePlaceholder`(255-268),
`_SummerTownPainter`(270-411)를 그대로 옮기고 이름에서 밑줄 제거:

```dart
import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:flutter/material.dart';

/// 관광지 대표 사진을 채워 넣되, URL이 없거나 로딩에 실패하면
/// [mood] 기반 일러스트([PlaceImagePlaceholder])로 폴백한다.
class PlaceImage extends StatelessWidget {
  const PlaceImage({super.key, required this.imageUrl, required this.mood});

  final String? imageUrl;
  final PlacePlaceholderMood mood;

  /// TourAPI가 내려주는 `http://tong.visitkorea.or.kr/...` 는 cleartext라
  /// Android 9+ 기본 설정에서 차단된다. 동일 호스트가 https도 제공하므로
  /// 스킴을 올려서 로드한다. 빈 문자열/null 은 null 로 정규화한다.
  static String? _normalized(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://')) {
      return 'https://${trimmed.substring('http://'.length)}';
    }
    return trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = PlaceImagePlaceholder(mood: mood);
    final url = _normalized(imageUrl);
    if (url == null) return placeholder;

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      semanticLabel: '관광지 대표 사진',
      errorBuilder: (context, error, stackTrace) => placeholder,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const ColoredBox(
          color: ChaerokColors.sageLight,
          child: Center(
            child: SizedBox(
              width: ChaerokSpacing.lg,
              height: ChaerokSpacing.lg,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ChaerokColors.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}

class PlaceImagePlaceholder extends StatelessWidget {
  const PlaceImagePlaceholder({super.key, required this.mood});

  final PlacePlaceholderMood mood;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '여행 사진이 들어갈 자리',
      image: true,
      child: CustomPaint(painter: _SummerTownPainter(mood)),
    );
  }
}

// _SummerTownPainter 전체를 recommended_place_card.dart에서 그대로 이동.
```

> `_SummerTownPainter`는 이미 `ChaerokRadius.sm`를 쓰므로 위 import에 포함. 클래스
> 본문은 원본을 축자 이동(수정 없음).

`lib/features/home/presentation/widgets/recommended_place_card.dart` 수정:
- 위 3개 클래스 제거.
- `import 'package:chaerok/features/home/presentation/widgets/place_image.dart';` 추가.
- `_buildFeatured`/`_buildCompact` 내부의 `_PlaceImage(...)` → `PlaceImage(...)`.
- 이제 안 쓰는 import 정리(`dart:ui`의 `FontFeature` 등은 원래 없음 — `chaerok_radius`가
  카드 본문에서 계속 쓰이면 유지, 아니면 `flutter analyze`가 unused를 알려줌).

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/features/home/presentation/widgets/place_image_test.dart`
Expected: PASS

- [ ] **Step 5: 회귀 + analyze**

Run: `flutter analyze lib/features/home/presentation/widgets/place_image.dart lib/features/home/presentation/widgets/recommended_place_card.dart`
Expected: No issues (unused import 경고 시 제거)

Run: `flutter test test/features/home`
Expected: PASS (기존 `nearby_place_recorder_test.dart` 포함)

- [ ] **Step 6: 커밋**

```bash
git add lib/features/home/presentation/widgets/place_image.dart lib/features/home/presentation/widgets/recommended_place_card.dart test/features/home/presentation/widgets/place_image_test.dart
git commit -m "refactor(home): 관광지 이미지 위젯을 place_image.dart로 공용화

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 4: `RegionFilmStrip` 아코디언

**Files:**
- Create: `lib/features/home/presentation/widgets/out_of_service/region_film_strip.dart`
- Test: `test/features/home/presentation/widgets/region_film_strip_test.dart`

**Interfaces:**
- Consumes: `RegionCode`, `RegionCodeX.displayName` (`lib/shared/region/region_code.dart`)
- Produces:
  - `class RegionFilmStrip extends StatelessWidget { const RegionFilmStrip({super.key, required this.selected, required this.onSelect}); final RegionCode selected; final ValueChanged<RegionCode> onSelect; }`
  - 헤더 순서는 항상 `RegionCode.values` (gongju, buyeo, seosan, yesan)

- [ ] **Step 1: 실패하는 테스트 작성**

`test/features/home/presentation/widgets/region_film_strip_test.dart`:

```dart
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_strip.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required RegionCode selected, required ValueChanged<RegionCode> onSelect}) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegionFilmStrip(selected: selected, onSelect: onSelect),
        ),
      ),
    );
  }

  testWidgets('4개 지역 필름롤 라벨을 모두 표시한다', (tester) async {
    await pump(tester, selected: RegionCode.yesan, onSelect: (_) {});
    expect(find.text('공주 필름롤'), findsOneWidget);
    expect(find.text('부여 필름롤'), findsOneWidget);
    expect(find.text('서산 필름롤'), findsOneWidget);
    expect(find.text('예산 필름롤'), findsOneWidget);
  });

  testWidgets('접힌 헤더를 탭하면 onSelect가 호출된다', (tester) async {
    RegionCode? tapped;
    await pump(tester, selected: RegionCode.yesan, onSelect: (r) => tapped = r);
    await tester.tap(find.text('서산 필름롤'));
    expect(tapped, RegionCode.seosan);
  });

  testWidgets('이미 선택된 헤더 탭도 onSelect를 호출한다(부모가 no-op 판단)', (tester) async {
    RegionCode? tapped;
    await pump(tester, selected: RegionCode.yesan, onSelect: (r) => tapped = r);
    await tester.tap(find.text('예산 필름롤'));
    expect(tapped, RegionCode.yesan);
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/features/home/presentation/widgets/region_film_strip_test.dart`
Expected: FAIL — `region_film_strip.dart` 없음

- [ ] **Step 3: 구현**

`lib/features/home/presentation/widgets/out_of_service/region_film_strip.dart`:

```dart
import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';

/// 충남 외 지역 홈 상단의 "필름롤" 아코디언. 4개 지역 헤더를 필름 스트립처럼
/// 살짝 겹쳐 쌓고, 접힌 헤더를 탭하면 [onSelect]로 전환을 요청한다.
/// 상세 패널은 이 위젯이 아니라 부모가 그린다.
class RegionFilmStrip extends StatelessWidget {
  const RegionFilmStrip({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final RegionCode selected;
  final ValueChanged<RegionCode> onSelect;

  /// 겹쳐 쌓이는 느낌을 주는 헤더 간 음수 오버랩(Figma 근사). 토큰이 없어 raw 사용.
  static const double _overlap = 8;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, region) in RegionCode.values.indexed)
          Padding(
            padding: EdgeInsets.only(top: index == 0 ? 0 : -_overlap < 0 ? 0 : 0),
            child: Transform.translate(
              offset: Offset(0, index == 0 ? 0 : -_overlap * index),
              child: _FilmRollHeader(
                label: region.filmRollTitle,
                isSelected: region == selected,
                onTap: () => onSelect(region),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilmRollHeader extends StatelessWidget {
  const _FilmRollHeader({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? ChaerokColors.primaryDark
              : ChaerokColors.primaryDark.withValues(alpha: 0.72),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(ChaerokRadius.lg),
            topRight: Radius.circular(ChaerokRadius.lg),
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: ChaerokTypography.jeongnimsajiFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
            ),
            const _SprocketHoles(),
          ],
        ),
      ),
    );
  }
}

/// 필름 스트립의 스프로킷 구멍 3개(Figma 근사).
class _SprocketHoles extends StatelessWidget {
  const _SprocketHoles();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        3,
        (_) => Container(
          margin: const EdgeInsets.only(left: ChaerokSpacing.xxs),
          width: 6, // Figma 6px 스프로킷. 토큰 없음.
          height: 6,
          decoration: BoxDecoration(
            color: ChaerokColors.background,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}
```

> `Padding`의 `top` 계산이 지저분하다 — 실제로는 `Transform.translate`만으로 겹침을
> 처리하므로 `Padding` 래퍼를 빼고 `Transform.translate`만 남겨도 된다. 구현자는
> 아래로 단순화할 것:
> ```dart
> for (final (index, region) in RegionCode.values.indexed)
>   Transform.translate(
>     offset: Offset(0, index == 0 ? 0 : -RegionFilmStrip._overlap * index),
>     child: _FilmRollHeader(...),
>   ),
> ```

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/features/home/presentation/widgets/region_film_strip_test.dart`
Expected: PASS (3 tests)

- [ ] **Step 5: analyze**

Run: `flutter analyze lib/features/home/presentation/widgets/out_of_service/region_film_strip.dart`
Expected: No issues

- [ ] **Step 6: 커밋**

```bash
git add lib/features/home/presentation/widgets/out_of_service/region_film_strip.dart test/features/home/presentation/widgets/region_film_strip_test.dart
git commit -m "feat(home): 충남 외 지역 홈 상단 필름롤 아코디언 위젯

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 5: 하위 섹션 위젯 — 캐러셀 / 배너 / 장소 스트립

**Files:**
- Create: `lib/features/home/presentation/widgets/out_of_service/region_carousel.dart`
- Create: `lib/features/home/presentation/widgets/out_of_service/recommended_course_banner.dart`
- Create: `lib/features/home/presentation/widgets/out_of_service/region_place_strip.dart`
- Test: `test/features/home/presentation/widgets/region_detail_panel_test.dart` (섹션 위젯을 여기서 함께 검증; 패널은 Task 6에서 추가)

**Interfaces:**
- Consumes: `PlaceListResponse` (`lib/data/models/place_list_response.dart` — `title`, `categoryDetail`, `firstImageUrl`), `PlaceImage`/`PlaceImagePlaceholder` (Task 3), `PlacePlaceholderMood`, `RegionCode`/`RegionCodeX.displayName`
- Produces:
  - `class RegionCarousel extends StatefulWidget { const RegionCarousel({super.key, required this.places}); final List<PlaceListResponse> places; }`
  - `class RecommendedCourseBanner extends StatelessWidget { const RecommendedCourseBanner({super.key, required this.region, required this.onTap}); final RegionCode region; final VoidCallback onTap; }`
  - `class RegionPlaceStrip extends StatelessWidget { const RegionPlaceStrip({super.key, required this.region, required this.places, required this.onSeeAll}); final RegionCode region; final List<PlaceListResponse> places; final VoidCallback onSeeAll; }`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/features/home/presentation/widgets/region_detail_panel_test.dart` (섹션 위젯 부분만 우선):

```dart
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/recommended_course_banner.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_carousel.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_place_strip.dart';
import 'package:chaerok/features/home/presentation/widgets/place_image.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PlaceListResponse _place(String title, {String? image}) => PlaceListResponse(
      id: title.hashCode,
      title: title,
      address: '충남 어딘가',
      latitude: 36.0,
      longitude: 126.0,
      categoryGroup: 'AT4',
      categoryDetail: '관광지',
      isRepresentative: false,
      source: 'TOUR_API',
      firstImageUrl: image,
    );

void main() {
  testWidgets('RegionCarousel: 이미지 없는 장소만 있으면 플레이스홀더 1장 + 1/1 뱃지', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegionCarousel(places: [_place('a'), _place('b')]),
        ),
      ),
    );
    expect(find.byType(PlaceImagePlaceholder), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('RegionCarousel: 이미지 있는 장소는 최대 5장까지 페이지', (tester) async {
    final places = [
      for (var i = 0; i < 7; i++) _place('p$i', image: 'http://x/$i.jpg'),
    ];
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: RegionCarousel(places: places))),
    );
    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('RecommendedCourseBanner: 지역명 문구 + 탭 콜백', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecommendedCourseBanner(
            region: RegionCode.seosan,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('서산 추천 채록길'), findsOneWidget);
    expect(find.text('서산의 매력을 담은 코스를 확인해보세요'), findsOneWidget);
    await tester.tap(find.byType(RecommendedCourseBanner));
    expect(tapped, isTrue);
  });

  testWidgets('RegionPlaceStrip: 헤더 문구 + 전체보기 탭 + 카드 이름', (tester) async {
    var seeAll = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegionPlaceStrip(
            region: RegionCode.yesan,
            places: [_place('수덕사'), _place('예당호')],
            onSeeAll: () => seeAll = true,
          ),
        ),
      ),
    );
    expect(find.text('예산에서 이런 장소를 만나보세요'), findsOneWidget);
    expect(find.text('수덕사'), findsOneWidget);
    await tester.tap(find.text('전체보기'));
    expect(seeAll, isTrue);
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/features/home/presentation/widgets/region_detail_panel_test.dart`
Expected: FAIL — 3개 위젯 파일 없음

- [ ] **Step 3: 구현 — `region_carousel.dart`**

```dart
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/place_image.dart';
import 'package:flutter/material.dart';

/// 선택 지역 장소 이미지 캐러셀. firstImageUrl이 있는 장소를 최대 5개까지
/// 페이지로 보여주고, 하나도 없으면 mood 플레이스홀더 1장을 보여준다.
class RegionCarousel extends StatefulWidget {
  const RegionCarousel({super.key, required this.places});

  final List<PlaceListResponse> places;

  static const int maxPages = 5;
  static const double _height = 200;

  @override
  State<RegionCarousel> createState() => _RegionCarouselState();
}

class _RegionCarouselState extends State<RegionCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  List<PlaceListResponse> get _withImages => widget.places
      .where((p) => (p.firstImageUrl ?? '').trim().isNotEmpty)
      .take(RegionCarousel.maxPages)
      .toList();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _withImages;
    final pageCount = items.isEmpty ? 1 : items.length;
    const fallbackMood = PlacePlaceholderMood.forest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ChaerokRadius.lg),
        child: SizedBox(
          height: RegionCarousel._height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: pageCount,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  if (items.isEmpty) {
                    return const PlaceImagePlaceholder(mood: fallbackMood);
                  }
                  final place = items[i];
                  return PlaceImage(
                    imageUrl: place.firstImageUrl,
                    mood: PlacePlaceholderMood
                        .values[i % PlacePlaceholderMood.values.length],
                  );
                },
              ),
              Positioned(
                right: ChaerokSpacing.sm,
                bottom: ChaerokSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChaerokSpacing.xs,
                    vertical: 2, // Figma 뱃지 세로 패딩. 토큰 없음.
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(ChaerokRadius.sm),
                  ),
                  child: Text(
                    '${_index + 1}/$pageCount',
                    style: ChaerokTypography.caption.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 구현 — `recommended_course_banner.dart`**

```dart
import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';

/// "OO 추천 채록길" CTA 배너. 탭하면 채록길 탭으로 이동한다(부모가 처리).
class RecommendedCourseBanner extends StatelessWidget {
  const RecommendedCourseBanner({
    super.key,
    required this.region,
    required this.onTap,
  });

  final RegionCode region;
  final VoidCallback onTap;

  /// Figma 배너 배경(sage 계열). ChaerokColors에 없어 리터럴 사용.
  static const Color _bg = Color(0xFFEBEEE3);
  static const Color _title = Color(0xFF3C3F2F);

  @override
  Widget build(BuildContext context) {
    final name = region.displayName;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
      child: Material(
        color: _bg,
        borderRadius: BorderRadius.circular(ChaerokRadius.sm),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ChaerokRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ChaerokSpacing.md,
              vertical: ChaerokSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.map_outlined,
                    size: ChaerokSpacing.xl, color: ChaerokColors.primaryDark),
                const SizedBox(width: ChaerokSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$name 추천 채록길',
                          style: ChaerokTypography.caption.copyWith(
                            color: _title,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: ChaerokSpacing.xxs),
                      Text('$name의 매력을 담은 코스를 확인해보세요',
                          style: ChaerokTypography.caption.copyWith(
                            color: ChaerokColors.primaryDark,
                          )),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: ChaerokColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: 구현 — `region_place_strip.dart`**

```dart
import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/place_image.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';

/// "OO에서 이런 장소를 만나보세요" 헤더 + 가로 스크롤 장소 카드 목록.
/// 헤더의 "전체보기"와 카드 탭 모두 채록길 탭 이동을 요청한다(부모가 처리).
class RegionPlaceStrip extends StatelessWidget {
  const RegionPlaceStrip({
    super.key,
    required this.region,
    required this.places,
    required this.onSeeAll,
  });

  final RegionCode region;
  final List<PlaceListResponse> places;
  final VoidCallback onSeeAll;

  static const int _maxCards = 10;
  static const double _cardWidth = 121;
  static const double _imageHeight = 81;

  @override
  Widget build(BuildContext context) {
    final visible = places.take(_maxCards).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${region.displayName}에서 이런 장소를 만나보세요',
                  style: ChaerokTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              InkWell(
                onTap: onSeeAll,
                child: Row(
                  children: [
                    Text('전체보기',
                        style: ChaerokTypography.caption
                            .copyWith(color: ChaerokColors.textDisabled)),
                    const Icon(Icons.chevron_right_rounded,
                        size: ChaerokSpacing.sm,
                        color: ChaerokColors.textDisabled),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ChaerokSpacing.sm),
        SizedBox(
          height: 150, // 이미지 81 + 텍스트 2줄. Figma 근사, 토큰 없음.
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(width: ChaerokSpacing.sm),
            itemBuilder: (context, index) => _PlaceCard(
              place: visible[index],
              mood: PlacePlaceholderMood
                  .values[index % PlacePlaceholderMood.values.length],
              onTap: onSeeAll,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required this.place,
    required this.mood,
    required this.onTap,
  });

  final PlaceListResponse place;
  final PlacePlaceholderMood mood;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: RegionPlaceStrip._cardWidth,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(ChaerokRadius.lg),
                topRight: Radius.circular(ChaerokRadius.lg),
              ),
              child: SizedBox(
                height: RegionPlaceStrip._imageHeight,
                width: double.infinity,
                child: PlaceImage(imageUrl: place.firstImageUrl, mood: mood),
              ),
            ),
            const SizedBox(height: ChaerokSpacing.xxs),
            Row(
              children: [
                const Icon(Icons.place,
                    size: ChaerokSpacing.sm, color: ChaerokColors.primaryDark),
                const SizedBox(width: 2), // 아이콘-텍스트 최소 간격. 토큰 없음.
                Expanded(
                  child: Text(place.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ChaerokTypography.caption
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            Text(place.categoryDetail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ChaerokTypography.caption.copyWith(
                  color: ChaerokColors.textSecondary,
                  fontSize: 10, // Figma 8px 근사, 가독성 위해 10. 토큰 없음.
                )),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: 테스트 통과 확인**

Run: `flutter test test/features/home/presentation/widgets/region_detail_panel_test.dart`
Expected: PASS (4 tests)

- [ ] **Step 7: analyze**

Run: `flutter analyze lib/features/home/presentation/widgets/out_of_service`
Expected: No issues

- [ ] **Step 8: 커밋**

```bash
git add lib/features/home/presentation/widgets/out_of_service/region_carousel.dart lib/features/home/presentation/widgets/out_of_service/recommended_course_banner.dart lib/features/home/presentation/widgets/out_of_service/region_place_strip.dart test/features/home/presentation/widgets/region_detail_panel_test.dart
git commit -m "feat(home): 충남 외 지역 홈 하위 섹션 위젯(캐러셀/배너/장소 스트립)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 6: `RegionDetailPanel` — 상태 분기 + 소개/해시태그

**Files:**
- Create: `lib/features/home/presentation/widgets/out_of_service/region_detail_panel.dart`
- Test: `test/features/home/presentation/widgets/region_detail_panel_test.dart` (Task 5 파일에 추가)

**Interfaces:**
- Consumes: `RegionCode`/`RegionCodeX.displayName`, `RegionGuideX.guide` (Task 1), `RegionCarousel`/`RecommendedCourseBanner`/`RegionPlaceStrip` (Task 5), `PlaceListResponse`, `ChaerokLoadingIndicator` (`lib/shared/widgets/chaerok_loading_indicator.dart`)
- Produces:
  - `enum RegionLoadStatus { loading, ready, error }`
  - `class RegionDetailPanel extends StatelessWidget { const RegionDetailPanel({super.key, required this.region, required this.status, required this.places, required this.onRetry, required this.onExploreRegionRequested}); final RegionCode region; final RegionLoadStatus status; final List<PlaceListResponse> places; final VoidCallback onRetry; final ValueChanged<RegionCode> onExploreRegionRequested; }`

- [ ] **Step 1: 실패하는 테스트 작성** — Task 5 테스트 파일 `main()` 안에 추가:

```dart
  group('RegionDetailPanel', () {
    Widget host({
      required RegionLoadStatus status,
      List<PlaceListResponse> places = const [],
      VoidCallback? onRetry,
      ValueChanged<RegionCode>? onExplore,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: RegionDetailPanel(
            region: RegionCode.yesan,
            status: status,
            places: places,
            onRetry: onRetry ?? () {},
            onExploreRegionRequested: onExplore ?? (_) {},
          ),
        ),
      );
    }

    testWidgets('loading이면 인디케이터', (tester) async {
      await tester.pumpWidget(host(status: RegionLoadStatus.loading));
      expect(find.byType(ChaerokLoadingIndicator), findsOneWidget);
    });

    testWidgets('error이면 다시 시도 버튼, 탭 시 onRetry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        host(status: RegionLoadStatus.error, onRetry: () => retried = true),
      );
      await tester.tap(find.text('다시 시도'));
      expect(retried, isTrue);
    });

    testWidgets('ready + 빈 목록이면 안내 문구', (tester) async {
      await tester.pumpWidget(host(status: RegionLoadStatus.ready));
      expect(find.text('이 지역의 장소 정보가 없어요'), findsOneWidget);
    });

    testWidgets('ready + 목록이면 소개/해시태그/배너 렌더', (tester) async {
      await tester.pumpWidget(host(
        status: RegionLoadStatus.ready,
        places: [_place('수덕사', image: 'http://x/a.jpg')],
      ));
      expect(find.text('예산'), findsOneWidget); // 정림사지체 타이틀
      expect(find.text('Y E S A N'), findsOneWidget);
      expect(find.text('# 수덕사'), findsOneWidget);
      expect(find.text('# 예당호'), findsOneWidget);
      expect(find.text('# 예산시장'), findsOneWidget);
      expect(find.text('예산 추천 채록길'), findsOneWidget);
    });

    testWidgets('배너 탭 시 onExploreRegionRequested(region)', (tester) async {
      RegionCode? got;
      await tester.pumpWidget(host(
        status: RegionLoadStatus.ready,
        places: [_place('수덕사', image: 'http://x/a.jpg')],
        onExplore: (r) => got = r,
      ));
      await tester.tap(find.byType(RecommendedCourseBanner));
      expect(got, RegionCode.yesan);
    });
  });
```

`region_detail_panel.dart` import를 테스트 상단에 추가.

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/features/home/presentation/widgets/region_detail_panel_test.dart`
Expected: FAIL — `region_detail_panel.dart` 없음

- [ ] **Step 3: 구현**

`lib/features/home/presentation/widgets/out_of_service/region_detail_panel.dart`:

```dart
import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/recommended_course_banner.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_carousel.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_place_strip.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/region/region_guide.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';

enum RegionLoadStatus { loading, ready, error }

/// 선택 지역 상세 패널. 상태에 따라 로딩/에러/빈값/본문을 그린다.
class RegionDetailPanel extends StatelessWidget {
  const RegionDetailPanel({
    super.key,
    required this.region,
    required this.status,
    required this.places,
    required this.onRetry,
    required this.onExploreRegionRequested,
  });

  final RegionCode region;
  final RegionLoadStatus status;
  final List<PlaceListResponse> places;
  final VoidCallback onRetry;
  final ValueChanged<RegionCode> onExploreRegionRequested;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case RegionLoadStatus.loading:
        return const Center(child: ChaerokLoadingIndicator());
      case RegionLoadStatus.error:
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('장소 정보를 불러오지 못했어요',
                  style: ChaerokTypography.bodyMedium
                      .copyWith(color: ChaerokColors.textSecondary)),
              const SizedBox(height: ChaerokSpacing.sm),
              TextButton(onPressed: onRetry, child: const Text('다시 시도')),
            ],
          ),
        );
      case RegionLoadStatus.ready:
        if (places.isEmpty) {
          return Center(
            child: Text('이 지역의 장소 정보가 없어요',
                style: ChaerokTypography.bodyMedium),
          );
        }
        return _Body(
          region: region,
          places: places,
          onExploreRegionRequested: onExploreRegionRequested,
        );
    }
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.region,
    required this.places,
    required this.onExploreRegionRequested,
  });

  final RegionCode region;
  final List<PlaceListResponse> places;
  final ValueChanged<RegionCode> onExploreRegionRequested;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: ChaerokSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
            child: _RegionIntro(region: region),
          ),
          const SizedBox(height: ChaerokSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
            child: _HashtagRow(tags: region.guide.hashtags),
          ),
          const SizedBox(height: ChaerokSpacing.lg),
          RegionCarousel(places: places),
          const SizedBox(height: ChaerokSpacing.lg),
          RecommendedCourseBanner(
            region: region,
            onTap: () => onExploreRegionRequested(region),
          ),
          const SizedBox(height: ChaerokSpacing.xl),
          RegionPlaceStrip(
            region: region,
            places: places,
            onSeeAll: () => onExploreRegionRequested(region),
          ),
        ],
      ),
    );
  }
}

class _RegionIntro extends StatelessWidget {
  const _RegionIntro({required this.region});

  final RegionCode region;

  @override
  Widget build(BuildContext context) {
    final guide = region.guide;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          guide.romanized,
          style: ChaerokTypography.caption.copyWith(
            color: ChaerokColors.primaryDark,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: ChaerokSpacing.xxs),
        Text(
          region.displayName,
          style: const TextStyle(
            fontFamily: ChaerokTypography.jeongnimsajiFontFamily,
            fontWeight: FontWeight.w600, // pubspec Jeongnimsaji-L
            fontSize: 36, // Figma 36px 타이틀. 토큰 없음.
            color: ChaerokColors.primaryDark,
          ),
        ),
        const SizedBox(height: ChaerokSpacing.xxs),
        Text(
          guide.tagline,
          style: ChaerokTypography.bodyMedium
              .copyWith(color: ChaerokColors.textPrimary),
        ),
      ],
    );
  }
}

class _HashtagRow extends StatelessWidget {
  const _HashtagRow({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: ChaerokSpacing.xs,
      runSpacing: ChaerokSpacing.xs,
      children: [
        for (final tag in tags)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: ChaerokSpacing.xs,
              vertical: ChaerokSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: ChaerokColors.sageLight,
              borderRadius: BorderRadius.circular(ChaerokRadius.lg),
            ),
            child: Text(
              '# $tag',
              style: ChaerokTypography.bodyMedium
                  .copyWith(color: ChaerokColors.primaryDark),
            ),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/features/home/presentation/widgets/region_detail_panel_test.dart`
Expected: PASS (Task 5의 4개 + Task 6의 5개)

- [ ] **Step 5: analyze**

Run: `flutter analyze lib/features/home/presentation/widgets/out_of_service`
Expected: No issues

- [ ] **Step 6: 커밋**

```bash
git add lib/features/home/presentation/widgets/out_of_service/region_detail_panel.dart test/features/home/presentation/widgets/region_detail_panel_test.dart
git commit -m "feat(home): 충남 외 지역 홈 상세 패널(상태 분기 + 소개/해시태그)

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 7: `OutOfServiceHomeView` — 컨테이너 + 로드/캐시

**Files:**
- Create: `lib/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart`
- Test: `test/features/home/presentation/out_of_service_home_view_test.dart`

**Interfaces:**
- Consumes: `RegionFilmStrip` (Task 4), `RegionDetailPanel`/`RegionLoadStatus` (Task 6), `RegionCode`/`RegionCodeX.cityCountyName`, `PlaceListResponse`, `PlacesApi.getExternalPlaces` (`lib/data/remote/places_api.dart`), `RegionsApi.resolveRegion` + `ResolveRegionRequest` (`lib/data/remote/regions_api.dart`, `lib/data/models/resolve_region_request.dart`)
- Produces:
  - `typedef RegionIdResolver = Future<int> Function(RegionCode region);`
  - `typedef PlacesFetcher = Future<List<PlaceListResponse>> Function(int regionId);`
  - `Future<int> defaultRegionIdResolver(RegionCode region)` (top-level)
  - `class OutOfServiceHomeView extends StatefulWidget { const OutOfServiceHomeView({super.key, required this.onExploreRegionRequested, this.regionIdResolver = defaultRegionIdResolver, this.placesFetcher = PlacesApi.getExternalPlaces}); final ValueChanged<RegionCode> onExploreRegionRequested; final RegionIdResolver regionIdResolver; final PlacesFetcher placesFetcher; }`

- [ ] **Step 1: 실패하는 테스트 작성**

`test/features/home/presentation/out_of_service_home_view_test.dart`:

```dart
import 'dart:async';

import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_detail_panel.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PlaceListResponse _place(String title) => PlaceListResponse(
      id: title.hashCode,
      title: title,
      address: '충남',
      latitude: 36,
      longitude: 126,
      categoryGroup: 'AT4',
      categoryDetail: '관광지',
      isRepresentative: false,
      source: 'TOUR_API',
    );

void main() {
  Widget host({
    RegionIdResolver? resolver,
    PlacesFetcher? fetcher,
    ValueChanged<RegionCode>? onExplore,
  }) {
    return MaterialApp(
      home: OutOfServiceHomeView(
        onExploreRegionRequested: onExplore ?? (_) {},
        regionIdResolver: resolver ?? (region) async => region.index + 1,
        placesFetcher: fetcher ?? (regionId) async => [_place('장소$regionId')],
      ),
    );
  }

  testWidgets('기본 선택 지역은 예산이고, 로드되면 상세가 예산으로 렌더', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.text('예산'), findsOneWidget);
    expect(find.text('Y E S A N'), findsOneWidget);
  });

  testWidgets('서산 헤더 탭 시 상세가 서산으로 전환', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('서산 필름롤'));
    await tester.pumpAndSettle();
    expect(find.text('서산'), findsOneWidget);
    expect(find.text('S E O S A N'), findsOneWidget);
  });

  testWidgets('fetcher가 느리면 로딩 인디케이터', (tester) async {
    final completer = Completer<List<PlaceListResponse>>();
    await tester.pumpWidget(host(fetcher: (_) => completer.future));
    await tester.pump();
    expect(find.byType(ChaerokLoadingIndicator), findsOneWidget);
    completer.complete([_place('a')]);
    await tester.pumpAndSettle();
  });

  testWidgets('fetcher가 throw하면 에러 상태', (tester) async {
    await tester.pumpWidget(host(fetcher: (_) async => throw Exception('boom')));
    await tester.pumpAndSettle();
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('한 번 로드한 지역은 재방문 시 fetcher를 다시 부르지 않는다', (tester) async {
    final calls = <int>[];
    await tester.pumpWidget(host(fetcher: (id) async {
      calls.add(id);
      return [_place('a')];
    }));
    await tester.pumpAndSettle();
    await tester.tap(find.text('서산 필름롤'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('예산 필름롤'));
    await tester.pumpAndSettle();
    // 예산(4) 1회 + 서산(3) 1회 = 2회, 예산 재방문 시 추가 호출 없음
    expect(calls.length, 2);
  });

  testWidgets('배너/전체보기는 onExploreRegionRequested(선택지역) 호출', (tester) async {
    RegionCode? got;
    await tester.pumpWidget(host(onExplore: (r) => got = r));
    await tester.pumpAndSettle();
    await tester.tap(find.text('전체보기'));
    expect(got, RegionCode.yesan);
  });
}
```

- [ ] **Step 2: 테스트 실패 확인**

Run: `flutter test test/features/home/presentation/out_of_service_home_view_test.dart`
Expected: FAIL — `out_of_service_home_view.dart` 없음

- [ ] **Step 3: 구현**

`lib/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart`:

```dart
import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/data/models/resolve_region_request.dart';
import 'package:chaerok/data/remote/places_api.dart';
import 'package:chaerok/data/remote/regions_api.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_detail_panel.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_strip.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';

typedef RegionIdResolver = Future<int> Function(RegionCode region);
typedef PlacesFetcher = Future<List<PlaceListResponse>> Function(int regionId);

const _serviceProvinceName = '충청남도';

/// 기본 regionId 해석기: 백엔드에 (충청남도, 시/군)으로 지역 검증을 요청해
/// regionId를 얻는다. ExploreScreen._fetchPlaces와 동일 경로.
Future<int> defaultRegionIdResolver(RegionCode region) async {
  final resolved = await RegionsApi.resolveRegion(
    ResolveRegionRequest(
      provinceName: _serviceProvinceName,
      cityCountyName: region.cityCountyName,
    ),
  );
  return resolved.regionId;
}

/// 충청남도 외 지역 사용자에게 보여주는 홈 화면.
/// 상단 필름롤 아코디언으로 4개 지역을 전환하며 지역별 장소를 둘러본다.
class OutOfServiceHomeView extends StatefulWidget {
  const OutOfServiceHomeView({
    super.key,
    required this.onExploreRegionRequested,
    this.regionIdResolver = defaultRegionIdResolver,
    this.placesFetcher = PlacesApi.getExternalPlaces,
  });

  final ValueChanged<RegionCode> onExploreRegionRequested;
  final RegionIdResolver regionIdResolver;
  final PlacesFetcher placesFetcher;

  @override
  State<OutOfServiceHomeView> createState() => _OutOfServiceHomeViewState();
}

class _OutOfServiceHomeViewState extends State<OutOfServiceHomeView> {
  static const _tag = 'OutOfServiceHomeView';

  /// Figma 기본 노출 지역(15-521).
  RegionCode _selected = RegionCode.yesan;

  final Map<RegionCode, _RegionData> _cache = {};

  /// 지역 전환이 빠르게 반복돼도 늦게 도착한 응답이 최신 상태를 덮어쓰지
  /// 않도록, 지역별 최신 요청만 반영한다(기존 화면들과 동일 패턴).
  final Map<RegionCode, int> _tokens = {};

  @override
  void initState() {
    super.initState();
    unawaited(_ensureLoaded(_selected));
  }

  Future<void> _ensureLoaded(RegionCode region, {bool force = false}) async {
    final existing = _cache[region];
    if (!force &&
        existing != null &&
        existing.status == RegionLoadStatus.ready) {
      return;
    }

    final token = (_tokens[region] ?? 0) + 1;
    _tokens[region] = token;
    setState(() {
      _cache[region] = const _RegionData(status: RegionLoadStatus.loading);
    });

    try {
      final regionId =
          existing?.regionId ?? await widget.regionIdResolver(region);
      final places = await widget.placesFetcher(regionId);
      if (!mounted || _tokens[region] != token) return;
      setState(() {
        _cache[region] = _RegionData(
          status: RegionLoadStatus.ready,
          regionId: regionId,
          places: places,
        );
      });
    } catch (e, st) {
      log('지역 장소 로드 실패 ($region)', name: _tag, error: e, stackTrace: st);
      if (!mounted || _tokens[region] != token) return;
      setState(() {
        _cache[region] = _RegionData(
          status: RegionLoadStatus.error,
          regionId: existing?.regionId,
        );
      });
    }
  }

  void _onSelect(RegionCode region) {
    if (region == _selected) return;
    setState(() => _selected = region);
    unawaited(_ensureLoaded(region));
  }

  @override
  Widget build(BuildContext context) {
    final data = _cache[_selected] ??
        const _RegionData(status: RegionLoadStatus.loading);

    return Scaffold(
      backgroundColor: ChaerokColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RegionFilmStrip(selected: _selected, onSelect: _onSelect),
            Expanded(
              child: RegionDetailPanel(
                region: _selected,
                status: data.status,
                places: data.places,
                onRetry: () => _ensureLoaded(_selected, force: true),
                onExploreRegionRequested: widget.onExploreRegionRequested,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionData {
  const _RegionData({
    required this.status,
    this.regionId,
    this.places = const [],
  });

  final RegionLoadStatus status;
  final int? regionId;
  final List<PlaceListResponse> places;
}
```

- [ ] **Step 4: 테스트 통과 확인**

Run: `flutter test test/features/home/presentation/out_of_service_home_view_test.dart`
Expected: PASS (6 tests)

- [ ] **Step 5: analyze**

Run: `flutter analyze lib/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart`
Expected: No issues

- [ ] **Step 6: 커밋**

```bash
git add lib/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart test/features/home/presentation/out_of_service_home_view_test.dart
git commit -m "feat(home): OutOfServiceHomeView 컨테이너 + 지역별 지연 로드/캐시

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 8: 홈 대시보드 분기 + 채록길 탭 배선

**Files:**
- Modify: `lib/features/home/presentation/home_dashboard_screen.dart`
- Modify: `lib/features/explore/presentation/explore_screen.dart`
- Modify: `lib/features/home/presentation/main_tab_screen.dart`
- Test: `test/features/home/presentation/home_dashboard_out_of_service_test.dart`
- Test: `test/features/explore/presentation/explore_select_region_test.dart`

**Interfaces:**
- Consumes: `LocationVerificationOutcome`/`LocationVerified`/`LocationOutOfService`/`LocationVerificationResult.outOfServiceSessionCache` (Task 2), `OutOfServiceHomeView` (Task 7), `RegionCode`
- Produces:
  - `HomeDashboardScreen({ ..., this.onExploreRegionRequested })` — `final ValueChanged<RegionCode>? onExploreRegionRequested;`
  - `ExploreScreenState.selectRegion(RegionCode region)` — 공개 메서드

- [ ] **Step 1: 실패하는 테스트 작성 — explore**

`test/features/explore/presentation/explore_select_region_test.dart`:

```dart
import 'package:chaerok/features/explore/presentation/explore_screen.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selectRegion은 예외 없이 호출되고 지역 셀렉터가 갱신된다', (tester) async {
    final key = GlobalKey<ExploreScreenState>();
    await tester.pumpWidget(MaterialApp(home: ExploreScreen(key: key)));
    await tester.pump(); // reevaluate/initState 비동기 1프레임

    key.currentState!.selectRegion(RegionCode.seosan);
    await tester.pump();

    // ChoiceChip('서산')이 선택 상태로 표시된다.
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '서산'),
    );
    expect(chip.selected, isTrue);
  });
}
```

> 이 테스트는 실제 API(`RegionsApi`/`PlacesApi`)를 태우지 않도록 `selectRegion`이
> 동기적으로 `_selectedRegion`만 먼저 바꾸고 `_fetchPlaces`는 뒤이어 비동기로
> 도는 구조여야 한다(아래 구현 참고). 네트워크는 테스트 환경에서 실패하지만
> `_fetchPlaces`가 그 실패를 `_errorMessage`로 흡수하므로 테스트는 통과한다.

- [ ] **Step 2: 실패 확인**

Run: `flutter test test/features/explore/presentation/explore_select_region_test.dart`
Expected: FAIL — `selectRegion` 미정의

- [ ] **Step 3: 구현 — explore_screen.dart**

`ExploreScreenState` 안, `_onRegionSelected` 아래에 추가:

```dart
  /// 홈(충남 외 지역 둘러보기)에서 특정 지역으로 채록길 탭에 진입할 때
  /// MainTabScreen이 GlobalKey로 호출한다.
  void selectRegion(RegionCode region) {
    if (!mounted || region == _selectedRegion) return;
    unawaited(_onRegionSelected(region));
  }
```

(`_onRegionSelected`는 이미 `setState`로 `_selectedRegion`을 먼저 바꾸고
`await _fetchPlaces()`를 호출하므로 셀렉터는 즉시 갱신된다.)

- [ ] **Step 4: 통과 확인 — explore**

Run: `flutter test test/features/explore/presentation/explore_select_region_test.dart`
Expected: PASS

- [ ] **Step 5: 실패하는 테스트 작성 — home dashboard**

`test/features/home/presentation/home_dashboard_out_of_service_test.dart`:

```dart
import 'package:chaerok/features/home/presentation/home_dashboard_screen.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    LocationVerificationResult.sessionCache = null;
    LocationVerificationResult.outOfServiceSessionCache = true; // 세션 캐시로 강제
  });

  tearDown(() {
    LocationVerificationResult.outOfServiceSessionCache = false;
  });

  testWidgets('세션 캐시가 out-of-service면 OutOfServiceHomeView를 렌더한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeDashboardScreen()),
    );
    await tester.pump(); // postFrameCallback
    await tester.pump();

    expect(find.byType(OutOfServiceHomeView), findsOneWidget);
  });
}
```

- [ ] **Step 6: 실패 확인 — home dashboard**

Run: `flutter test test/features/home/presentation/home_dashboard_out_of_service_test.dart`
Expected: FAIL — `_ensureLocationVerified`가 캐시를 안 보고 인증 화면을 push, `outOfServiceSessionCache` 미정의 컴파일 에러(Task 2 완료 전이면), `OutOfServiceHomeView` 미렌더

- [ ] **Step 7: 구현 — home_dashboard_screen.dart**

1. import 추가:

```dart
import 'package:chaerok/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart';
import 'package:chaerok/shared/region/region_code.dart';
```

2. 위젯에 콜백 파라미터:

```dart
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key, this.onExploreRegionRequested});

  /// 충남 외 지역 홈에서 "OO 추천 채록길"/"전체보기" 탭 시, 채록길 탭으로
  /// 전환하며 해당 지역을 선택하도록 MainTabScreen에 위임한다.
  final ValueChanged<RegionCode>? onExploreRegionRequested;
```

3. 상태 필드:

```dart
  bool _isOutOfService = false;
```

4. `_ensureLocationVerified()` 교체:

```dart
  Future<void> _ensureLocationVerified() async {
    final cached = LocationVerificationResult.sessionCache;
    if (cached != null) {
      setState(() => _locationResult = cached);
      unawaited(_onLocationVerified(cached));
      return;
    }
    if (LocationVerificationResult.outOfServiceSessionCache) {
      setState(() => _isOutOfService = true);
      return;
    }

    final outcome = await Navigator.of(context)
        .push<LocationVerificationOutcome>(
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
        break;
    }
  }
```

5. `build()` 최상단(기존 `const circleDiameter` 계산 전)에서 분기:

```dart
  @override
  Widget build(BuildContext context) {
    if (_isOutOfService) {
      return OutOfServiceHomeView(
        onExploreRegionRequested: (region) =>
            widget.onExploreRegionRequested?.call(region),
      );
    }
    // ... 기존 코드 그대로
```

- [ ] **Step 8: 구현 — main_tab_screen.dart**

`IndexedStack`의 `children` 첫 항목 교체:

```dart
        children: [
          HomeDashboardScreen(
            onExploreRegionRequested: (region) {
              setState(() => _selectedIndex = _exploreTabIndex);
              _exploreKey.currentState?.selectRegion(region);
            },
          ),
          ExploreScreen(key: _exploreKey),
          const FilmRollCollectionScreen(),
          const MyScreen(),
        ],
```

(`const HomeDashboardScreen()` → `HomeDashboardScreen(...)`, `const` 제거.)

- [ ] **Step 9: 통과 확인**

Run: `flutter test test/features/home/presentation/home_dashboard_out_of_service_test.dart`
Expected: PASS

Run: `flutter analyze lib/features/home lib/features/explore`
Expected: No issues

- [ ] **Step 10: 커밋**

```bash
git add lib/features/home/presentation/home_dashboard_screen.dart lib/features/home/presentation/main_tab_screen.dart lib/features/explore/presentation/explore_screen.dart test/features/home/presentation/home_dashboard_out_of_service_test.dart test/features/explore/presentation/explore_select_region_test.dart
git commit -m "feat(home): 서비스 지역 외 사용자에게 OutOfServiceHomeView 노출 + 채록길 탭 배선

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 9: 전체 회귀 + 마무리

**Files:** 없음 (검증 전용)

- [ ] **Step 1: 전체 테스트**

Run: `flutter test`
Expected: 전체 PASS. 실패 시 해당 태스크로 돌아가 수정.

- [ ] **Step 2: 전체 analyze**

Run: `flutter analyze`
Expected: 새로 생긴 이슈 0. (기존 베이스라인 경고가 있으면 이 작업으로 늘지 않았는지 확인.)

- [ ] **Step 3: 수동 스모크 (선택)**

`kDebugMode`에서는 서비스 지역 외 좌표가 공주시로 대체되어 이 화면이 자동으로는
보이지 않는다(스펙 리스크 6). 확인이 필요하면 임시로
`location_verification_screen.dart`의 `_debugFallbackProvinceName` 대체 로직을
잠시 건너뛰거나, `HomeDashboardScreen`를 `OutOfServiceHomeView`로 직접 띄우는
임시 진입점으로 육안 확인 후 되돌린다. (커밋하지 않는다.)

- [ ] **Step 4: 스펙 리스크 재확인**

스펙의 "리스크 / 유의 사항" 6개가 구현에서 어떻게 처리됐는지 1줄씩 점검:
정림사지체 36px(inline TextStyle 사용), 필름 스프로킷(근사 구현), 카피 출처
(`region_guide.dart` 하드코딩), 데이터 품질(`firstImageUrl` 필터 + placeholder
폴백), kDebugMode(테스트는 세션 캐시 주입으로 우회), 테스트 seam(주입 파라미터).

- [ ] **Step 5: 최종 커밋 (필요 시)**

정리 커밋이 있으면:

```bash
git add -A
git commit -m "chore(home): 충남 외 지역 홈 화면 마무리 정리

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Self-Review

**1. 스펙 커버리지**

| 스펙 항목 | 태스크 |
|---|---|
| `LocationVerificationOutcome` + `outOfServiceArea` 버튼/문구/캐시 | Task 2 |
| `region_guide.dart` 하드코딩 테이블 | Task 1 |
| 공용 `PlaceImage` 추출 | Task 3 |
| `OutOfServiceHomeView` 컨테이너 + 캐시 + 주입 seam | Task 7 |
| `_RegionFilmStrip` 아코디언 단일 선택 | Task 4 |
| 상세 패널 로딩/에러/빈값 + 소개/해시태그 | Task 6 |
| `_RegionCarousel` (PageView + n/total) | Task 5 |
| `_RecommendedCourseBanner` | Task 5 |
| `_RegionPlaceStrip` + 카드 | Task 5 |
| `ExploreScreenState.selectRegion` | Task 8 |
| `HomeDashboardScreen` 분기 + `onExploreRegionRequested` | Task 8 |
| `MainTabScreen` 콜백 배선 + `const` 제거 | Task 8 |
| 테스트 5종 + 회귀 | Task 1·2·3·4·5·6·7·8·9 |
| 범위 외(추천 코스 전용 화면, 필름 에셋, 백엔드 API화, 쓰기 동작) | 플랜에서 제외 확인 |

누락 없음. 스펙의 "배경 원(sageLight backdrop)"은 스펙에서 "필수 아님"으로 명시 →
플랜에서 의도적으로 제외(구현자 재량, Task 7 `Scaffold` 배경색만 적용).

**2. 플레이스홀더 스캔**

"TBD"/"TODO"/"적절히 처리" 없음. 모든 코드 스텝에 실제 코드 블록 포함.
Task 4 Step 3의 `Padding` 계산은 지저분하지만 바로 아래 단순화 코드를 제시함.

**3. 타입 일관성**

- `RegionLoadStatus` — Task 6에서 정의, Task 7에서 소비. 일치.
- `RegionIdResolver`/`PlacesFetcher`/`defaultRegionIdResolver` — Task 7에서 정의·사용. 일치.
- `OutOfServiceHomeView({required onExploreRegionRequested, regionIdResolver, placesFetcher})` — Task 7 정의, Task 8 사용 시 `onExploreRegionRequested`만 전달(나머지 기본값). 일치.
- `RegionFilmStrip({required selected, required onSelect})` — Task 4 정의, Task 7 사용. 일치.
- `RegionDetailPanel({region, status, places, onRetry, onExploreRegionRequested})` — Task 6 정의, Task 7 사용. 일치.
- `RegionCarousel({required places})` / `RecommendedCourseBanner({required region, required onTap})` / `RegionPlaceStrip({required region, required places, required onSeeAll})` — Task 5 정의, Task 6 사용. 일치.
- `PlaceImage({required imageUrl, required mood})` / `PlaceImagePlaceholder({required mood})` — Task 3 정의, Task 5 사용. 일치.
- `LocationVerified(result)` / `LocationOutOfService()` / `outOfServiceSessionCache` — Task 2 정의, Task 8 소비. 일치.
- `ExploreScreenState.selectRegion` — Task 8에서 정의·배선. 일치.
- `RegionCode.filmRollTitle`(Task 4), `RegionCode.displayName`(Task 5·6), `RegionCode.cityCountyName`(Task 7) — 모두 기존 `RegionCodeX`에 존재. 확인됨.

이슈 없음.
