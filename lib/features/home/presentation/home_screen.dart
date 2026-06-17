import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.provider,
    this.email,
    this.nickname,
  });

  final String provider;
  final String? email;
  final String? nickname;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: const Text('홈', style: ChaerokTypography.titleMedium),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(ChaerokSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: ChaerokColors.primary,
                size: 64,
              ),
              const SizedBox(height: ChaerokSpacing.lg),
              Text('$provider 로그인 성공', style: ChaerokTypography.titleMedium),
              if (nickname != null) ...[
                const SizedBox(height: ChaerokSpacing.sm),
                Text(nickname!, style: ChaerokTypography.bodyLarge),
              ],
              if (email != null) ...[
                const SizedBox(height: ChaerokSpacing.xs),
                Text(
                  email!,
                  style: ChaerokTypography.bodyMedium.copyWith(
                    color: ChaerokColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
