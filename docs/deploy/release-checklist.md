# 릴리스 체크리스트

스토어(App Store / Google Play) 제출 전 확인 항목. 매 릴리스마다 이 문서를 복사해 채운다.

- 버전 규칙: [../versioning.md](../versioning.md)
- 개인정보 근거: [privacy-data-flow.md](privacy-data-flow.md), [store-privacy-checklist.md](store-privacy-checklist.md)

---

## 1. 버전 · 빌드

- [ ] `pubspec.yaml` `version: X.Y.Z+N` 수정 (빌드번호 `N`은 이전보다 큼)
- [ ] `chore : release version up ...` 커밋

## 2. 빌드 · 서명

- [ ] `flutter analyze` 통과
- [ ] `flutter test` 통과
- [ ] iOS: `flutter build ipa` 성공
- [ ] Android: `flutter build appbundle` 성공

## 3. 개인정보 · 컴플라이언스

- [ ] `ios/Runner/PrivacyInfo.xcprivacy`가 최신 데이터 흐름과 일치 ([privacy-data-flow.md](privacy-data-flow.md) §7 대조)
- [ ] `flutter build ipa` 산출물에 `Payload/Runner.app/PrivacyInfo.xcprivacy` 포함 확인
      (`unzip -l build/ios/ipa/*.ipa | grep PrivacyInfo`)
- [ ] Xcode Organizer → **Generate Privacy Report** 정상 (정밀 위치 / 앱 기능 항목 표시)
- [ ] **신규 SDK/플러그인 추가 시** 매니페스트·스토어 신고 재점검 (특히 광고·분석·어트리뷰션 → `NSPrivacyTracking` 영향)
- [ ] **백엔드에 "명시적 좌표 파라미터 수집/저장 없음, 로그·분석에도 미포함" 재확인** ([privacy-data-flow.md](privacy-data-flow.md) §8)
- [ ] **(blocking) `camera` 촬영본 EXIF에 GPS IFD 없음** 실기기 실측(T1, iOS·Android 각각). 신고 값(`Linked` 등) 확정 전 필수 — [privacy-data-flow.md](privacy-data-flow.md) §5·§8
- [ ] Play "데이터 삭제" — 인앱 삭제 경로(`DELETE /api/users/me`) 동작 확인 + **외부 삭제 요청 웹 URL** Play Console 등록
- [ ] App Store Connect App Privacy / Play 데이터 보안 콘솔 반영 완료 (제출 담당자 — [store-privacy-checklist.md](store-privacy-checklist.md) §5)
- [ ] `Info.plist` 위치 권한: `NSLocationWhenInUseUsageDescription`만 존재, Always/Background 키 없음

## 4. 스토어 메타데이터

- [ ] 스크린샷 / 설명 / 변경 사항(release notes) 최신화
- [ ] 연령 등급 · 카테고리 확인

## 5. 회귀 스모크

- [ ] 위치 인증 플로우 (권한 요청 → 좌표 → 지역 판별 → 관광지 조회)
- [ ] 필름롤 촬영 → 방문 인증 → 동기화
- [ ] 홈 날씨 표시
- [ ] Test Mode(비공개 테스트 빌드) 정상 동작

## 6. 제출

- [ ] TestFlight / 내부 테스트 업로드 후 설치 확인
- [ ] 심사 제출
