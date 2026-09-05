#!/usr/bin/env bash
# 비공개 테스트(closed testing) 빌드.
#
# Test Mode(위치 판정 우회 + E2E 시나리오 패널)를 활성화하는 compile-time flag
# `CHAEROK_TEST_MODE=true` 를 config/testers.json 으로 주입한다.
# 정식 빌드는 이 스크립트를 쓰지 않고 `flutter build appbundle` 를 그대로 쓴다
# (정식 빌드에는 config/prod.json = {} 만 있으므로 flag 가 false 로 컴파일됨).
#
# 사용:
#   scripts/build-testers.sh appbundle          # Android App Bundle
#   scripts/build-testers.sh apk --debug        # 디버그 APK
#   scripts/build-testers.sh ipa                # iOS
set -euo pipefail

TARGET="${1:-appbundle}"
shift || true

exec flutter build "$TARGET" \
  --dart-define-from-file=config/testers.json \
  "$@"
