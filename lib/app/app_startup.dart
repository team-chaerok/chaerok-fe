import 'package:chaerok/core/config/app_secrets.dart';
import 'package:chaerok/core/network/dio_client.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:kakao_map_sdk/kakao_map_sdk.dart';

class AppStartup {
  const AppStartup._();

  static Future<void> initialize({void Function()? onUnauthorized}) async {
    KakaoSdk.init(nativeAppKey: AppSecrets.kakaoNativeAppKey);
    await KakaoMapSdk.instance.initialize(AppSecrets.kakaoNativeAppKey);
    await GoogleSignIn.instance.initialize(
      clientId: AppSecrets.googleClientId,
      serverClientId: AppSecrets.googleServerClientId,
    );
    DioClient.init(onUnauthorized: onUnauthorized);
  }
}
