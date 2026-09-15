import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/folder_card_shape.dart';
import 'package:flutter/material.dart';

/// 폴더 탭 카드 한 장의 틀(클리핑+그림자+탭 라벨+열림/닫힘 분기)만 담당하는
/// 범용 위젯. 색·라벨·닫힘 미리보기·열림 본문은 전부 파라미터로 받으므로,
/// 지역별 홈의 `RegionFilmCard`와 충남 홈의 카드가 이 틀 하나를 공유한다.
/// 원래 `RegionFilmCard`에 있던 클리핑/그림자/라벨 배치를 값 변경 없이 옮긴 것이다.
class FolderCard extends StatelessWidget {
  const FolderCard({
    super.key,
    required this.color,
    required this.label,
    required this.opened,
    required this.closedPreview,
    required this.openedBody,
    this.labelColor,
  });

  /// 폴더 탭 배경색.
  final Color color;

  /// 탭(왼쪽 위)에 얹는 라벨.
  final String label;

  /// 라벨 색을 강제 지정한다. null이면 기존처럼 열림 흰색/닫힘 흰색 70%를 쓴다.
  final Color? labelColor;

  /// 스택 맨 앞(열린) 카드인지. false면 본문 대신 [closedPreview]만 얹는다.
  final bool opened;

  /// 닫혀 있을 때 본문 오른쪽 위에 얹는 미리보기 위젯(예: 지역 대표 사진).
  final Widget closedPreview;

  /// 열렸을 때 탭 아래 전체를 채우는 본문 위젯.
  final Widget openedBody;

  /// 닫힌 카드의 미리보기 자리 크기. 폴더 탭이 튀어나오는 높이
  /// ([FolderCardClipper.cardTop]) 아래, 즉 본문 영역에 둔다. 토큰 없음.
  static const double previewWidth = 150;
  static const double previewHeight = 80;

  /// 탭 라벨 위치. 토큰 없음.
  static const double _labelTop = 6;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FolderCardShadowPainter(elevation: opened ? 8 : 3),
      child: ClipPath(
        clipper: const FolderCardClipper(),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: color),
            if (opened)
              Positioned(
                top: FolderCardClipper.cardTop,
                left: 0,
                right: 0,
                bottom: 0,
                child: openedBody,
              )
            else
              Positioned(
                top: FolderCardClipper.cardTop,
                right: 0,
                width: previewWidth,
                height: previewHeight,
                child: closedPreview,
              ),
            Positioned(
              left: ChaerokSpacing.md,
              top: _labelTop,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: ChaerokTypography.jeongnimsajiFontFamily,
                  fontWeight: FontWeight.w500,
                  fontSize: 16, // Figma 근사. 토큰 없음.
                  color: labelColor ?? (opened ? Colors.white : Colors.white70),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
