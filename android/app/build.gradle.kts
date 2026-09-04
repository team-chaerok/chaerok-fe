import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    val file = rootProject.file("local.properties")
    if (file.exists()) load(file.inputStream())
}

// 출시 서명 정보. `android/key.properties`(gitignore, 커밋 금지)에서 읽는다.
// 파일이 없으면(다른 개발자의 `flutter run --release` 등) debug 키로 폴백한다.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

// `storeFile` 경로는 `android/`(rootProject) 기준으로 해석한다 — key.properties.example과 일치.
val releaseStoreFile = keystoreProperties.getProperty("storeFile")
    ?.takeIf { it.isNotBlank() }
    ?.let { rootProject.file(it) }

// 릴리스 서명은 4개 속성이 모두 채워지고 키스토어 파일이 실제로 존재할 때만 사용한다.
// 하나라도 빠지면 debug 키로 폴백해 "debug 서명" 산출물이 조용히 나가는 것을 막는다.
val hasReleaseKeystore = releaseStoreFile?.isFile == true &&
    !keystoreProperties.getProperty("storePassword").isNullOrBlank() &&
    !keystoreProperties.getProperty("keyAlias").isNullOrBlank() &&
    !keystoreProperties.getProperty("keyPassword").isNullOrBlank()

if (keystorePropertiesFile.exists() && !hasReleaseKeystore) {
    logger.warn(
        "key.properties가 있지만 storeFile/storePassword/keyAlias/keyPassword 중 " +
            "일부가 비었거나 키스토어 파일이 없어 debug 키로 폴백합니다."
    )
}

android {
    namespace = "com.leebakju.chaerok"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.leebakju.chaerok"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["kakaoNativeAppKey"] = localProperties.getProperty("kakao.nativeAppKey", "")
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = releaseStoreFile
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            // key.properties가 있으면 출시 키로 서명, 없으면 debug 키로 폴백
            // (다른 개발자가 키스토어 없이 `flutter run --release`를 돌릴 수 있게).
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
