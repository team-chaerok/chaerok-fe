# 충남 지역 홈 화면 카드 덱 구조 개편

**날짜:** 2026-09-14
**상태:** 초안
**이슈:** (미정)
**관련 문서:** [2026-09-05-out-of-service-region-home-design.md](./2026-09-05-out-of-service-region-home-design.md) — 이번 개편이 재사용하는 폴더 카드 덱의 원형

---

## 목표

충남(서비스 지역) 사용자의 홈 화면을, 이미 만들어진 **충남 외 지역 홈
(`OutOfServiceHomeView`)과 동일한 폴더 카드 덱 구조**로 개편한다. 단, 스택에
쌓이는 탭은 지역 4개가 아니라 다음 3개다.

1. **{현재여행지역}시** — 지금 위치 인증으로 확인된 지역(예: "공주시"). 지금의
   홈 대시보드 콘텐츠(날씨·필름롤 진행 상태·근처 채록 장소)가 여기로 들어간다.
2. **지난여행(필름롤 아카이브)** — 지금 헤더의 `FilmCollectionButton`이 열던
   `FilmRollCollectionScreen`에 해당하는 자리.
3. **마이페이지** — 지금 헤더의 `MyPageButton`이 열던 `MyScreen`에 해당하는 자리.

**이번 스코프는 구조만이다.** 각 카드를 열었을 때 실제로 보여줄 화면 구성은
사용자가 추후 별도로 지정하며, 여기서는 그 콘텐츠가 꽂힐 자리(카드 덱 메커니즘,
탭 모델, 상태 배선)만 만든다. "지난여행"/"마이페이지" 카드의 본문은 이번엔
placeholder로 둔다.

### 확정된 결정 (사용자 확인 완료)

- 세 탭 모두 카드를 열면 **그 카드 안에서 인라인으로** 내용을 보여준다. 지금처럼
  별도 화면으로 push하지 않는다.
- 홈 진입 시 기본으로 열려 있는 카드는 **현재여행지역 탭**이다.
- 폴더 카드 덱(쌓임/전환 애니메이션)은 `RegionCode` 전용 `RegionFilmDeck`을
  탭 타입 무관 **공통 컴포넌트로 일반화**해서 두 홈 화면이 공유한다.
- 탭으로 흡수되는 두 기능이 중복되므로, 홈 헤더 오른쪽 위의
  `FilmCollectionButton`/`MyPageButton` 아이콘은 **제거**한다.

### 현재 동작 (변경 전)

`HomeDashboardScreen.build()`가 `_isOutOfService == false`일 때 그리는 화면:

```
Scaffold
 └ Stack
    ├ 배경 원(sageLight, 593px circle)
    └ SingleChildScrollView
       └ Column
          ├ _HomeHeader(닉네임/오늘 날짜/지역명 + FilmCollectionButton + MyPageButton)
          ├ WeatherCard (날씨 조회 성공 시)
          ├ ActiveFilmRollCard (진행중 필름롤 있음) | 시작하기 카드 (없음)
          └ 가까운 채록 장소 섹션 (근처 장소 있음)
```

이 Column 전체가 그대로 "현재여행지역" 카드의 열린 본문이 된다(헤더의 아이콘
버튼 두 개만 제거).

---

## 컴포넌트 설계

### 1. 폴더 카드 덱 일반화

지금 `RegionFilmDeck`/`RegionFilmCard`는 `RegionCode`와 `PlaceListResponse` 목록에
강하게 결합돼 있다. 애니메이션·클리핑 로직 자체는 지역과 무관하므로, 탭 식별자
타입 `T`에 대한 제네릭 컴포넌트로 뽑아낸다.

**신규 `lib/features/home/presentation/widgets/folder_deck/folder_card_deck.dart`**

```dart
/// 폴더 탭 카드 스택 — [deckOrder]의 마지막 원소가 "열린" 카드이고 나머지는
/// 탭만 겹쳐 쌓인다. 지역별 홈(RegionCode)과 충남 홈(HomeCardTab)이 공유한다.
/// 카드 자체의 시각 요소는 [cardBuilder]에 위임한다.
class FolderCardDeck<T> extends StatefulWidget {
  const FolderCardDeck({
    required this.deckOrder,
    required this.cardBuilder, // Widget Function(T tab, bool opened)
    required this.onOpen,      // ValueChanged<T>
  });

  final List<T> deckOrder;
  final Widget Function(T tab, bool opened) cardBuilder;
  final ValueChanged<T> onOpen;
}
```

- 내부 구현은 `RegionFilmDeck`의 `_RegionFilmDeckState`를 그대로 옮기되, 필드
  타입만 `RegionCode` → `T`로 바꾸고 `_card()` 안에서 `RegionFilmCard(...)`를
  직접 생성하던 부분을 `widget.cardBuilder(tab, open)` 호출로 바꾼다. 스케일/틸트/
  스태거/스왑 애니메이션 상수와 로직은 변경하지 않는다(동작 동일).
- `T`는 `ValueKey<T>`와 `Map<T, ...>` 키로 쓰이므로 `==`/`hashCode`가 값
  기반이어야 한다 — `RegionCode`/`HomeCardTab` 모두 enum이라 문제 없음.
- `FolderCardDeck<T>`에 `static List<T> swapToFront<T>(List<T> order, T tab)`
  정적 메서드를 추가해, 겹친 탭을 눌렀을 때 "탭 지역과 열린 지역의 슬롯을
  맞바꾸는" 로직(`OutOfServiceHomeView._onOpenRegion`에 지금 인라인으로 있는
  것과 동일)을 양쪽 화면이 재사용한다. `_onOpenRegion`도 이 메서드를 쓰도록
  같이 정리한다.

**신규 `lib/features/home/presentation/widgets/folder_deck/folder_card.dart`**

```dart
/// 폴더 탭 카드 한 장의 틀(클리핑+그림자+탭 라벨+열림/닫힘 분기)만 담당하는
/// 범용 위젯. 색·라벨·본문은 전부 파라미터로 받는다.
class FolderCard extends StatelessWidget {
  const FolderCard({
    required this.color,
    required this.label,
    required this.opened,
    required this.closedPreview, // 닫혀 있을 때 탭 아래 오른쪽에 얹는 위젯
    required this.openedBody,    // 열렸을 때 탭 아래 전체를 채우는 위젯
  });

  final Color color;
  final String label;
  final bool opened;
  final Widget closedPreview;
  final Widget openedBody;
}
```

- `RegionFilmCard.build()`의 `CustomPaint(FolderCardShadowPainter) >
  ClipPath(FolderCardClipper) > Stack[ColoredBox, (opened body | closedPreview),
  탭 라벨 Text]` 구조를 그대로 옮기되, `region.filmTabColor`/`region.filmStripLabel`/
  `RegionDetailBody(...)`/`RegionFilmPhoto(...)` 참조를 파라미터로 교체한다.
- `FolderCardClipper`/`FolderCardShadowPainter`는 이미 지역 비의존적이라
  변경하지 않는다.

**기존 `region_film_card.dart` 리팩터**

`RegionFilmCard`는 이제 지역 전용 데이터(`RegionCode`/`RegionLoadStatus`/
`List<PlaceListResponse>`)를 받아 `FolderCard`에 필요한 `color`/`label`/
`closedPreview`/`openedBody`로 변환하는 **얇은 어댑터**가 된다. `RegionDetailBody`
클래스(로딩/에러/빈값/본문 분기)는 지금 그대로 두고 `openedBody`로 넘긴다.
동작·시각 변화 없음 — 순수 리팩터링.

**`OutOfServiceHomeView` 변경**

`RegionFilmDeck` 사용부를 `FolderCardDeck<RegionCode>`로 교체:

```dart
FolderCardDeck<RegionCode>(
  deckOrder: _deckOrder,
  onOpen: _onOpenRegion, // 내부에서 FolderCardDeck.swapToFront 사용
  cardBuilder: (region, opened) => RegionFilmCard(
    region: region,
    status: dataByRegion[region]?.status ?? RegionLoadStatus.loading,
    places: dataByRegion[region]?.places ?? const [],
    onRetry: () => onRetry(region),
    onExploreRegionRequested: onExploreRegionRequested,
    opened: opened,
  ),
)
```

동작·애니메이션·테스트는 변경되지 않아야 한다(순수 리팩터링 확인이 이번 작업의
회귀 방지 기준).

### 2. `HomeCardTab` — 충남 홈의 탭 모델

**신규 `lib/features/home/presentation/models/home_card_tab.dart`**

```dart
/// 충남(서비스 지역) 홈 카드 덱의 탭 3종.
enum HomeCardTab { region, filmArchive, myPage }

extension HomeCardTabX on HomeCardTab {
  /// 폴더 탭 배경색(placeholder). 라벨은 "현재여행지역"이 실제 지역명을
  /// 필요로 해 정적 extension에 두지 않고 조립 시점에 채운다(아래 참고).
  Color get color => switch (this) {
    HomeCardTab.region => ChaerokColors.primary,
    HomeCardTab.filmArchive => ChaerokColors.skyBlue,
    HomeCardTab.myPage => ChaerokColors.sageLight,
  };
}
```

> 색은 이번 단계의 placeholder다. 실제 화면 구성이 나오면 지역 카드처럼
> 전용 팔레트로 교체될 수 있다.

`region` 탭의 라벨(예: "공주 필름롤"이 아니라 실제 지역명 기반 문구)은 enum
확장이 아니라 `InServiceHomeCards`(아래 3번) 조립 시점에 `LocationVerificationResult`
에서 얻은 지역명으로 채운다 — `RegionCode.filmStripLabel`과 달리 동적 값이라
정적 extension에 둘 수 없다.

### 3. 충남 홈 조립 — `HomeDashboardScreen` 변경

새 위젯을 만들지 않고, **`HomeDashboardScreenState`가 상태를 계속 소유**한 채
`build()`의 서비스 지역 분기만 카드 덱으로 교체한다(위치 인증·날씨·필름롤 복구
등 기존 로직은 전혀 건드리지 않음).

```dart
// State에 추가
List<HomeCardTab> _deckOrder = const [
  HomeCardTab.filmArchive,
  HomeCardTab.myPage,
  HomeCardTab.region, // 마지막 = 기본으로 열린 카드
];

void _onOpenTab(HomeCardTab tab) {
  if (tab == _deckOrder.last) return;
  setState(() => _deckOrder = FolderCardDeck.swapToFront(_deckOrder, tab));
}
```

`build()`의 서비스 지역 분기:

```dart
return Scaffold(
  backgroundColor: ChaerokColors.background,
  body: SafeArea(
    child: FolderCardDeck<HomeCardTab>(
      deckOrder: _deckOrder,
      onOpen: _onOpenTab,
      cardBuilder: (tab, opened) => switch (tab) {
        HomeCardTab.region => FolderCard(
            color: HomeCardTab.region.color,
            label: _locationResult != null
                ? '${_locationResult!.region.cityCountyName} 필름롤'
                : '필름롤',
            opened: opened,
            closedPreview: const _TabPreviewPlaceholder(), // 지역 사진 등, 추후 교체
            openedBody: _RegionHomeBody(  // 지금 build()가 그리던 Column 그대로
              user: _user,
              locationResult: _locationResult,
              weather: _weather,
              recoveredFilmRoll: _recoveredFilmRoll,
              recentPhotoThumbnailPaths: _recentPhotoThumbnailPaths,
              nearbyPlaces: _nearbyPlaces,
              isAutoConnectingFilmRoll: _isAutoConnectingFilmRoll,
              isEnteringFilmRoll: _isEnteringFilmRoll,
              onResumeFilmRollTap: _onResumeFilmRollTap,
              onStartFilmRollTap: _onStartFilmRollTap,
            ),
          ),
        HomeCardTab.filmArchive => FolderCard(
            color: HomeCardTab.filmArchive.color,
            label: '지난여행',
            opened: opened,
            closedPreview: const _TabPreviewPlaceholder(),
            openedBody: const _PlaceholderCardBody(text: '지난여행 화면은 곧 만나볼 수 있어요'),
          ),
        HomeCardTab.myPage => FolderCard(
            color: HomeCardTab.myPage.color,
            label: '마이페이지',
            opened: opened,
            closedPreview: const _TabPreviewPlaceholder(),
            openedBody: const _PlaceholderCardBody(text: '마이페이지는 곧 만나볼 수 있어요'),
          ),
      },
    ),
  ),
);
```

- 배경 원(`sageLight` 593px circle)은 지금 `Stack`의 화면 전체 배경으로 그려지고
  있었는데, 카드 덱 구조에서는 열린 카드가 뷰포트를 채우므로 더 이상 보이는
  자리가 없다. **제거한다** (`OutOfServiceHomeView`도 배경 원 없이 같은 구조).
- `_HomeHeader`는 `_RegionHomeBody` 내부로 옮기되 `FilmCollectionButton`/
  `MyPageButton` 두 줄은 삭제한다.
- `_RegionHomeBody`는 지금 `build()`에 인라인으로 있던 헤더/날씨/필름롤 카드/근처
  장소 Column을 그대로 옮긴 `StatelessWidget`이다 — 로직 변경 없이 위치만 이동.
- `_PlaceholderCardBody`/`_TabPreviewPlaceholder`는 이번 스코프의 자리채우기용
  최소 위젯(가운데 정렬 텍스트 / 빈 색 블록)이며, 실제 화면 구성이 정해지면
  통째로 교체된다.

---

## 변경 / 신규 파일 목록

| 파일 | 유형 | 내용 |
|---|---|---|
| `lib/features/home/presentation/widgets/folder_deck/folder_card_deck.dart` | 신규 | `RegionFilmDeck`의 스택/전환 애니메이션을 `FolderCardDeck<T>`로 일반화, `swapToFront<T>` 헬퍼 |
| `lib/features/home/presentation/widgets/folder_deck/folder_card.dart` | 신규 | `RegionFilmCard`의 틀(클리핑+그림자+탭 라벨)을 `FolderCard`로 일반화 |
| `lib/features/home/presentation/widgets/out_of_service/region_film_deck.dart` | 삭제 | `FolderCardDeck<RegionCode>`로 대체 |
| `lib/features/home/presentation/widgets/out_of_service/region_film_card.dart` | 수정 | `FolderCard`를 감싸는 지역 전용 어댑터로 축소(색/라벨/본문만 계산) |
| `lib/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart` | 수정 | `RegionFilmDeck` → `FolderCardDeck<RegionCode>` 사용부 교체 |
| `lib/features/home/presentation/models/home_card_tab.dart` | 신규 | `HomeCardTab` enum + `color` extension |
| `lib/features/home/presentation/home_dashboard_screen.dart` | 수정 | 서비스 지역 분기를 `FolderCardDeck<HomeCardTab>` 조립으로 교체, 기존 Column을 `_RegionHomeBody`로 추출, 배경 원 제거, `_deckOrder`/`_onOpenTab` 상태 추가 |
| `lib/features/home/presentation/widgets/film_collection_button.dart` | 삭제 | 헤더에서 제거되어 더 이상 쓰이지 않음 |
| `lib/features/home/presentation/widgets/my_page_button.dart` | 삭제 | 헤더에서 제거되어 더 이상 쓰이지 않음 |

---

## 테스트

| 테스트 파일 | 내용 |
|---|---|
| `test/features/home/presentation/widgets/folder_deck/folder_card_deck_test.dart` | 제네릭 `String`/enum 탭으로 스택 순서·`onOpen` 콜백·`swapToFront` 헬퍼 단위 검증(기존 `region_film_card_test.dart`의 스택 관련 케이스를 여기로 이관) |
| `test/features/home/presentation/widgets/out_of_service/region_film_card_test.dart` | `RegionFilmCard`가 여전히 올바른 색/라벨/본문으로 `FolderCard`를 조립하는지(리팩터링 회귀 확인) |
| `test/features/home/presentation/home_dashboard_in_service_test.dart` | 서비스 지역 진입 시 기본으로 `region` 탭이 열려 있는지, 겹친 "지난여행"/"마이페이지" 탭을 탭하면 해당 카드가 열리는지(placeholder 텍스트 노출로 확인), 헤더에 `FilmCollectionButton`/`MyPageButton`이 더 이상 없는지 |

- 리팩터링 대상인 `OutOfServiceHomeView` 관련 기존 테스트(`out_of_service_home_view_test.dart` 등)가 수정 없이 통과해야 한다 — 통과하지 않으면 일반화 과정에서 동작이 바뀐 것이므로 원인을 먼저 규명한다.
- 마지막에 `flutter analyze` + `flutter test` 전체 통과.

---

## 리스크 / 유의 사항

1. **제네릭 전환의 회귀 위험** — `RegionFilmDeck`/`RegionFilmCard`는 이미
   프로토타입 확정치(애니메이션 상수)를 담고 있는 코드다. `FolderCardDeck<T>`/
   `FolderCard`로 일반화하면서 상수·분기 로직을 실수로 바꾸지 않도록, 기존
   `region_film_card_test.dart`/`region_film_deck` 관련 테스트를 리팩터링
   직후 우선 통과시켜 동작 동치를 확인한다.
2. **`region` 탭 라벨의 동적 값** — 다른 두 탭은 정적 라벨이지만 `region` 탭은
   `LocationVerificationResult`가 아직 없을 때(위치 인증 전) 지역명이 없다.
   이 경우 "필름롤" 같은 폴백 라벨을 쓴다(위 스니펫 참조).
3. **`_isOutOfService` 분기와의 관계** — 이번 개편은 `_isOutOfService == false`
   분기에만 영향을 준다. `_isOutOfService == true`일 때의 `OutOfServiceHomeView`
   경로는 내부 구현(덱 컴포넌트)만 공유하고 화면 전환 로직은 그대로다.
4. **placeholder 콘텐츠는 임시** — "지난여행"/"마이페이지" 탭의 실제 화면
   구성(기존 `FilmRollCollectionScreen`/`MyScreen`을 어떻게 카드 안에 넣을지,
   각자의 `Scaffold`/`AppBar`를 어떻게 제거·재구성할지 포함)은 사용자가 후속으로
   지정할 예정이며 이번 스펙의 범위가 아니다.
5. **배경 원 제거** — 현재 홈의 시각적 정체성 중 하나였던 `sageLight` 배경 원이
   이번 개편으로 사라진다. 카드 덱 구조에서 재도입할지는 실제 화면 구성 단계에서
   다시 판단한다.

---

## 범위 외

- "지난여행"/"마이페이지" 카드의 실제 화면 구성(디자인·데이터 연동) — 사용자가
  추후 별도로 지정.
- `region` 탭의 `closedPreview`(닫혔을 때 보이는 미리보기) 실제 디자인 —
  지역 카드의 `RegionFilmPhoto`에 대응하는 요소이나 이번엔 placeholder.
- 배경 원 등 비주얼 디테일 재설계.
- `FilmRollCollectionScreen`/`MyScreen`의 Scaffold/AppBar 분리(카드 임베딩을
  위한 리팩터링) — 후속 작업.
