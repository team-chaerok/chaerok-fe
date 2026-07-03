import 'package:chaerok/core/design_system/chaerok_theme.dart';
import 'package:chaerok/features/splash/screens/splash_screen.dart';
import 'package:flutter/material.dart';

/// MaterialApp, 테마, 라우터 연결
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
