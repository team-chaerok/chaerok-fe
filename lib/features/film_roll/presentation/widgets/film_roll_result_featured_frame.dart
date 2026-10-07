import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_shadows.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:flutter/material.dart';

/// 현상 결과 화면 가운데의 대표 사진 필름 칸. 검은 필름 띠 위아래에 스프라켓
/// 구멍을 두르고, 위 띠에는 [topLabel](예: "CHAEROK · SEOSAN"), 아래 띠에는
/// [dateLabel]과 [frameLabel](현재 칸 번호)을 새긴다. [child]에는 사진을 넣는다.
class FilmRollResultFeaturedFrame extends StatelessWidget {
  const FilmRollResultFeaturedFrame({
    super.key,
    required this.child,
    required this.topLabel,
    this.dateLabel,
    this.frameLabel,
  });

  /// 사진 칸의 가로세로 비율. 휴대폰으로 세워 찍은 사진에 맞춘 세로형이다.
  static const double photoAspectRatio = 4 / 5;

  static const double _frameRadius = 6;
  static const double _photoRadius = 4;
  static const double _edgeHeight = 28;

  final Widget child;
  final String topLabel;
  final String? dateLabel;
  final String? frameLabel;

  static final TextStyle _labelStyle = ChaerokTypography.caption.copyWith(
    color: Colors.white,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.6,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  @override
  Widget build(BuildContext context) {
    final dateLabel = this.dateLabel;
    final frameLabel = this.frameLabel;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ChaerokColors.cameraBlack,
        borderRadius: BorderRadius.circular(_frameRadius),
        boxShadow: ChaerokShadows.floating,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.sm),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEdge([Text(topLabel, style: _labelStyle)], const []),
            ClipRRect(
              borderRadius: BorderRadius.circular(_photoRadius),
              child: AspectRatio(aspectRatio: photoAspectRatio, child: child),
            ),
            _buildEdge(
              [if (dateLabel != null) Text(dateLabel, style: _labelStyle)],
              [if (frameLabel != null) Text(frameLabel, style: _labelStyle)],
            ),
          ],
        ),
      ),
    );
  }

  /// 필름 띠 한 줄. 양 끝 라벨 사이를 스프라켓 구멍으로 채운다.
  Widget _buildEdge(List<Widget> leading, List<Widget> trailing) {
    return SizedBox(
      height: _edgeHeight,
      child: Row(
        children: [
          for (final label in leading) ...[
            label,
            const SizedBox(width: ChaerokSpacing.sm),
          ],
          const Expanded(
            child: FilmRollResultSprocketHoles(
              holeWidth: 9,
              holeHeight: 11,
              pitch: 22,
            ),
          ),
          for (final label in trailing) ...[
            const SizedBox(width: ChaerokSpacing.sm),
            label,
          ],
        ],
      ),
    );
  }
}

/// 필름 띠의 스프라켓 구멍 줄. 가용 너비에 맞춰 개수를 계산해 고르게 채운다.
/// 대표 사진 틀과 오늘의 사진 스트립이 크기만 바꿔 함께 쓴다.
class FilmRollResultSprocketHoles extends StatelessWidget {
  const FilmRollResultSprocketHoles({
    super.key,
    required this.holeWidth,
    required this.holeHeight,
    required this.pitch,
  });

  final double holeWidth;
  final double holeHeight;

  /// 구멍 하나가 차지하는 간격(구멍 너비 + 사이 여백).
  final double pitch;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final holeCount = (constraints.maxWidth / pitch).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < holeCount; i++)
              Container(
                width: holeWidth,
                height: holeHeight,
                decoration: BoxDecoration(
                  color: ChaerokColors.background,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        );
      },
    );
  }
}
