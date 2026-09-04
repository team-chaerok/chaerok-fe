import 'dart:async';

import 'package:chaerok/features/auth/presentation/signup_navigation.dart';
import 'package:chaerok/features/location/presentation/location_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('회원가입 성공 흐름은 위치 인증 화면으로 전환된다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => unawaited(
                  SignupNavigation.toMainViaLocationVerification(context),
                ),
                child: const Text('회원가입 완료'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('회원가입 완료'));
    await tester.pump(); // 라우트 push 시작
    await tester.pump(const Duration(milliseconds: 16)); // 전환 첫 프레임

    expect(find.byType(LocationVerificationScreen), findsOneWidget);
  });
}
