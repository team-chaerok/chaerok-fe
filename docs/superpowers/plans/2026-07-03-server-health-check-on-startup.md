# Server Health Check on Startup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 앱 시작 시 Flutter SplashScreen에서 서버 헬스 체크를 수행하고, 실패 시 스낵바 경고 후 LoginScreen으로 진행한다.

**Architecture:** `AppStartup.initialize()`가 SDK 초기화를 담당하고 `main.dart`는 이를 호출한다. `SplashScreen`이 앱 첫 화면으로 헬스 체크를 수행하며, 결과에 따라 LoginScreen으로 이동한다.

**Tech Stack:** Flutter, Dart, Dio (`DioClient`), `HealthApi` (기존 구현)

## Global Constraints

- Flutter SDK: ^3.9.2
- 파일명: `snake_case`, 클래스명: `PascalCase`
- import는 `package:chaerok/...` 절대 경로 사용
- `mounted` 체크 후 Navigator/ScaffoldMessenger 호출
- `BuildContext` 를 비동기 간격 너머로 직접 저장하지 않음
- 화면에서 API 직접 호출 금지 — `HealthApi`는 datasource 역할이므로 SplashScreen에서 직접 호출 허용 (controller 없는 단순 startup 흐름)

---

### Task 1: AppStartup 구현 및 main.dart 정리

**Files:**
- Modify: `lib/app/app_startup.dart` (현재 비어 있음)
- Modify: `lib/main.dart`
- Modify: `test/widget_test.dart` (MyApp 참조 제거)

**Interfaces:**
- Produces: `AppStartup.initialize({void Function()? onUnauthorized})` — `Future<void>`, Task 2의 SplashScreen이 의존하지 않음. main.dart만 사용.

- [ ] **Step 1: `app_startup.dart` 구현**

`lib/app/app_startup.dart`를 다음으로 교체한다:

```dart
import 'package:chaerok/core/config/app_secrets.dart';
import 'package:chaerok/core/network/dio_client.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

class AppStartup {
  const AppStartup._();

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

- [ ] **Step 2: `main.dart` 정리**

`lib/main.dart`를 다음으로 교체한다. `MyApp` 래퍼 제거, `AppStartup` 위임, `ChaerokApp` 직접 실행:

```dart
import 'package:chaerok/app/app.dart';
import 'package:chaerok/app/app_startup.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStartup.initialize();
  runApp(const ChaerokApp());
}
```

- [ ] **Step 3: `test/widget_test.dart` 수정**

기존 smoke test는 `MyApp`을 참조하므로 삭제 후 빈 테스트로 교체한다:

```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Smoke test placeholder — integration tests go in integration_test/
}
```

- [ ] **Step 4: 빌드 확인**

```bash
flutter analyze
```

Expected: No errors (warnings 있어도 무방, error 0개)

- [ ] **Step 5: 커밋**

```bash
git add lib/app/app_startup.dart lib/main.dart test/widget_test.dart
git commit -m "feat: AppStartup으로 SDK 초기화 위임, main.dart 정리"
```

---

### Task 2: SplashScreen 구현

**Files:**
- Create: `lib/features/splash/screens/splash_screen.dart`
- Modify: `lib/app/app.dart`

**Interfaces:**
- Consumes:
  - `HealthApi.checkHealth()` — `Future<String>`, 예외 발생 시 실패로 간주
  - `LoginScreen` — `const LoginScreen()` (기존)
- Produces: `SplashScreen` — `StatefulWidget`, `const SplashScreen()`으로 사용

- [ ] **Step 1: SplashScreen 파일 생성**

`lib/features/splash/screens/splash_screen.dart`를 생성한다:

```dart
import 'package:chaerok/data/remote/health_api.dart';
import 'package:chaerok/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await HealthApi.checkHealth();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서버에 연결할 수 없습니다. 일부 기능이 제한될 수 있습니다.'),
          duration: Duration(seconds: 3),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
    }
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '채록',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: `app.dart`에서 home을 SplashScreen으로 변경**

`lib/app/app.dart`를 다음으로 교체한다:

```dart
import 'package:chaerok/core/design_system/chaerok_theme.dart';
import 'package:chaerok/features/splash/screens/splash_screen.dart';
import 'package:flutter/material.dart';

class ChaerokApp extends StatelessWidget {
  const ChaerokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chaerok',
      debugShowCheckedModeBanner: false,
      theme: ChaerokTheme.light,
      home: const SplashScreen(),
    );
  }
}
```

- [ ] **Step 3: 빌드 및 분석 확인**

```bash
flutter analyze
```

Expected: No errors

- [ ] **Step 4: 커밋**

```bash
git add lib/features/splash/screens/splash_screen.dart lib/app/app.dart
git commit -m "feat: SplashScreen 추가 — 앱 시작 시 서버 헬스 체크"
```

---

### Task 3: 동작 검증

**Files:**
- 변경 없음 — 실행 및 수동 검증

- [ ] **Step 1: 정상 케이스 확인 (서버 정상)**

```bash
flutter run
```

Expected: 스플래시 화면(로딩 인디케이터) → 자동으로 LoginScreen 이동. 스낵바 미표시.

- [ ] **Step 2: 실패 케이스 확인 (서버 오프라인 시뮬레이션)**

`lib/data/remote/health_api.dart`의 경로를 임시로 잘못된 URL로 바꾸거나, 디바이스 네트워크를 끄고 실행한다.

Expected: 스플래시 화면 → "서버에 연결할 수 없습니다..." 스낵바 표시 → 1초 후 LoginScreen으로 이동.

- [ ] **Step 3: 최종 커밋 (변경 없으면 생략)**

검증 중 수정사항이 있으면:

```bash
git add <수정된 파일>
git commit -m "fix: 헬스 체크 동작 검증 후 수정"
```
