# iOS PrivacyInfo.xcprivacy 추가 및 스토어 위치정보 신고 정비 — 분석 / 구현 계획서

- **이슈**: #82 `⚙️[기능추가][배포] iOS PrivacyInfo.xcprivacy 추가 및 스토어 위치정보 신고 정비`
- **선행 문서**: [plan/20260908_20260904_iOS_PrivacyInfo_xcprivacy_추가_및_스토어_위치정보_신고_정비.md](../plan/20260908_20260904_iOS_PrivacyInfo_xcprivacy_%EC%B6%94%EA%B0%80_%EB%B0%8F_%EC%8A%A4%ED%86%A0%EC%96%B4_%EC%9C%84%EC%B9%98%EC%A0%95%EB%B3%B4_%EC%8B%A0%EA%B3%A0_%EC%A0%95%EB%B9%84.md)
- **작성일**: 2026-09-08
- **모드**: Analyze (코드 분석 + 구현 계획 — 코드 수정 없음)

---

## 📊 분석 요약

| 항목 | 값 |
| --- | --- |
| **감지된 프로젝트 타입** | Flutter 앱 (`pubspec.yaml` name: `chaerok`, `publish_to: none`) |
| **주요 기술 스택** | Flutter / Dart, `dio`(HTTP), `geolocator` 14.x, `permission_handler` 12.x, `camera` 0.11.x, `drift`(로컬 DB), `image`(썸네일), `kakao_map_sdk` / `kakao_flutter_sdk_user`, `google_sign_in`, `sign_in_with_apple` |
| **코드 스타일** | `flutter_lints` + 커스텀 규칙: `prefer_single_quotes`, `require_trailing_commas`, `type_annotate_public_apis`, `directives_ordering`, `always_declare_return_types`. private 클래스 + `static` 메서드 서비스, `const` 생성자, 한국어 doc-comment. 네이티브: iOS 앱 타깃 1st-party 코드는 `AppDelegate.swift`만(플러그인 등록 외 로직 없음) |
| **변경 성격** | iOS 네이티브 리소스(plist) 1개 + Xcode `project.pbxproj` + 문서 3개 신설 + Info.plist 점검. **Dart 코드 변경 없음** |
| **pre-commit 훅 영향** | [.githooks/pre-commit](../../../.githooks/pre-commit)는 staged `.dart` 파일에만 `dart format` + `flutter analyze` 실행. 본 작업에 Dart 변경이 없으면 훅은 no-op |

---

## 🔍 현재 상태

### iOS 프로젝트 구조 ([ios/Runner.xcodeproj/project.pbxproj](../../../ios/Runner.xcodeproj/project.pbxproj))

- **Runner 타깃 Resources build phase**: id `97C146EC1CF9000F007C117D`, 현재 files:
  `LaunchScreen.storyboard`, `AppFrameworkInfo.plist`, `Assets.xcassets`, `Main.storyboard`
- **Runner PBXGroup**: id `97C146F01CF9000F007C117D`, `path = Runner`, children에 `Info.plist`(`97C147021CF9000F007C117D`) 등
- **RunnerTests Resources build phase**: id `331C807F294A63A400263BE5`, files 비어 있음 — 매니페스트 추가 대상 아님(테스트 번들은 심사 대상 아님)
- `PrivacyInfo.xcprivacy` **파일 없음** — 플러그인 Pods(`geolocator_apple` 등)는 각자 번들 매니페스트 보유(별도, 본 작업 범위 밖)

### Info.plist ([ios/Runner/Info.plist](../../../ios/Runner/Info.plist))

| 키 | 현재 | 판정 |
| --- | --- | --- |
| `NSLocationWhenInUseUsageDescription` | `"주변 장소 추천 등 위치 기반 서비스를 제공하기 위해 위치 권한이 필요합니다."` | 유지 |
| `NSLocationAlwaysAndWhenInUseUsageDescription` / `NSLocationAlwaysUsageDescription` | 없음 | **없음이 정답** (백그라운드/Always 미사용) — 추가하지 않음 |
| `UIBackgroundModes` (location) | 없음 | 정상 |
| `NSCameraUsageDescription` | 존재 | 범위 밖(참고만) |

### Android ([android/app/src/main/AndroidManifest.xml](../../../android/app/src/main/AndroidManifest.xml))

`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` 선언(주석 있음). `ACCESS_BACKGROUND_LOCATION` 없음(정상). → Data Safety 폼 신고 대상.

### 좌표 데이터 흐름 (plan §4 재확인 + 심화)

| 대상 | 전송 값 | 근거 |
| --- | --- | --- |
| 카카오 로컬 API `dapi.kakao.com` | **원시 위·경도** (`x`, `y` 쿼리) | [kakao_local_api_service.dart:34-37](../../../lib/features/location/data/kakao_local_api_service.dart#L34-L37) |
| 기상청 `apis.data.go.kr` | 위·경도 → **격자 nx/ny 변환 후** 전송 | [weather_api_service.dart:31-49](../../../lib/features/home/data/weather_api_service.dart#L31-L49), [kma_grid_converter.dart](../../../lib/features/home/data/kma_grid_converter.dart) |
| 채록 백엔드 `/api/regions/resolve` | `provinceName`, `cityCountyName` 문자열만 | [resolve_region_request.dart](../../../lib/data/models/resolve_region_request.dart), [location_verification_runner.dart:125-136](../../../lib/features/location/data/location_verification_runner.dart#L125-L136) |
| 채록 백엔드 `/api/film-rolls/{id}/visits` | `placeId`(+`photoId`)만. 주석: "백엔드는 GPS 좌표…받거나 저장하지 않는다" | [visits_api.dart:29-39](../../../lib/data/remote/visits_api.dart#L29-L39) |
| 채록 백엔드 사진 업로드 URL | `sequence`, `contentType`, `contentLength`, `takenAt` | [photo_upload_url_request.dart](../../../lib/data/models/photo_upload_url_request.dart) |
| 채록 S3 (presigned PUT) | **원본 사진 바이트 그대로** (재인코딩 없음) | [local_photo_storage.dart:48](../../../lib/core/file/local_photo_storage.dart#L48) `writeAsBytes(imageBytes)` → [film_roll_sync_service.dart:246-263](../../../lib/features/film_roll/data/sync/film_roll_sync_service.dart#L246-L263) `_readPhotoBytes` → `_putPhotoToS3` |
| 로컬 Drift DB `photos` | 촬영 좌표(`latitude`, `longitude` nullable) — **온디바이스만** | [photos_table.dart](../../../lib/core/database/tables/photos_table.dart), [photo_repository_impl.dart:54-59](../../../lib/features/film_roll/data/repository/photo_repository_impl.dart#L54-L59) |

**신규 발견 (EXIF 리스크 상향)**: 촬영 원본은 [visit_capture_screen.dart:257-259](../../../lib/features/film_roll/presentation/page/visit_capture_screen.dart#L257-L259) `controller.takePicture()` → `readAsBytes()` 결과가 **디스크에 무변형 저장**되고, 동기화 시 **그대로 S3로 PUT**된다(썸네일만 `image` 패키지로 재인코딩, 원본은 손대지 않음). 따라서 `camera` 플러그인이 JPEG에 GPS EXIF를 심으면 **좌표가 채록 S3로 간접 전송**된다. → "자체 백엔드는 원시 좌표를 수신하지 않는다"(plan D1)의 전제 조건. **구현 전 실측 검증 필수(아래 T1)**.

---

## 🎯 구현 목표

1. `ios/Runner/PrivacyInfo.xcprivacy` 생성 + Runner 타깃 리소스로 포함 → `flutter build ipa` 산출물에 번들
2. `docs/deploy/privacy-data-flow.md` — 좌표 데이터 흐름 문서(위 표 + EXIF 검증 결과)
3. `docs/deploy/store-privacy-checklist.md` — App Store Connect / Google Play 신고 값 체크리스트(제3자 공유 포함)
4. `docs/deploy/release-checklist.md` — 릴리스 체크리스트 신설 + 개인정보 신고 최신화 항목
5. `ios/Runner/Info.plist` 위치 권한 키 최종 점검 결과를 데이터 흐름 문서에 기록(코드 변경 없음)

---

## 📝 상세 구현 계획

### 1️⃣ 준비 단계

| # | 작업 | 비고 |
| --- | --- | --- |
| P1 | `camera` 촬영본 EXIF 실측 (T1) | 결과가 이후 매니페스트/문서/체크리스트 값에 영향. **선행 필수** |
| P2 | 현재 App Store Connect / Play Console 개인정보 신고 스냅샷 확보(제출 담당자에게 현재 값 요청) | 체크리스트에 "변경 전/후" 비교로 남김. blocking 아님 |
| P3 | 플러그인 매니페스트 존재 확인: `flutter build ios --config-only` 후 `ios/Pods/` 내 `geolocator_apple`, `permission_handler_apple`, `camera_avfoundation`, `path_provider_foundation`, `shared_preferences_foundation`, `sqlite3_flutter_libs` 의 `*/PrivacyInfo.xcprivacy` 확인 | 플러그인 책임이나 릴리스 점검 항목화 |

### 2️⃣ 핵심 구현

#### 2-1. `ios/Runner/PrivacyInfo.xcprivacy` (신규)

정확한 Apple 키 스키마(감사 결과 반영 전 초안):

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>NSPrivacyTracking</key>
  <false/>
  <key>NSPrivacyTrackingDomains</key>
  <array/>
  <key>NSPrivacyCollectedDataTypes</key>
  <array>
    <dict>
      <key>NSPrivacyCollectedDataType</key>
      <string>NSPrivacyCollectedDataTypePreciseLocation</string>
      <key>NSPrivacyCollectedDataTypeLinked</key>
      <false/>
      <key>NSPrivacyCollectedDataTypeTracking</key>
      <false/>
      <key>NSPrivacyCollectedDataTypePurposes</key>
      <array>
        <string>NSPrivacyCollectedDataTypePurposeAppFunctionality</string>
      </array>
    </dict>
  </array>
  <key>NSPrivacyAccessedAPITypes</key>
  <array/>
</dict>
</plist>
```

값 확정 근거:

| 필드 | 값 | 근거 |
| --- | --- | --- |
| `NSPrivacyCollectedDataType` | `NSPrivacyCollectedDataTypePreciseLocation` | `geolocator` 전체 좌표 수집. `LocationAccuracy.medium`이어도 Precise 대상(plan §2) |
| `...Linked` | `false` | plan D1 — 자체 백엔드 원시 좌표 미수신. **단 T1에서 EXIF GPS 확인 시 재검토** |
| `...Tracking` | `false` | plan D3 — 광고/어트리뷰션/분석 SDK 없음([pubspec.yaml](../../../pubspec.yaml)) |
| `...Purposes` | `[AppFunctionality]` | plan D5 — 지역 판별·주변 장소·필름롤·날씨 |
| `NSPrivacyTrackingDomains` | `[]` | 추적 도메인 없음 |
| `NSPrivacyAccessedAPITypes` | `[]` | 앱 1st-party 코드(`AppDelegate.swift`)에 Required Reason API 직접 호출 없음. UserDefaults/FileTimestamp 등은 플러그인이 자체 매니페스트로 신고. **T2에서 재확인** |

> ⚠️ `NSPrivacyCollectedDataType`에 **Coarse Location**(`NSPrivacyCollectedDataTypeCoarseLocation`)은 추가하지 않는다 — 앱은 정밀 좌표만 다루므로 Precise 하나로 충분(중복 신고는 App Privacy 답변과 불일치 소지).
> ⚠️ "제3자 공유"(plan D2)는 `.xcprivacy`에 표현하는 필드가 **없다**. Apple에서는 App Store Connect의 App Privacy 질문("이 데이터를 제3자와 공유합니까")에서만 답한다 → §2-3 체크리스트 문서로만 반영.

#### 2-2. `ios/Runner.xcodeproj/project.pbxproj` (수정)

4곳에 항목 추가 (UUID 2개 신규 생성 — 24자리 hex, 기존과 충돌 없이):

| 섹션 | 추가 내용 |
| --- | --- |
| `PBXBuildFile` | `<UUID_BUILD> /* PrivacyInfo.xcprivacy in Resources */ = {isa = PBXBuildFile; fileRef = <UUID_REF> /* PrivacyInfo.xcprivacy */; };` |
| `PBXFileReference` | `<UUID_REF> /* PrivacyInfo.xcprivacy */ = {isa = PBXFileReference; lastKnownFileType = text.xml; path = PrivacyInfo.xcprivacy; sourceTree = "<group>"; };` |
| `PBXGroup` `97C146F01CF9000F007C117D` (Runner) children | `<UUID_REF> /* PrivacyInfo.xcprivacy */,` 추가 |
| `PBXResourcesBuildPhase` `97C146EC1CF9000F007C117D` (Runner Resources) files | `<UUID_BUILD> /* PrivacyInfo.xcprivacy in Resources */,` 추가 |

> 대안: Xcode GUI로 "Add Files to Runner…" → Runner 타깃 체크. 수동 편집과 결과 동일하나 CI/리뷰 재현성을 위해 pbxproj 직접 편집을 권장하고 `flutter build ipa`로 검증(3️⃣).
> `project.pbxproj`는 objectVersion에 따라 정렬 규칙이 있으니 기존 항목 포맷(들여쓰기 탭, 정렬 위치)을 그대로 따른다.

#### 2-3. `docs/deploy/store-privacy-checklist.md` (신규)

목차:

1. **App Store Connect — App Privacy**
   - Data Type: **Precise Location**
   - Collection: Yes / Linked to user: **No** (T1 결과 반영) / Used for tracking: **No**
   - Purposes: **App Functionality**
   - "Shared with third parties": **Yes** → 수신자: 카카오(Kakao Local API, 역지오코딩), 기상청/공공데이터포털(단기예보) — plan D2
2. **Google Play — Data safety**
   - Location → **Approximate location** + **Precise location**: Collected = Yes, Shared = Yes
   - Purpose: App functionality
   - "Is this data processed ephemerally?" — 실제 저장 여부에 맞춰 응답(자체 저장 없음 → 카카오/기상청 전송분은 일시 처리)
   - Data encrypted in transit: Yes (HTTPS) / User can request deletion: 정책에 맞춰
3. **매니페스트 ↔ 폼 일치 표** — `.xcprivacy` 필드와 App Privacy 답변이 1:1로 맞는지 대조표
4. **변경 전/후 스냅샷** (P2 결과)
5. **제출 담당자 액션 아이템 체크박스**

#### 2-4. `docs/deploy/privacy-data-flow.md` (신규)

목차: 수집 지점 / 전송 대상 표(위 🔍 표) / 온디바이스 사용 / EXIF 검증 결과(T1) / Info.plist·AndroidManifest 권한 키 현황 / 신고 값 매핑 근거 / 남은 확인 항목(BE 재확인).

#### 2-5. `docs/deploy/release-checklist.md` (신규)

섹션: 버전/빌드 → 빌드·서명 → **개인정보·컴플라이언스**(아래) → 스토어 메타데이터 → 회귀 테스트 → 제출.

개인정보·컴플라이언스 항목:
- [ ] `ios/Runner/PrivacyInfo.xcprivacy`가 최신 데이터 흐름과 일치 (`docs/deploy/privacy-data-flow.md` 대조)
- [ ] `flutter build ipa` 산출물에 `Runner.app/PrivacyInfo.xcprivacy` 포함
- [ ] Xcode Organizer "Generate Privacy Report" 정상
- [ ] 신규 SDK/플러그인 추가 시 매니페스트·스토어 신고 재점검
- [ ] BE에 "위치 좌표 수집/저장 없음" 재확인 (D1 근거 유지)
- [ ] App Store Connect App Privacy / Play Data safety 콘솔 반영 완료 (제출 담당자)
- [ ] `camera` 촬영본 EXIF GPS 미포함 재확인 (또는 스트립 처리 유지 확인)

#### 2-6. `ios/Runner/Info.plist` — 점검만 (변경 없음)

Always/Background 위치 키 부재, `NSLocationWhenInUseUsageDescription` 문구 유지 확인 → 결과를 §2-4 문서에 기록.

### 3️⃣ 검증 (테스트)

| # | 시나리오 | 방법 | 기대 |
| --- | --- | --- | --- |
| **T1** | `camera` 촬영본 EXIF에 GPS 있는가 | 실기기 촬영 → 저장된 `film_rolls/.../original/*.jpg`를 꺼내 `exiftool` 또는 `img.decodeJpg(bytes).exif` 로그 확인. iOS/Android 각각 | GPS IFD 없음 기대. **있으면**: (a) 저장 전 스트립 코드 추가를 별도 이슈로, (b) `.xcprivacy`/체크리스트에서 자체 백엔드도 좌표 수신처로 반영 |
| **T2** | 앱 1st-party Required Reason API 호출 여부 | `AppDelegate.swift` + `ios/Runner/` 내 Swift 전수 확인(현재 `AppDelegate` 1개, 로직 없음) | 없음 → `NSPrivacyAccessedAPITypes` 빈 배열 유지 |
| **T3** | 매니페스트 빌드 번들 포함 | `flutter build ipa --no-codesign` 후 `find build/ios -name PrivacyInfo.xcprivacy` / `Payload/Runner.app/` 내 존재 | Runner.app 루트에 파일 존재 |
| **T4** | plist 유효성 | `plutil -lint ios/Runner/PrivacyInfo.xcprivacy` | `OK` |
| **T5** | Privacy Report | Xcode → Product → Archive → Organizer → Generate Privacy Report | Precise Location / App Functionality 항목 표시(플러그인 항목과 병합) |
| **T6** | 회귀 | `flutter analyze`, `flutter test`, 위치 인증·필름롤 촬영 플로우 스모크 | 영향 없음(네이티브 리소스/문서 변경만) |
| **T7** | Android 빌드 | `flutter build appbundle` | 정상(Android는 매니페스트 파일 변경 없음, 문서만) |

### 4️⃣ 검증 및 문서화

- 3개 문서(`docs/deploy/*.md`) 상호 링크 및 이슈 #82 역참조
- PR 설명에 T1/T3/T5 결과 캡처, 제출 담당자 멘션, "콘솔 반영은 담당자 몫" 명시
- 커밋 컨벤션(common-rules §커밋 메시지):
  - `iOS PrivacyInfo.xcprivacy 추가 및 스토어 위치정보 신고 정비 : feat : ios/Runner 앱 레벨 privacy manifest 추가 및 Runner 타깃 포함 {이슈URL}`
  - `... : docs : 위치 좌표 데이터 흐름·스토어 신고 체크리스트·릴리스 체크리스트 문서 추가 {이슈URL}`

---

## ⚠️ 주의사항 (위험 요소 및 대안)

| 위험 | 영향 | 대응 |
| --- | --- | --- |
| **T1에서 EXIF GPS 발견** | plan D1(Not Linked)·"자체 백엔드 좌표 미전송" 서술이 사실과 불일치 → 허위 신고 위험 | T1을 **blocking 선행 작업**으로. 발견 시 이번 PR 범위에 "원본 저장 전 EXIF GPS 스트립"(`local_photo_storage.save`에서 `img` 재인코딩 또는 EXIF 제거) 포함 여부를 사용자와 재협의. 최소한 문서/매니페스트에 사실 반영 |
| `project.pbxproj` 수동 편집 실수 | Xcode 프로젝트 파손, 빌드 불가 | 편집 후 즉시 `plutil -lint`(pbxproj는 plist), `flutter build ipa` 통과 확인. 실패 시 `git checkout`. 대안: Xcode GUI 추가 |
| Flutter 빌드가 매니페스트를 번들에서 누락 | 심사 반려 | T3로 산출물 직접 확인을 완료 조건에 포함 |
| 매니페스트 값 ↔ App Store Connect App Privacy 답변 불일치 | Apple 심사 지적 | §2-3 "매니페스트↔폼 일치 표"를 단일 출처로. 제출 담당자에게 문서 링크 전달 |
| 향후 분석/광고 SDK 추가 시 `NSPrivacyTracking`·목적 낡음 | 신고 부정확 | 릴리스 체크리스트에 "신규 SDK 추가 시 재점검" 고정(§2-5) |
| `docs/deploy/`가 Git 공개 커밋 | 민감 정보 노출 | API 키·serviceKey 실제 값 미기재, 엔드포인트 경로만. common-rules 마스킹 규칙 준수 |
| BE가 실제로는 좌표를 로깅/분석 | D1 근거 붕괴 | 릴리스 체크리스트 "BE 재확인" 항목 + 이번 PR에서 BE 담당에게 코멘트로 확인 요청 |
| Play "Approximate location" 신고 여부 논쟁 | `ACCESS_COARSE_LOCATION` 선언되어 있으므로 Approximate도 신고 대상 | 체크리스트에 Approximate+Precise 둘 다 체크로 명시(§2-3) |

---

## 📁 변경/신규 파일 목록

| 파일 | 유형 | 변경 |
| --- | --- | --- |
| `ios/Runner/PrivacyInfo.xcprivacy` | 신규 | 앱 레벨 privacy manifest |
| `ios/Runner.xcodeproj/project.pbxproj` | 수정 | PBXBuildFile / PBXFileReference / Runner PBXGroup / Runner Resources build phase 4곳 |
| `docs/deploy/privacy-data-flow.md` | 신규 | 좌표 데이터 흐름 |
| `docs/deploy/store-privacy-checklist.md` | 신규 | ASC / Play 신고 값 체크리스트 |
| `docs/deploy/release-checklist.md` | 신규 | 릴리스 체크리스트 + 개인정보 항목 |
| `ios/Runner/Info.plist` | **변경 없음** | 점검만, 결과는 문서에 기록 |
| `docs/test-mode-guide.md` 등 기타 | 변경 없음 | — |

- **Dart 소스 변경 없음** (T1 결과에 따라 EXIF 스트립이 추가되면 [local_photo_storage.dart](../../../lib/core/file/local_photo_storage.dart) 1개 파일이 범위에 편입 — 사용자 재협의 후 결정)

---

## ▶️ 다음 단계

`/implement` 로 진행. 순서: **T1(EXIF 실측) → T2 → 매니페스트 작성(§2-1) → pbxproj 편집(§2-2) → T3/T4/T5 검증 → 문서 3종 작성(§2-3~2-5) → Info.plist 점검(§2-6) → T6/T7 회귀**.
T1 결과가 매니페스트 `...Linked` 값과 체크리스트 "제3자 공유 수신처"에 직접 반영되므로 반드시 먼저 수행한다.
