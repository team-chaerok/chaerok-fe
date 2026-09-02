# ⚙️[기능추가][Auth] Apple 로그인 추가 — 회원탈퇴 authorizationCode 연동 (후속)

## 개요

`DELETE /api/users/me`에 `authorizationCode` request body가 추가됨에 따라, Apple 사용자가 회원탈퇴할 때 Apple 재인증으로 단회성 authorizationCode를 발급받아 백엔드에 전달하도록 구현했다. 백엔드는 이 코드로 Apple 서버에 토큰 폐기(revoke)를 요청한다. 카카오·구글 사용자는 재인증 없이 기존 흐름을 유지한다.

## 변경 사항

- `lib/core/network/dio_client.dart`: `delete()`가 request body(`data`)를 받도록 확장
- `lib/data/remote/users_api.dart`: `withdraw({String? authorizationCode})` — `DELETE /api/users/me`에 `{"authorizationCode": ...}` 전송
- `lib/features/auth/data/apple_auth_service.dart`: `getAuthorizationCode()` 추가 — Apple 재인증 시트로 authorizationCode 발급. 사용자가 취소하면 `null` 반환, 그 외 실패는 rethrow
- `lib/features/settings/presentation/settings_screen.dart`: 탈퇴 시 `getMyInformation()`으로 provider 확인 → Apple이면 재인증 → 발급된 코드를 `withdraw()`에 전달. 재인증 취소 시 탈퇴 중단

## 동작 흐름 (Apple 사용자)

```
회원탈퇴 탭 → 확인 다이얼로그
  → Apple 재인증 시트
      ├─ 취소 → 탈퇴 중단 (로딩 해제, 에러 표시 없음)
      └─ 완료 → DELETE /api/users/me { authorizationCode }
          → 백엔드가 Apple revoke 처리
          → 로컬 토큰 삭제 → 로그인 화면
```

## 주의사항

- provider 확인을 위해 탈퇴 시 `GET /api/users/me` 호출이 1회 추가된다. 탈퇴는 확인 다이얼로그를 거치는 드문 동작이라 비용상 문제없다고 판단.
- 카카오·구글 사용자 요청은 `{"authorizationCode": null}` body로 나간다.
