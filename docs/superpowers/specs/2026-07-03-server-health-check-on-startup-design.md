# 앱 시작 시 서버 헬스 체크 설계

**날짜:** 2026-07-03
**상태:** 승인됨

---

## 목표

앱이 시작될 때 서버 상태를 확인하여 사용자에게 서버 이상 여부를 알린다. 실패 시에도 앱 진입을 막지 않고 경고 후 진행한다.

---

## 전체 흐름

```
main.dart
  └─ AppStartup.initialize()   # SDK 초기화
  └─ runApp(ChaerokApp)
       └─ home: SplashScreen

SplashScreen
  1. 로딩 인디케이터 표시
  2. HealthApi.checkHealth() 호출
  3a. 성공 → LoginScreen으로 replace
  3b. 실패 → ScaffoldMessenger 스낵바 경고 → 1초 대기 → LoginScreen으로 replace
```

---

## 컴포넌트 설계

### AppStartup (`lib/app/app_startup.dart`)

앱 시작 전 필요한 모든 SDK/인프라 초기화를 담당한다. `main.dart`는 이 메서드 하나만 호출한다.

```dart
class AppStartup {
  static Future<void> initialize({void Function()? onUnauthorized}) async {
    KakaoSdk.init(nativeAppKey: AppSecrets.kakaoNativeAppKey);
    await GoogleSignIn.instance.initialize(
      clientId: AppSecrets.googleClientId,
      serverClientId: AppSecrets.googleServerClientId,
    );
    DioClient.init(onUnauthorized: onUnauthorized);
  }
}
```

### SplashScreen (`lib/features/splash/screens/splash_screen.dart`)

- `StatefulWidget`으로 구현
- `initState`에서 `_init()` 비동기 호출
- UI: 앱 이름 또는 로고 + 로딩 인디케이터
- health check 성공: `Navigator.pushReplacement` → `LoginScreen`
- health check 실패: `ScaffoldMessenger.showSnackBar`로 경고 메시지 표시 → 1초 후 `LoginScreen`으로 이동
- 타임아웃: `DioClient` 기존 설정 (`connectTimeout: 10s`) 그대로 활용
- `mounted` 체크를 통해 위젯 해제 후 Navigator 호출 방지

### main.dart 정리

현재 `main.dart`에 있는 SDK 초기화 코드를 `AppStartup.initialize()`로 위임한다. `MyApp` 래퍼를 제거하고 `ChaerokApp`을 직접 `runApp`에 전달한다.

### app.dart 변경

`home`을 `LoginScreen`에서 `SplashScreen`으로 교체한다.

---

## 변경 파일 목록

| 파일 | 변경 유형 | 내용 |
|---|---|---|
| `lib/main.dart` | 수정 | SDK init 제거, `AppStartup.initialize()` 호출, `MyApp` 래퍼 제거 |
| `lib/app/app_startup.dart` | 신규 구현 | SDK 및 DioClient 초기화 |
| `lib/app/app.dart` | 수정 | `home: SplashScreen`으로 변경 |
| `lib/features/splash/screens/splash_screen.dart` | 신규 생성 | 헬스 체크 + 로딩 UI |

---

## 오류 처리

- 헬스 체크 실패(네트워크 오류, 타임아웃, 서버 500 등) → 모두 동일하게 스낵바 경고 후 진행
- 성공 기준: `HealthApi.checkHealth()` 예외 없이 반환
- 실패 기준: 예외 발생 (DioException 포함)

---

## 범위 외

- 재시도 버튼 UI (실패 시 막지 않음)
- 오프라인 모드
- 헬스 체크 결과에 따른 기능 제한
