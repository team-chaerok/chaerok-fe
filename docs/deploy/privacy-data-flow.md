# 위치 좌표 데이터 흐름

앱이 수집하는 위치 좌표가 **어디서 생겨서 어디로 가는지** 정리한다.
iOS `PrivacyInfo.xcprivacy`와 App Store / Google Play 개인정보 신고 값의 근거 문서다.

- 관련 이슈: [#82](https://github.com/team-chaerok/chaerok-fe/issues/82)
- 함께 보기: [store-privacy-checklist.md](store-privacy-checklist.md), [release-checklist.md](release-checklist.md)

---

## 1. 한눈에

- 앱은 `geolocator`로 **정밀 좌표**(전체 위·경도)를 수집한다. `LocationAccuracy.medium`은 배터리 절충일 뿐 좌표 정밀도 신고 등급은 **Precise**다.
- 원시 좌표가 **기기 밖으로 나가는 경로는 카카오 로컬 API 한 곳**이다.
- 기상청 API에는 좌표를 **격자(nx, ny)로 변환한 뒤** 보낸다(원시 좌표 자체는 미전송).
- **채록 자체 백엔드는 어떤 경로로도 원시 좌표를 받거나 저장하지 않는다.**
- 백그라운드 위치는 사용하지 않는다.

---

## 2. 수집 지점

| 지점 | 파일 | 내용 |
| --- | --- | --- |
| 좌표 조회 단일 진입점 | `lib/features/location/data/location_permission_service.dart` `getCurrentPosition()` | `Geolocator.getCurrentPosition(accuracy: medium, timeLimit: 30s)` |
| mock 좌표 분기 | 같은 파일 + `lib/core/location/mock_location_gate.dart` | 개발/QA 빌드 또는 테스트 계정 + 사용자가 켠 경우, 저장된 지점의 mock 좌표 반환 (이슈 #76) |
| iOS 권한 | `ios/Runner/Info.plist` `NSLocationWhenInUseUsageDescription` | "주변 장소 추천 등 위치 기반 서비스를 제공하기 위해 위치 권한이 필요합니다." |
| Android 권한 | `android/app/src/main/AndroidManifest.xml` | `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` |

---

## 3. 전송 대상

| 대상 | 호출 위치 | 전송하는 값 | 성격 |
| --- | --- | --- | --- |
| **카카오 로컬 API** `dapi.kakao.com` | `lib/features/location/data/kakao_local_api_service.dart` — `/v2/local/geo/coord2regioncode.json?x={경도}&y={위도}` | **원시 위·경도** | 제3자 전송 |
| **기상청 단기예보 API** `apis.data.go.kr` | `lib/features/home/data/weather_api_service.dart` + `kma_grid_converter.dart` | 위·경도를 **격자(nx, ny)로 변환 후** 전송. 원시 좌표 미전송 | 제3자 전송(좌표 파생값) |
| **채록 백엔드** `/api/regions/resolve` | `lib/data/remote/regions_api.dart`, `location_verification_runner.dart` | `provinceName`, `cityCountyName` **문자열만** | 좌표 미전송 |
| **채록 백엔드** `/api/film-rolls/{id}/visits` | `lib/data/remote/visits_api.dart` | `placeId`(+`photoId`)만. 코드 주석: "백엔드는 GPS 좌표, 정확도, 거리, 이동 경로를 받거나 저장하지 않는다" | 좌표 미전송 |
| **채록 백엔드** 사진 업로드 URL 발급 | `lib/data/models/photo_upload_url_request.dart` | `sequence`, `contentType`, `contentLength`, `takenAt`만 | 좌표 메타데이터 미전송 |
| **채록 S3** presigned PUT | `lib/features/film_roll/data/sync/film_roll_sync_service.dart` | **촬영 원본 JPEG 바이트 그대로**(재인코딩 없음) | EXIF에 GPS가 실릴 경우 간접 전송 → §5 |

### 인증 정보

- 카카오: REST API 키(`Authorization: KakaoAK ...`)만. 사용자 계정 식별자는 함께 보내지 않는다.
- 기상청: `serviceKey`만. 사용자 식별자 없음.
- 채록 백엔드: 로그인 토큰이 붙지만, 위 표대로 **좌표 자체를 보내지 않는다**.

---

## 4. 온디바이스 사용 (전송 없음)

| 용도 | 파일 |
| --- | --- |
| 현재 위치 ↔ 장소 거리 계산 | `lib/features/home/presentation/home_dashboard_screen.dart`, `lib/features/explore/presentation/explore_screen.dart` (`Geolocator.distanceBetween`) |
| 방문 인증 게이트 (반경 100m, GPS 오차 50m 이내) | `lib/features/film_roll/domain/visit_verification.dart` |
| 방문 인증 사진 촬영 좌표 저장 | `lib/core/database/tables/photos_table.dart`, `photo_repository_impl.dart` — **로컬 Drift DB에만** 저장(`latitude`, `longitude` nullable). 서버 동기화 payload에는 미포함 |

---

## 5. 촬영 사진 EXIF (확인 항목)

촬영 원본은 `CameraController.takePicture()` 결과를 **무변형으로 디스크에 저장**하고
(`lib/core/file/local_photo_storage.dart` — 썸네일만 `image` 패키지로 재인코딩, 원본은 손대지 않음),
동기화 시 그대로 채록 S3로 PUT한다.

따라서 `camera` 플러그인이 JPEG에 **GPS EXIF**를 심으면 좌표가 채록 인프라로 간접 전송된다.

- Flutter `camera`(`camera_avfoundation` / `camera_android`)는 기본적으로 위치 메타데이터를 사진에 넣지 않는다 → **GPS EXIF 미포함으로 간주**.
- **릴리스마다 실기기(iOS·Android)에서 촬영본 EXIF에 GPS IFD가 없는지 재확인한다**([release-checklist.md](release-checklist.md)).
- 만약 GPS가 발견되면: (1) 원본 저장 전 EXIF GPS 스트립을 별도 이슈로 추가, (2) 본 문서·`PrivacyInfo.xcprivacy`·스토어 체크리스트의 "제3자 공유/신원 연결" 값을 재검토.

---

## 6. 권한 키 현황

### iOS `ios/Runner/Info.plist`

| 키 | 상태 | 판정 |
| --- | --- | --- |
| `NSLocationWhenInUseUsageDescription` | 있음 | 유지 |
| `NSLocationAlwaysAndWhenInUseUsageDescription` / `NSLocationAlwaysUsageDescription` | 없음 | **없음이 정답**(백그라운드/Always 미사용) — 추가하지 않는다 |
| `UIBackgroundModes` → `location` | 없음 | 정상 |

### Android `android/app/src/main/AndroidManifest.xml`

| 권한 | 상태 | 판정 |
| --- | --- | --- |
| `ACCESS_FINE_LOCATION` | 있음 | Data safety에 Precise 신고 |
| `ACCESS_COARSE_LOCATION` | 있음 | Data safety에 Approximate 신고 |
| `ACCESS_BACKGROUND_LOCATION` | 없음 | 정상 |

---

## 7. 신고 값 매핑

| 신고 항목 | 값 | 근거 |
| --- | --- | --- |
| 수집 데이터 | Precise Location | §2 — `geolocator` 전체 좌표 |
| 수집 목적 | App Functionality (지역 판별·주변 채록 장소·필름롤·날씨) | §3, §4 |
| 사용자 신원 연결 (Linked) | **아니오** | §3 — 자체 백엔드가 좌표를 계정과 함께 저장하지 않음. 카카오/기상청 전송분에 계정 식별자 없음 |
| 추적 (Tracking) | **아니오** | `pubspec.yaml`에 광고·어트리뷰션·분석 SDK 없음 |
| 제3자 공유 | **예** — 카카오(역지오코딩), 기상청/공공데이터포털(날씨) | §3 |

---

## 8. 남은 확인 항목

- [ ] **백엔드 재확인**: 위치 인증·방문 인증 로그·분석 파이프라인에서 좌표를 별도로 수집·저장하지 않는지 (위 "Linked = 아니오" 근거 유지)
- [ ] **EXIF 실측**: iOS·Android 실기기 촬영본에 GPS EXIF가 없는지 (§5)
