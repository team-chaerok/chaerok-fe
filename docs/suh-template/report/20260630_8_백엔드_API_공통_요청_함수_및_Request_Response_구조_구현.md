# [Network] 백엔드 API 공통 요청 함수 및 Request/Response 구조 구현

> Issue: [#8](https://github.com/team-chaerok/chaerok-fe/issues/8)

## 개요

Dio 기반 HTTP 클라이언트 공통 계층을 신규 구축했다. `DioClient` 싱글톤을 통해 모든 API 호출을 통일된 방식으로 처리하고, `AuthInterceptor`로 JWT 토큰을 자동 주입하며 401 만료 시 자동 재발급한다. 응답은 `ApiResponse<T>`, 오류는 `ApiError`로 일관되게 반환된다.

---

## 변경 사항

### 의존성 추가

- `pubspec.yaml`: `dio ^5.8.0`, `flutter_secure_storage ^9.2.4` 추가

### 설정

- `lib/core/config/app_secrets.dart`: `baseUrl` 상수 추가 (`https://api.chaerok.com` — 실제 URL 확정 후 교체 필요)

### 네트워크 계층 신규 추가

- `lib/core/network/dio_client.dart`: Dio 싱글톤 클라이언트. `get / post / put / delete` 공통 메서드 제공
- `lib/core/network/interceptors/auth_interceptor.dart`: `flutter_secure_storage`에서 access token 읽어 `Authorization: Bearer` 헤더 자동 주입. 401 응답 시 refresh token으로 재발급 후 원래 요청 재시도
- `lib/core/network/interceptors/error_interceptor.dart`: 타임아웃, 네트워크 단절, HTTP 오류를 `ApiError`로 변환

### 모델 신규 추가

- `lib/data/models/api_response.dart`: 공통 응답 래퍼 `ApiResponse<T>`. 제네릭 `fromJson` 지원
- `lib/data/models/api_error.dart`: 에러 정보 모델 `ApiError`. `Exception` 구현

---

## 주요 구현 내용

### DioClient 초기화 및 사용법

```dart
// main.dart — 앱 시작 시 1회 초기화 (로그아웃 콜백 연결)
DioClient.init(
  onUnauthorized: () {
    // 로그인 화면으로 이동
    Navigator.pushReplacementNamed(context, '/login');
  },
);

// 서비스 레이어에서 호출
final response = await DioClient.instance.get<User>(
  '/users/me',
  fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
);

if (response.success && response.data != null) {
  final user = response.data!;
}
```

### POST 요청

```dart
final response = await DioClient.instance.post<TokenDto>(
  '/auth/login',
  data: {'email': email, 'password': password},
  fromJson: (json) => TokenDto.fromJson(json as Map<String, dynamic>),
);
```

### 에러 처리

```dart
try {
  final response = await DioClient.instance.get<List<Feed>>('/feeds');
} on DioException catch (e) {
  final error = e.error as ApiError?;
  print(error?.message); // "네트워크 연결을 확인해주세요." 등
}
```

### 토큰 저장 (로그인 성공 후)

```dart
const storage = FlutterSecureStorage();
await storage.write(key: 'access_token', value: accessToken);
await storage.write(key: 'refresh_token', value: refreshToken);
// 이후 모든 요청에 자동으로 Authorization 헤더 주입됨
```

### 인터셉터 체인

```
요청 흐름: AuthInterceptor(토큰 주입) → 서버
응답 흐름: 서버 → ErrorInterceptor(에러 변환) → DioClient
401 처리:  AuthInterceptor → refresh 요청 → 새 토큰 저장 → 원래 요청 재시도
```

401 동시 요청 충돌은 `Completer`로 방지 — 첫 번째 요청이 refresh 중이면 나머지는 대기 후 새 토큰으로 재시도.

---

## 주의사항

| 항목 | 내용 |
|------|------|
| `baseUrl` 교체 | `lib/core/config/app_secrets.dart`의 `baseUrl`을 실제 서버 URL로 교체 필요 |
| `/auth/refresh` 엔드포인트 | 백엔드 refresh 경로 확정 후 `auth_interceptor.dart:59` 수정 |
| Response JSON 구조 | `success`, `data`, `message` 키 기반으로 파싱 — 백엔드 스펙 변경 시 `ApiResponse.fromJson` 조정 |
| `DioClient.init()` 누락 | `init()` 없이 `instance` 접근 시 `onUnauthorized` 콜백 없이 동작 (기본 허용, 단 로그아웃 미처리) |
