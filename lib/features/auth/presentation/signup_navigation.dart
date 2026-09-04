import 'package:chaerok/features/home/presentation/main_tab_screen.dart';
import 'package:chaerok/features/location/presentation/location_verification_screen.dart';
import 'package:flutter/material.dart';

/// 회원가입 성공 직후의 화면 전환을 담당한다.
///
/// 위치 인증 화면을 먼저 띄우고, 인증 성공·실패·건너뛰기(뒤로가기) 어느
/// 경우든 화면이 닫히면 [MainTabScreen]으로 진입한다. 인증 성공 시
/// [LocationVerificationResult.sessionCache]에 결과가 저장되므로 홈 대시보드가
/// 이를 재사용한다.
class SignupNavigation {
  const SignupNavigation._();

  static Future<void> toMainViaLocationVerification(
    BuildContext context,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const LocationVerificationScreen(),
      ),
    );
    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainTabScreen()),
    );
  }
}
