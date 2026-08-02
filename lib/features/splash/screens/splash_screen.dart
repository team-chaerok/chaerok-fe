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

  // 헬스체크/세션 검증 각 단계에 자체 타임아웃이 있지만, 알려지지 않은 원인으로
  // 어느 한 단계가 예외 없이 멈추는 경우까지 대비한 전체 초기화 상한선.
  static const _initTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  Future<void> _init() async {
    try {
      await _runInitFlow().timeout(_initTimeout);
    } on TimeoutException catch (e, st) {
      log(
        '초기화가 시간 내에 끝나지 않음 - 로그인 화면으로 이동',
        name: _tag,
        error: e,
        stackTrace: st,
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  Future<void> _runInitFlow() async {
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
