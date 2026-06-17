import 'package:chaerok/app/app.dart';
import 'package:chaerok/core/config/app_secrets.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  KakaoSdk.init(nativeAppKey: AppSecrets.kakaoNativeAppKey);
  await GoogleSignIn.instance.initialize(
    clientId: AppSecrets.googleClientId,
    serverClientId: AppSecrets.googleServerClientId,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const ChaerokApp(),
    );
  }
}
