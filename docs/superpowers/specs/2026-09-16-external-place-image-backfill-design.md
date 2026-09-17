# 외부(TourAPI/Kakao) 장소 대표 사진 보충 — 설계 문서

- 관련 버그: "충남 지역 홈" 필름롤 갤러리(`RegionPhotoGallery`)에서 미방문 장소가 일러스트
  플레이스홀더만 보이고 API 사진이 뜨지 않음
- 작성일: 2026-09-16

## 근본 원인

`BackfillPlaceImagesUseCase`(`lib/features/film_roll/domain/usecase/backfill_place_images_use_case.dart`)와
`SelectCourseUseCase._withImageIfAvailable`(`select_course_use_case.dart:64-73`) 둘 다, 장소의
대표 사진(`FilmRollPlace.imageUrl`)을 보충할 때 **`serverPlaceId`(백엔드 자체 Place DB에 존재)가
있는 장소만** 대상으로 한다. `CoursePlaceResponse.placeId`는 추천 코스 응답에서도 nullable이라,
실시간 TourAPI/Kakao로만 채워지는 장소(식당·카페에 흔함)는 흔히 `serverPlaceId`가 없다. 이런
장소는 코드 주석에 명시된 대로 "채울 방법이 없어 그대로" 두고 있어, `RegionPhotoGallery`가
`PlaceImage(imageUrl: previewPlace.imageUrl, ...)`로 API 사진을 시도해도 `imageUrl`이 계속
null이라 일러스트 폴백만 보인다.

`externalPlaceId`(TourAPI `tourContentId` 또는 Kakao `kakaoPlaceId`)는 코스 선택 시점부터
`FilmRollPlace`까지 끊김 없이 저장되고 있음을 확인했다(`select_course_use_case.dart` →
`film_roll_repository_impl.dart:175` → `film_roll_places_table.dart` → `film_roll_place_mapper.dart`).
즉 매칭에 쓸 식별자는 이미 있고, 그 식별자로 이미지를 가져오는 경로만 없다.

## 해결 방향

`PlacesApi.getExternalPlaces(regionId)`(이미 존재하는, TourAPI 기반으로 지역 장소를 실시간
조회하는 API — `PlaceListResponse` 목록을 반환하며 `tourContentId`/`kakaoPlaceId`/`firstImageUrl`을
포함)를 이용해 `BackfillPlaceImagesUseCase`를 확장한다.

1. `serverPlaceId`가 있는 장소는 기존 경로(`placeImageFetcher`, 장소 상세 API) 그대로 유지.
2. `serverPlaceId`가 없고 `externalPlaceId`가 있는 장소는, 같은 지역의 외부 장소 목록을
   **한 번만** 조회해 `tourContentId ?? kakaoPlaceId → firstImageUrl` 맵을 만들고, 그 맵에서
   자기 `externalPlaceId`에 해당하는 이미지를 채운다.
3. `regionId`를 모르면(예: 아직 서버와 동기화되지 않은 필름롤) 외부 장소 보충은 건너뛴다(기존
   서버-장소 보충 경로는 영향 없음).
4. 이미 이미지가 있는 장소는 그대로 두고(멱등), 실패한 장소가 있어도 나머지는 계속 보충한다
   (기존 정책 유지).

`SelectCourseUseCase._withImageIfAvailable`는 이번 범위에서 건드리지 않는다 — 코스 확정 시점엔
아직 `regionId` 조회 왕복을 늘리고 싶지 않고, 어차피 홈 진입 시 `BackfillPlaceImagesUseCase`가
한 번 더 보충하므로 이 경로 하나만 고쳐도 사용자에게 보이는 결과(갤러리 사진)는 동일하다.

## 변경 파일

- `lib/features/film_roll/domain/usecase/backfill_place_images_use_case.dart` —
  `call(filmRollId, {int? regionId})`로 시그니처 확장, 외부 장소 보충 분기 추가,
  `defaultExternalPlaceImageFetcher(regionId)` 신규 추가
- `lib/features/film_roll/film_roll_module.dart` — 변경 없음(기본 fetcher 그대로 사용)
- `lib/features/home/presentation/home_dashboard_screen.dart` — `_backfillPlaceImages` 호출부에
  `regionId: recovered.regionId` 전달

## 테스트 계획

- 기존 `test/features/film_roll/domain/usecase/backfill_place_images_use_case_test.dart`의
  "serverPlaceId가 있고 이미지가 없는 장소만 보충한다" 케이스는 `regionId`를 넘기지 않는
  시나리오로 유지(외부 보충 분기가 없어도 서버 분기는 그대로 동작해야 함).
- 신규 케이스: `regionId`를 넘기고 `externalPlaceImageFetcher`를 주입해, `serverPlaceId` 없이
  `externalPlaceId`만 있는 장소가 매핑된 이미지로 채워지는지 검증.
- 신규 케이스: `externalPlaceId`도 없는 장소(제목+주소로만 식별되는 완전 로컬 후보)는 여전히
  일러스트 폴백을 유지(보충 대상에서 제외)하는지 검증.
- 신규 케이스: `regionId`가 없으면 외부 장소 조회 자체를 시도하지 않는지 검증.

## 범위 밖

- `SelectCourseUseCase`의 즉시 보충 경로 확장(위 이유로 제외)
- 외부 장소 이미지 매핑 결과의 로컬 캐싱(현재도 `imageUrl`이 채워지면 재호출 안 하므로 별도
  캐싱 계층 불필요)
