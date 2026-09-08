# 스토어 개인정보 신고 체크리스트 (위치)

App Store Connect / Google Play 콘솔에 **그대로 옮겨 적기 위한** 신고 값 정리.
콘솔 입력은 **제출 담당자**가 한다. 근거는 [privacy-data-flow.md](privacy-data-flow.md).

- 관련 이슈: [#82](https://github.com/team-chaerok/chaerok-fe/issues/82)

---

## 1. App Store Connect — App Privacy

경로: App Store Connect → 앱 → **앱 개인정보 보호(App Privacy)** → 데이터 유형 편집

| 항목 | 값 |
| --- | --- |
| 데이터 유형 | **위치 → 정밀 위치(Precise Location)** |
| 이 데이터를 수집합니까? | 예 |
| 사용 목적 | **앱 기능(App Functionality)** |
| 사용자 신원에 연결됩니까? (Linked to the user) | **아니오** |
| 사용자 추적에 사용됩니까? (Tracking) | **아니오** |
| 제3자와 공유합니까? | **예** — 카카오(주소·행정구역 변환), 기상청/공공데이터포털(날씨 조회) |

- **대략적 위치(Coarse Location)는 신고하지 않는다** — 앱은 정밀 좌표만 다룬다.
- 이 값들은 `ios/Runner/PrivacyInfo.xcprivacy`와 일치해야 한다(§3 대조표).

---

## 2. Google Play — 데이터 보안(Data safety)

경로: Play Console → 앱 → **정책 → 앱 콘텐츠 → 데이터 보안**

| 항목 | 값 |
| --- | --- |
| 데이터 유형 | **위치 → 대략적인 위치(Approximate)** + **정밀한 위치(Precise)** |
| 수집(Collected) | 예 |
| 공유(Shared) | 예 — 카카오, 기상청/공공데이터포털 |
| 목적 | 앱 기능(App functionality) |
| 전송 중 암호화 | 예 (모든 호출 HTTPS) |
| 데이터가 일시적으로만 처리됩니까? | 예 — 자체 저장 없음. 카카오/기상청 전송분은 응답을 받으면 폐기 |
| 사용자가 삭제를 요청할 수 있습니까? | 개인정보처리방침 정책에 맞춰 응답 |

- Android 매니페스트에 `ACCESS_COARSE_LOCATION`이 선언되어 있으므로 **Approximate도 함께 체크**한다.
- `ACCESS_BACKGROUND_LOCATION` 없음 → 백그라운드 위치 관련 항목은 모두 "아니오".

---

## 3. 매니페스트 ↔ App Privacy 일치 대조표

| `PrivacyInfo.xcprivacy` 필드 | 값 | App Store Connect 대응 답변 |
| --- | --- | --- |
| `NSPrivacyCollectedDataType` | `NSPrivacyCollectedDataTypePreciseLocation` | 데이터 유형 = 정밀 위치 |
| `NSPrivacyCollectedDataTypeLinked` | `false` | 신원 연결 = 아니오 |
| `NSPrivacyCollectedDataTypeTracking` | `false` | 추적 = 아니오 |
| `NSPrivacyCollectedDataTypePurposes` | `[NSPrivacyCollectedDataTypePurposeAppFunctionality]` | 목적 = 앱 기능 |
| `NSPrivacyTracking` | `false` | (앱 전체) 추적 없음 |
| `NSPrivacyTrackingDomains` | `[]` (비어 있음) | 추적 도메인 없음 |
| `NSPrivacyAccessedAPITypes` | `[]` (비어 있음) | 앱 1st-party 코드에 Required Reason API 직접 호출 없음(플러그인은 각자 매니페스트로 신고) |

> "제3자 공유"는 `.xcprivacy`에 표현하는 필드가 없다. App Store Connect App Privacy 질문에서만 답한다.

---

## 4. 변경 전 / 후 스냅샷

| 콘솔 | 변경 전 (제출 담당자 확인) | 변경 후 |
| --- | --- | --- |
| App Store Connect App Privacy — 위치 | _(기입)_ | 정밀 위치 / 앱 기능 / 미연결 / 미추적 / 제3자 공유 |
| Play Data safety — 위치 | _(기입)_ | Approximate + Precise / 수집·공유 / 앱 기능 |

---

## 5. 제출 담당자 액션 아이템

- [ ] App Store Connect App Privacy에 위 §1 값 반영
- [ ] Play Console 데이터 보안 폼에 위 §2 값 반영
- [ ] 반영 후 §4 "변경 후" 열과 실제 콘솔 화면이 일치하는지 캡처로 확인
- [ ] 개인정보처리방침 문서(웹)에 위치 수집·제3자 전송 문구가 있는지 확인 (없으면 별도 이슈)
