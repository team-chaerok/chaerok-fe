import 'package:chaerok/app/app.dart';
import 'package:chaerok/app/app_startup.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 앱은 세로 전용이다. 촬영 화면(VisitCaptureScreen)만 진입 시 스스로 가로로
  // 전환했다가 이탈할 때 이 방향으로 되돌린다.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await AppStartup.initialize();
  runApp(const ChaerokApp());
}
