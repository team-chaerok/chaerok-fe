import 'dart:ui' as ui;

import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_palette.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 필름롤 카드 상단 오른쪽에 세로로 깔리는 지역 대표 사진.
/// [RegionCode.filmFilterAsset] 필름 질감(그레인·라이트 리크)을
/// [BlendMode.overlay]로 겹쳐 지역별 색감을 낸다.
/// 사진 에셋([RegionCode.filmPhotoAsset])이 아직 없으면 [RegionCode.filmTabColor]
/// 블록으로 폴백하므로, 파일을 나중에 넣어도 레이아웃은 지금 그대로다. 필터
/// 에셋만 없을 때는 필터 없이 사진만 보여준다.
class RegionFilmPhoto extends StatelessWidget {
  const RegionFilmPhoto({super.key, required this.region});

  final RegionCode region;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(ChaerokRadius.lg),
      ),
      child: FutureBuilder<ui.Image?>(
        future: _DecodedAssetCache.load(region.filmPhotoAsset),
        builder: (context, photoSnapshot) {
          final photo = photoSnapshot.data;
          if (photo == null) {
            // 로딩 중이거나 사진 자체가 없으면 지역색 블록으로 폴백.
            return ColoredBox(color: region.filmTabColor);
          }
          return FutureBuilder<ui.Image?>(
            future: _DecodedAssetCache.load(region.filmFilterAsset),
            builder: (context, filterSnapshot) {
              return CustomPaint(
                size: Size.infinite,
                painter: _FilmFilterPainter(
                  photo: photo,
                  filter: filterSnapshot.data,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// 사진 위에 필터를 [BlendMode.overlay]로 겹쳐 그리는 페인터.
/// 둘 다 [BoxFit.cover]로 캔버스를 채운다.
class _FilmFilterPainter extends CustomPainter {
  const _FilmFilterPainter({required this.photo, required this.filter});

  final ui.Image photo;
  final ui.Image? filter;

  /// 필터 레이어 불투명도. 값을 바꾸려면 여기만 고치면 된다.
  static const double _filterOpacity = 0.5;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    _drawCover(canvas, photo, rect);
    if (filter != null) {
      _drawCover(
        canvas,
        filter!,
        rect,
        Paint()
          ..blendMode = BlendMode.overlay
          ..color = Colors.white.withValues(alpha: _filterOpacity),
      );
    }
  }

  void _drawCover(Canvas canvas, ui.Image image, Rect dst, [Paint? paint]) {
    final srcSize = Size(image.width.toDouble(), image.height.toDouble());
    final fitted = applyBoxFit(BoxFit.cover, srcSize, dst.size);
    final srcRect = Alignment.center.inscribe(
      fitted.source,
      Offset.zero & srcSize,
    );
    final dstRect = Alignment.center.inscribe(fitted.destination, dst);
    canvas.drawImageRect(image, srcRect, dstRect, paint ?? Paint());
  }

  @override
  bool shouldRepaint(covariant _FilmFilterPainter oldDelegate) =>
      oldDelegate.photo != photo || oldDelegate.filter != filter;
}

/// 디코딩한 [ui.Image]를 에셋 경로별로 캐싱해 재빌드마다 다시 디코딩하지
/// 않도록 한다. 필름롤 덱은 4개 지역 카드가 동시에 떠 있어 캐시가 필요하다.
class _DecodedAssetCache {
  _DecodedAssetCache._();

  static final Map<String, Future<ui.Image?>> _cache = {};

  static Future<ui.Image?> load(String asset) {
    return _cache.putIfAbsent(asset, () async {
      try {
        final data = await rootBundle.load(asset);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        return frame.image;
      } catch (_) {
        // 에셋이 아직 없거나 디코딩 실패 — 호출부가 폴백을 그린다.
        return null;
      }
    });
  }
}
