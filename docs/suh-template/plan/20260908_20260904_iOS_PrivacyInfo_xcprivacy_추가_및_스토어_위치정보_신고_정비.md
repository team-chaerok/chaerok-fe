# 🎯 iOS PrivacyInfo.xcprivacy 추가 및 스토어 위치정보 신고 정비 — 전략 문서

- **이슈**: #82 `⚙️[기능추가][배포] iOS PrivacyInfo.xcprivacy 추가 및 스토어 위치정보 신고 정비`
- **관련 이슈**: #76 (Play 심사용 Mock 위치), #78 (회원가입 직후 위치 인증 화면)
- **작성일**: 2026-09-08
- **모드**: Plan (전략 수립 — 코드 수정 없음)
- **담당(FE)**: @SeoHyun1024

---

## 1. 요약

채록 앱은 `geolocator`로 기기의 정밀 좌표(Precise Location)를 수집하고, 이를 **카카오 로컬 API**(행정구역 판별)와 **기상청 단기예보 API**(날씨 조회)로 전송한다. Apple/Google 기준 "위치 데이터 수집·전송"에 해당하지만, iOS 앱 레벨 `PrivacyInfo.xcprivacy`가 없고 App Store Connect / Google Play 콘솔의 개인정보 신고 근거 문서도 없다. 본 작업은 (1) `ios/Runner/PrivacyInfo.xcprivacy` 초안 작성 및 Runner 타깃 포함, (2) 좌표 데이터 흐름 문서화, (3) 스토어 콘솔 신고 값 체크리스트 문서 작성, (4) `Info.plist` 위치 권한 키 최종 점검, (5) 릴리스 체크리스트에 "개인정보 매니페스트·스토어 신고 최신화" 항목 추가를 산출물로 한다. 콘솔 폼 실제 입력은 제출 담당자 몫이며, FE는 근거 문서와 매니페스트까지 책임진다.

---

## 2. 배경 및 목적

### 문제 / 필요성

| 항목 | 현재 상태 | 문제 |
| --- | --- | --- |
| iOS 앱 레벨 privacy manifest | 없음 ([ios/Runner/](../../../ios/Runner/)에 `PrivacyInfo.xcprivacy` 부재) | 플러그인(`geolocator_apple` 등)은 각자 매니페스트를 포함하지만, **앱이 직접 수집·전송하는 데이터**에 대한 앱 자체 매니페스트가 iOS 17+에서 사실상 필수 |
| App Store Connect 개인정보 신고 | 미정비 | Location → Precise Location 신고 근거 없음 |
| Google Play 데이터 보안 폼 | 미정비 | `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` 사용 중이나 신고 안 됨 |
| 데이터 흐름 문서 | 없음 | 신고 값(수집 목적·전송 대상·신원 연결 여부)의 근거를 남길 문서 부재 |
| 릴리스 체크리스트 | 없음 (repo 내 `docs/`에 릴리스/배포 체크리스트 문서 자체가 없음) | 매 릴리스마다 개인정보 신고 최신화 여부를 확인할 지점이 없음 |

`LocationAccuracy.medium`([location_permission_service.dart:88](../../../lib/features/location/data/location_permission_service.dart#L88), [:95](../../../lib/features/location/data/location_permission_service.dart#L95))을 사용하지만 이는 배터리 절충일 뿐, 여전히 전체 좌표를 반환·전송하므로 Precise Location 신고 대상이다.

### 목표

- iOS 17+ 심사 요구사항을 충족하는 앱 레벨 `PrivacyInfo.xcprivacy` 확보
- App Store Connect / Google Play 개인정보 신고를 정확히 채울 수 있는 **근거 문서** 확보
- 릴리스 프로세스에 개인정보 신고 최신화 확인 지점 삽입

### 범위

**포함 (FE 산출물)**

1. `ios/Runner/PrivacyInfo.xcprivacy` 초안 작성 + Xcode Runner 타깃 리소스 포함(`project.pbxproj` 반영)
2. `docs/deploy/privacy-data-flow.md` — 위치 좌표 데이터 흐름 문서
3. `docs/deploy/store-privacy-checklist.md` — App Store Connect / Google Play 신고 값 체크리스트
4. `docs/deploy/release-checklist.md` — 릴리스 체크리스트(신설) + "개인정보 매니페스트·스토어 신고 최신화" 항목
5. `ios/Runner/Info.plist` 위치 권한 키 최종 점검(불필요한 Always/Background 키 없음 확인 — 현재도 없음)

**제외**

- App Store Connect / Google Play 콘솔 폼 실제 입력 → **제출 담당자**가 체크리스트 문서를 보고 콘솔에서 반영
- 개인정보처리방침(Privacy Policy) 웹 문서 작성 → 이번 범위 아님(사용자 확정). 별도 이슈 권장
- 백엔드 코드/응답 변경 → 없음(아래 §5 결정사항 참고)
- 위치 정확도 조정(`medium` → `low` 등) 기능 변경 → 이번 범위 아님

---

## 3. 요구사항

### 필수 (P0)

- **P0-1** `ios/Runner/PrivacyInfo.xcprivacy` 생성
  - `NSPrivacyCollectedDataTypes` → **Precise Location**(`NSPrivacyCollectedDataTypePreciseLocation`)
    - 목적: **App Functionality**(`NSPrivacyCollectedDataTypePurposeAppFunctionality`) — 지역 판별, 주변 채록 장소·필름롤·날씨 제공
    - `NSPrivacyCollectedDataTypeLinked` = **false** (§5-D1 근거)
    - `NSPrivacyCollectedDataTypeTracking` = **false** (광고/어트리뷰션 SDK 없음, §5-D3 근거)
  - `NSPrivacyTracking` = `false`
  - `NSPrivacyTrackingDomains` = `[]` (빈 배열)
  - `NSPrivacyAccessedAPITypes` = 앱 1st-party 코드가 Required Reason API를 직접 호출하는지 점검 후 반영(§5-D4, 초기 가정: 빈 배열)
- **P0-2** 생성한 `PrivacyInfo.xcprivacy`를 Xcode **Runner** 타깃의 Copy Bundle Resources에 포함(`ios/Runner.xcodeproj/project.pbxproj` 반영). `flutter build ipa` 결과물 `Runner.app/PrivacyInfo.xcprivacy` 존재 확인
- **P0-3** `docs/deploy/privacy-data-flow.md` — 수집 지점 → 전송 대상 → 저장 위치를 표로 정리(§4 데이터 흐름 표 기반)
- **P0-4** `docs/deploy/store-privacy-checklist.md` — App Store Connect / Google Play 각각의 신고 값을 그대로 옮겨 적을 수 있는 체크리스트

### 중요 (P1)

- **P1-1** `docs/deploy/release-checklist.md` 신설 + "개인정보 매니페스트·스토어 신고 최신화" 항목
- **P1-2** `Info.plist` 위치 권한 키 점검 결과를 데이터 흐름 문서에 명시(현 상태: `NSLocationWhenInUseUsageDescription`만 존재, Always/Background 키 없음 — 유지)
- **P1-3** 카카오 로컬 API·기상청 API로의 좌표 전송을 스토어 폼에서 **제3자 데이터 공유**로 표기(§5-D2)
- **P1-4 (blocking)** 촬영 사진(`camera` 플러그인)의 EXIF GPS 포함 여부 **실기기 실측(T1)**. 촬영 원본은 채록 S3에 무변형 업로드되므로 GPS EXIF가 있으면 좌표가 자체 인프라로 간접 전송된다. **T1 완료 전에는 `Linked` 값·제3자 공유 수신처·보존 여부를 최종 확정하지 않는다.** (analyze 문서 T1과 동일 분류)

### 선택 (P2)

- **P2-1** `geolocator` / `permission_handler` / `camera` 등 위치·민감 플러그인의 번들 내 `PrivacyInfo.xcprivacy` 존재를 빌드 산출물에서 확인(플러그인 책임이지만 릴리스 점검 항목으로)
- **P2-2** 개인정보처리방침 웹 문서 별도 이슈 등록. Play 정책상 필요한 **외부 계정·데이터 삭제 요청 웹 URL** 마련 포함(인앱 삭제 경로 `DELETE /api/users/me`는 이미 존재)

---

## 4. 위치 좌표 데이터 흐름 (코드 근거)

### 4.1 수집 지점

| 지점 | 파일 | 내용 |
| --- | --- | --- |
| 좌표 조회 단일 진입점 | [location_permission_service.dart:58](../../../lib/features/location/data/location_permission_service.dart#L58) `getCurrentPosition()` | `Geolocator.getCurrentPosition(accuracy: medium, timeLimit: 30s)` |
| mock 좌표 분기 | [location_permission_service.dart:59](../../../lib/features/location/data/location_permission_service.dart#L59), [mock_location_gate.dart](../../../lib/core/location/mock_location_gate.dart) | 개발/QA 빌드 또는 테스트 계정+토글 시 저장된 지점 좌표 반환 (#76) |
| 권한 | [Info.plist:48](../../../ios/Runner/Info.plist#L48) `NSLocationWhenInUseUsageDescription` / [AndroidManifest.xml:5-6](../../../android/app/src/main/AndroidManifest.xml#L5-L6) `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` |

### 4.2 전송 대상

| 대상 | 호출 | 전송 값 | 성격 |
| --- | --- | --- | --- |
| **카카오 로컬 API** (`dapi.kakao.com`) | [kakao_local_api_service.dart:34-37](../../../lib/features/location/data/kakao_local_api_service.dart#L34-L37) `/v2/local/geo/coord2regioncode.json?x={lng}&y={lat}` | **원시 위·경도** | 제3자 전송 (§5-D2) |
| **기상청 단기예보 API** (`apis.data.go.kr`) | [weather_api_service.dart:37-49](../../../lib/features/home/data/weather_api_service.dart#L37-L49) | 위·경도를 [kma_grid_converter.dart](../../../lib/features/home/data/kma_grid_converter.dart)로 **격자(nx, ny)로 변환** 후 전송 (원시 좌표 자체는 미전송, 격자는 좌표에서 파생) | 제3자 전송 (§5-D2) |
| **채록 자체 백엔드** (`DioClient`) | [regions_api.dart](../../../lib/data/remote/regions_api.dart) `/api/regions/resolve` | **`provinceName`, `cityCountyName` 문자열만** ([resolve_region_request.dart](../../../lib/data/models/resolve_region_request.dart)) — 원시 좌표 미전송 | 좌표 미전송 |
| **채록 자체 백엔드** (방문 인증) | [visits_api.dart:29-39](../../../lib/data/remote/visits_api.dart#L29-L39) `/api/film-rolls/{id}/visits` | `placeId`만. 주석 명시: *"백엔드는 GPS 좌표, 정확도, 거리, 이동 경로를 받거나 저장하지 않는다"* | 좌표 미전송 |
| **채록 자체 백엔드** (사진 업로드) | [film_rolls_api.dart:77-88](../../../lib/data/remote/film_rolls_api.dart#L77-L88), [photo_upload_url_request.dart](../../../lib/data/models/photo_upload_url_request.dart) | `sequence`, `contentType`, `contentLength`, `takenAt`만. **사진 바이너리는 S3 presigned PUT으로 무변형 전송** | 좌표 메타데이터는 미전송이나, **원본 JPEG의 GPS EXIF가 있으면 좌표가 S3로 간접 전송** — P1-4(T1)에서 실측 |

### 4.3 온디바이스 사용 (전송 없음)

| 용도 | 파일 |
| --- | --- |
| 장소까지 거리 계산 | [home_dashboard_screen.dart:280](../../../lib/features/home/presentation/home_dashboard_screen.dart#L280), [explore_screen.dart:256](../../../lib/features/explore/presentation/explore_screen.dart#L256) `Geolocator.distanceBetween` |
| 방문 인증 게이트(반경 100m, GPS 오차 50m) | [visit_verification.dart:52](../../../lib/features/film_roll/domain/visit_verification.dart#L52) |
| 방문 인증 사진 좌표 저장 | [photos_table.dart](../../../lib/core/database/tables/photos_table.dart) — **로컬 Drift DB에 영속 저장**(`latitude`, `longitude` nullable). 서버 동기화 payload에는 미포함(단 원본 파일은 S3로 전송 → 4.2) |

### 4.4 결론

코드에서 **원시 정밀 좌표를 파라미터로 직접 전송하는 경로는 카카오 로컬 API 1곳**이며, 기상청은 좌표에서 파생된 격자값을 받는다. 채록 자체 백엔드는 **명시적 좌표 파라미터로는 위치를 수신하지 않으나**, 방문 인증 촬영 원본 JPEG가 S3에 무변형 저장되므로 **GPS EXIF 유무(P1-4/T1)가 "자체 인프라 미수신" 단정의 전제**다. 촬영 좌표는 로컬 Drift DB에 영속 저장된다.

---

## 5. 주요 결정사항

| # | 결정 | 선택 | 이유 |
| --- | --- | --- | --- |
| D1 | 정밀 위치의 "사용자 신원 연결(linked to identity)" 값 | **Not Linked (`false`)** — **P1-4/T1 완료 전까지 잠정** | §4 코드 분석상 명시적 좌표 파라미터가 계정과 함께 저장되지 않음. 카카오/기상청 전송분도 계정 식별자와 함께 보내지 않음(카카오는 REST 키 헤더만, 기상청은 serviceKey만). **단 촬영 원본 GPS EXIF가 없다는 T1 확인이 전제** — 있으면 사진이 계정에 연결되므로 재검토. 백엔드 재확인은 릴리스 체크리스트 항목으로 유지 |
| D2 | 카카오 로컬 API·기상청으로의 좌표 전송 표기 | **제3자 데이터 공유로 명시** | 사용자 확정. App Store "기타 업체와 데이터 공유" / Play "제3자와 데이터 공유"에 위치 전송 신고. 가장 보수적이고 심사 리스크가 낮음 |
| D3 | `NSPrivacyTracking` / `NSPrivacyCollectedDataTypeTracking` | **`false`** | [pubspec.yaml](../../../pubspec.yaml)에 광고·어트리뷰션·분석 SDK(Firebase/Sentry/Amplitude/AppsFlyer/Adjust/AdMob 등) 없음 확인. `NSPrivacyTrackingDomains` 빈 배열 |
| D4 | 앱 레벨 `NSPrivacyAccessedAPITypes` | **점검 후 반영, 초기 가정 빈 배열** | Flutter 앱 타깃 네이티브 코드는 `AppDelegate.swift`뿐. Required Reason API(UserDefaults/FileTimestamp/DiskSpace/SystemBootTime)는 `shared_preferences`·`path_provider`·`geolocator` 등 **플러그인이 자체 매니페스트로 신고**. 앱 1st-party 코드의 직접 호출 여부만 확인 후, 없으면 빈 배열 |
| D5 | 수집 목적 | **App Functionality만** | 지역 판별·주변 채록 장소/필름롤/날씨 제공. Analytics·Product Personalization·광고 목적 해당 없음 |
| D6 | 문서 위치 | **`docs/deploy/`** 신설 | 사용자 확정. 배포 관련 문서를 한 디렉토리로 모음 |
| D7 | 콘솔 폼 입력 주체 | **제출 담당자** | 이슈 명시. FE는 체크리스트 문서까지, 콘솔 반영은 담당자 |

### 남은 확인 항목

- **(blocking) EXIF 실측** (P1-4/T1): `camera` 플러그인 촬영본에 GPS EXIF가 실리는지 iOS·Android 실기기 실측. 실리면 S3 업로드로 좌표가 자체 인프라로 간접 전송되므로 수신처에 채록 S3 추가, `Linked` 값·데이터 흐름 문서 갱신. **신고 값 확정·심사 제출 전 필수.**
- **BE 재확인** (blocking 아님): 위치 인증·방문 인증 로그·분석 파이프라인에서 좌표를 별도 수집하지 않는지 (D1 근거 보강용, 릴리스 체크리스트 항목)

---

## 6. 선택한 접근 방식

### 방식: 수동 작성 매니페스트 + 근거 문서 우선 (문서→매니페스트→프로젝트 반영→빌드 검증 순)

**이유**

- privacy manifest 값은 "코드가 무엇을 어디로 보내는가"의 함수다. 데이터 흐름 문서를 먼저 확정하면 매니페스트 각 필드가 그 표의 한 줄로 환원되어 검증·리뷰가 쉽다.
- 콘솔 신고도 같은 표를 공유하므로 iOS 매니페스트와 스토어 폼이 어긋나지 않는다(Apple은 매니페스트와 App Privacy 답변 불일치를 지적함).
- `.xcprivacy`는 소규모 선언형 plist라 자동화 도구 도입 이득이 없다.

**대안 1 — 플러그인 매니페스트에만 의존, 앱 레벨 매니페스트 생략**
채택 안 함. `geolocator_apple`이 자체 매니페스트를 갖지만 이는 "플러그인이 접근하는 API"에 대한 것이고, "앱이 좌표를 카카오로 전송·수집한다"는 **앱의 행위**는 앱 레벨 매니페스트로만 신고 가능. iOS 17+ 심사에서 지적 대상.

**대안 2 — 도구/스크립트로 매니페스트 생성(예: `flutter_privacy_manifest` 류)**
채택 안 함. 파일이 30~40줄 수준이고 값이 프로젝트 정책 판단(D1~D5)에 의존해 자동 생성 이득이 없다. 유지보수 포인트만 늘어남.

**대안 3 — 이번에 개인정보처리방침 웹 문서까지 포함**
채택 안 함(사용자 확정). 범위가 커지고 법무 검토가 필요. 별도 이슈로 분리(P2-2).

---

## 7. 구현 단계 (개요 — 상세는 `/analyze`에서)

| 단계 | 산출물 | 검증 |
| --- | --- | --- |
| S1 | `docs/deploy/privacy-data-flow.md` | §4 표 + Info.plist/Manifest 권한 키 현황 + EXIF 점검 결과 반영 |
| S2 | `docs/deploy/store-privacy-checklist.md` | App Store Connect(App Privacy: Precise Location / App Functionality / Not Linked / No Tracking / 제3자 공유=카카오·기상청) + Google Play Data Safety(위치: 수집 O·공유 O, 목적=앱 기능) 항목별 값 표 |
| S3 | `ios/Runner/PrivacyInfo.xcprivacy` | plist lint(`plutil -lint`), 필드 값이 S1/S2와 일치 |
| S4 | `ios/Runner.xcodeproj/project.pbxproj` — Runner 타깃 리소스 등록 | `flutter build ipa` 후 `Runner.app/PrivacyInfo.xcprivacy` 포함 확인, Xcode Organizer의 "Generate Privacy Report" 통과 |
| S5 | `ios/Runner/Info.plist` 점검 | Always/Background 위치 키 없음 재확인(현 상태 유지), 문구 유지 |
| S6 | `docs/deploy/release-checklist.md` | "개인정보 매니페스트·스토어 신고 최신화 / 신규 SDK 추가 시 매니페스트 재점검 / BE 좌표 미수집 재확인" 항목 포함 |
| S7 | **(P1-4/blocking)** `camera` EXIF GPS 실기기 실측(T1) | iOS·Android 촬영본 EXIF 확인 → 결과를 S1·S2·S3에 반영. GPS 발견 시 수신처에 채록 S3 추가·`Linked` 재검토. **다른 산출물보다 먼저 착수** |

---

## 8. 고려사항 및 위험요소

### 기술적 위험

| 위험 | 영향 | 대응 |
| --- | --- | --- |
| `PrivacyInfo.xcprivacy`를 Runner 타깃에 등록해도 Flutter 빌드 파이프라인이 번들에 안 넣음 | 심사 시 매니페스트 누락으로 반려 | `flutter build ipa` 산출물에서 파일 존재를 S4 검증에 명시. `project.pbxproj`의 `PBXResourcesBuildPhase`에 확실히 포함 |
| 매니페스트 값과 App Store Connect App Privacy 답변 불일치 | Apple 심사 지적 | S2 체크리스트가 단일 출처(source of truth). 제출 담당자에게 문서 링크 전달 |
| EXIF GPS가 사진에 실려 S3로 전송 중이었음(T1 미점검 시) | "자체 인프라 좌표 미수신" 서술이 사실과 불일치 → 허위 신고 위험 | T1(S7)을 **P1-4 blocking**으로 고정. 신고 값 확정·심사 제출 전 필수 |
| 향후 분석/광고 SDK 추가 시 `NSPrivacyTracking`·수집 목적이 즉시 낡음 | 신고 부정확 | S6 릴리스 체크리스트에 "신규 SDK 추가 시 매니페스트·스토어 신고 재점검" 항목 고정 |
| `docs/deploy/`가 Git 공개 커밋됨 | 민감 정보 노출 | API 키/serviceKey 실제 값 미기재, 엔드포인트 경로만 기재(common-rules 마스킹 규칙) |

### 비즈니스 위험

| 위험 | 대응 |
| --- | --- |
| D1(Not Linked)이 BE 실제 구현과 다르면 허위 신고 | BE 재확인을 릴리스 체크리스트 blocking 항목으로. 코드 근거(§4)를 문서에 남겨 판단 이력 보존 |
| 제출 담당자가 체크리스트를 콘솔에 반영하지 않음 | S6 릴리스 체크리스트에 "스토어 콘솔 반영 완료" 확인란 포함, PR 설명에 담당자 멘션 |

---

## 9. 성공 기준

- [ ] `ios/Runner/PrivacyInfo.xcprivacy` 존재, `plutil -lint` 통과, 필드 값이 데이터 흐름 문서와 일치
- [ ] `flutter build ipa` 산출물 `Runner.app/PrivacyInfo.xcprivacy` 포함 확인
- [ ] Xcode "Generate Privacy Report"에서 앱 레벨 항목(Precise Location / App Functionality)이 표시됨
- [ ] `docs/deploy/privacy-data-flow.md` — 수집 지점·전송 대상·저장 위치가 코드 참조와 함께 정리됨
- [ ] `docs/deploy/store-privacy-checklist.md` — App Store Connect / Google Play 신고 값을 담당자가 그대로 입력 가능한 형태
- [ ] `docs/deploy/release-checklist.md` — "개인정보 매니페스트·스토어 신고 최신화" 항목 포함
- [ ] `Info.plist`에 Always/Background 위치 키 없음 재확인, `NSLocationWhenInUseUsageDescription` 문구 유지
- [ ] **(blocking)** EXIF GPS 실측(P1-4/T1) 결과가 데이터 흐름 문서·매니페스트·스토어 체크리스트에 반영됨
- [ ] `flutter analyze` / 기존 테스트 영향 없음(문서·plist·pbxproj 변경만)

---

## 10. 다음 단계

`/analyze` 로 진행 — `PrivacyInfo.xcprivacy` 정확한 키 스키마, `project.pbxproj` 수정 범위, `docs/deploy/` 3개 문서의 목차, EXIF 점검 방법을 파일 단위 구현 계획으로 구체화한다.
