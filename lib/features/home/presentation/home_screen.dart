import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text('홈', style: ChaerokTypography.titleMedium),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(ChaerokSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: ChaerokColors.primary, size: 64),
              SizedBox(height: ChaerokSpacing.lg),
              Text('로그인 성공', style: ChaerokTypography.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}
