---
title: "❗[버그][네트워크] ErrorInterceptor가 원본 예외 정보를 손실시킴"
labels: [작업전]
assignee: SeoHyun1024
---

🗒️ 설명
---
스플래시 화면에서 헬스체크(`/api/health`) 실패 시 로그가 전혀 남지 않던 문제를 수정하는 과정에서, `ErrorInterceptor`가 Dio의 원본 예외 정보를 손실시키고 있는 것을 확인했습니다.

`lib/core/network/interceptors/error_interceptor.dart`의 `onError`에서 새 `DioException`을 생성할 때 원본 `message`를 넘기지 않고, `error` 필드에도 원본 예외 대신 이미 변환된 `ApiError`만 담아 재전달합니다. 그 결과 로그에는 `DioException [unknown]: null` / `ApiError(0): 알 수 없는 오류가 발생했습니다.`처럼 실제 원인을 알 수 없는 메시지만 남고, 연결 거부·타임아웃·인증서 오류·DNS 실패 등 구체적인 원인을 구분할 수 없습니다.

관련 파일:
- `lib/core/network/interceptors/error_interceptor.dart`
- `lib/core/network/interceptors/logging_interceptor.dart`
- `lib/features/splash/screens/splash_screen.dart`

🔄 재현 방법
---
1. 서버가 응답하지 않는 상태(네트워크 차단, 서버 다운 등)를 재현
2. 앱 실행 후 스플래시 화면에서 헬스체크 API 호출
3. 콘솔 로그에서 `DioException` 상세 내용 확인
4. 타입/메시지가 `unknown` / `null`로만 찍히고 실제 실패 원인(연결 거부, 타임아웃 등)을 구분할 수 없음을 확인

📸 참고 자료
---
```
[SplashScreen] 헬스체크 실패
[SplashScreen] DioException (DioException [unknown]: null
               Error: ApiError(0): 알 수 없는 오류가 발생했습니다.)
```

✅ 예상 동작
---
- 로그에 원본 `DioException`의 타입(`type`), 원본 메시지(`message`), 원본 예외(`error`)가 보존되어 있어야 함
- 개발자가 로그만 보고 연결 거부 / 타임아웃 / 인증서 오류 / DNS 실패 등 실패 원인을 구분할 수 있어야 함
- 사용자에게 노출되는 `ApiError` 메시지는 기존처럼 단순하게 유지하되, 디버깅용 원본 정보는 별도로 로깅되어야 함

⚙️ 환경 정보
---
- **OS**: Android 에뮬레이터
- **브라우저**: -
- **기기**: Android Emulator

🙋‍♂️ 담당자
---

- **백엔드**: -
- **프론트엔드**: -
- **디자인**: -
