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

  /// 버튼 왼쪽 가장자리에서 로고까지의 간격 (Figma: x=110, 버튼 x=24)
  static const double _logoLeftInset = 86;

  /// 로고 크기 (Figma 22x22)
  static const double _logoSize = 22;

  /// Figma 시안 기준 버튼 모서리 반경 (디자인 토큰에 10 값이 없어 상수로 관리)
  static const double _borderRadius = 10;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Stack(
        children: [
          // 버튼 배경 + 정중앙 정렬된 라벨.
          // 좌우 대칭 padding(로고 영역 폭)을 줘서 라벨이 로고와 겹치지 않도록 제한하고,
          // 공간이 부족하면 말줄임(...) 처리한다.
          Positioned.fill(
            child: ElevatedButton(
              onPressed: isEnabled && !isLoading ? onTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                elevation: 0,
                side: side,
                padding: const EdgeInsets.symmetric(
                  horizontal: _logoLeftInset + _logoSize,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_borderRadius),
                ),
              ),
              child: isLoading
                  ? ChaerokLoadingIndicator(
                      color: foregroundColor,
                      size: 20,
                      strokeWidth: 2,
                    )
                  : Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: ChaerokTypography.pretendardFontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
            ),
          ),
          // 로고: 왼쪽에 고정, 세로 중앙 정렬 (탭 이벤트는 버튼으로 통과)
          if (!isLoading)
            Positioned(
              left: _logoLeftInset,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Center(
                  child: SvgPicture.asset(
                    logo,
                    width: _logoSize,
                    height: _logoSize,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
