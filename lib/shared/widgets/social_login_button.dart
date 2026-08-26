import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

/// SocialLoginButton 위젯은 소셜 로그인 버튼을 나타내는 위젯
class SocialLoginButton extends StatelessWidget {
  const SocialLoginButton({
    super.key,
    required this.logo,
    required this.label,
    required this.onTap,
    required this.backgroundColor,
    required this.foregroundColor,
    this.side,
    this.isLoading = false,
    this.isEnabled = true,
  });

  final String logo;
  final String label;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color foregroundColor;
  final BorderSide? side;
  final bool isLoading;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isEnabled && !isLoading ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: backgroundColor,
              foregroundColor: foregroundColor,
              elevation: 0,
              side: side,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ChaerokRadius.md),
              ),
            ),
            child: isLoading
                ? ChaerokLoadingIndicator(
                    color: foregroundColor,
                    size: 20,
                    strokeWidth: 2,
                  )
                : Text(label, style: ChaerokTypography.labelLarge),
          ),
        ),
        Positioned(
          left: 86,
          top: 0,
          bottom: 0,
          child: SvgPicture.asset(logo, width: 22, height: 22),
        ),
      ],
    );
  }
}
