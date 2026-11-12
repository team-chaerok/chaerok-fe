# Kakao Map SDK v2 — 네이티브(C++) 엔진이 JNI로 Java 클래스/메서드를 이름으로
# 찾으므로 R8이 이름을 바꾸거나 제거하면 지도 첫 로드 시 프로세스가 종료된다.
# (카카오맵 Android SDK 공식 가이드의 ProGuard 규칙)
-keep class com.kakao.vectormap.** { *; }
-keep interface com.kakao.vectormap.** { *; }

# Kakao SDK(로그인) — 응답 모델을 리플렉션으로 직렬화한다.
-keep class com.kakao.sdk.** { *; }

# Google 로그인(Credential Manager + Google ID) — 공급자를 리플렉션으로 로드한다.
-if class androidx.credentials.CredentialManager
-keep class androidx.credentials.playservices.** { *; }
-keep class com.google.android.libraries.identity.googleid.** { *; }
