# 🔍[시험요청][iOS] Test Mode iOS 빌드/동작 회귀 검증

- 라벨: 작업전
- 담당자: 프론트엔드 SeoHyun1024

---

📝 배경
---

- Test Mode(비공개 테스트용 위치 판정 우회 + E2E 시나리오 패널)는 **Android 우선**으로 구현한다.
  - 전략: [docs/suh-template/plan/20260906_20260905_Test_Mode_비공개_테스트_위치_우회_및_E2E_시나리오_패널.md](../plan/20260906_20260905_Test_Mode_비공개_테스트_위치_우회_및_E2E_시나리오_패널.md)
  - 분석: [docs/suh-template/analyze/20260906_20260905_Test_Mode_안드로이드_우선_구현_분석.md](../analyze/20260906_20260905_Test_Mode_안드로이드_우선_구현_분석.md)
- **결정 변경**: Android product flavor를 쓰지 않고 **compile-time flag(`CHAEROK_TEST_MODE`) 단독 +
  `--dart-define-from-file`** 로 간다. 이 방식은 플랫폼 무관이라 iOS는 스킴/xcconfig/번들ID
  **분리가 불필요**하다. (당초 예상했던 iOS 스킴 분리·Apple/Google/Kakao iOS OAuth 재등록 작업은
  **발생하지 않음**.)
- 따라서 이 이슈는 "iOS 빌드/동작이 flag 방식에서 문제없는지" **회귀 검증 체크리스트**만 남긴다.
  독립 트래킹이 불필요하면 메인 기능 이슈의 체크리스트로 흡수해도 된다.

⚙️ 검증 항목
---

- [ ] iOS 비공개 테스트 빌드: `flutter build ipa --dart-define-from-file=config/testers.json` 가
      `AppFlavor.isTestMode == true` 로 반영되는지
- [ ] iOS 비공개 테스트 빌드 + 서버 `isTester` 계정으로 실기기(공주 밖) E2E:
      공주 진입 → 촬영 → 관광지/음식점/카페 인증 → 공주 이탈 → 현상 대기 → 현상 완료 → 결과/릴스
- [ ] iOS 정식 빌드(`flutter build ipa`) + 일반 계정: 마이 탭에 Test Mode 항목 없음, 패널 도달 불가
- [ ] iOS 정식 빌드 + 서버 `isTester` 계정: 패널 진입 가능(기존 Play/앱스토어 심사 Mock 흐름 대응 유지)
- [ ] CI `PROJECT-CHECK-FLUTTER.yml` 의 `Inject secrets (iOS)` 스텝이 변경 없이 통과
- [ ] `config/prod.json` 에 `CHAEROK_TEST_MODE` 가 없어 iOS 정식 빌드에도 test define이 섞이지 않음
- [ ] `README.md` 에 iOS 비공개 테스트 빌드 명령 반영

🔗 의존 / 선행
---

- 선행: Test Mode Android 구현(메인 이슈) 머지 — `AppFlavor` / `TestModeSession` / 패널 / 배선 확보 후 검증.
- FCM 시작/완료 알림 검증은 이 이슈 범위 밖(별도 이슈).

⚙️ 환경 정보
---

- **OS**: iOS
- **기기**: 실기기(TestFlight 비공개 테스트) 기준

🙋‍♂️ 담당자
---

- **백엔드**: - (서버 `isTester` 플래그 외 변경 없음)
- **프론트엔드**: @SeoHyun1024
- **디자인**: -
