import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key, required this.signupToken});

  final String signupToken;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text('회원가입', style: ChaerokTypography.titleMedium),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(ChaerokSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_add, color: ChaerokColors.primary, size: 64),
              SizedBox(height: ChaerokSpacing.lg),
              Text('회원가입 화면', style: ChaerokTypography.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
