import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/config/app_secrets.dart';
import 'package:chaerok/core/network/token_storage.dart';
import 'package:chaerok/data/remote/health_api.dart';
import 'package:chaerok/features/auth/presentation/login_screen.dart';
import 'package:chaerok/features/home/presentation/main_tab_screen.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _tag = 'SplashScreen';

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      await HealthApi.checkHealth();
    } catch (e, st) {
      log('헬스체크 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('서버에 연결할 수 없습니다. 일부 기능이 제한될 수 있습니다.'),
          duration: Duration(seconds: 3),
        ),
      );
      await Future.delayed(const Duration(seconds: 1));
    }

    final status = await TokenStorage.instance.resolveSession(
      Dio(
        BaseOptions(
          baseUrl: AppSecrets.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 30),
        ),
      ),
    );
    log('세션 상태: $status', name: _tag);

    if (!mounted) return;

    if (status == SessionStatus.networkError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('네트워크 연결을 확인해주세요.'),
          duration: Duration(seconds: 3),
        ),
      );
    }

    final destination = status == SessionStatus.authenticated
        ? const MainTabScreen()
        : const LoginScreen();

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
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
            ChaerokLoadingIndicator(),
          ],
        ),
      ),
    );
  }
}
