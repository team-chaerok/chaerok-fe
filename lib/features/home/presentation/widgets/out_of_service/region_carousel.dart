import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/place_image.dart';
import 'package:flutter/material.dart';

/// 선택 지역 장소 이미지 캐러셀. firstImageUrl이 있는 장소를 최대 5개까지
/// 페이지로 보여주고, 하나도 없으면 mood 플레이스홀더 1장을 보여준다.
class RegionCarousel extends StatefulWidget {
  const RegionCarousel({super.key, required this.places});

  final List<PlaceListResponse> places;

  static const int maxPages = 5;
  static const double _height = 200; // Figma 근사. 토큰 없음.

  @override
  State<RegionCarousel> createState() => _RegionCarouselState();
}

class _RegionCarouselState extends State<RegionCarousel> {
  final PageController _controller = PageController();
  int _index = 0;

  List<PlaceListResponse> get _withImages => widget.places
      .where((p) => (p.firstImageUrl ?? '').trim().isNotEmpty)
      .take(RegionCarousel.maxPages)
      .toList();

  List<String?> get _imageUrls =>
      _withImages.map((p) => p.firstImageUrl).toList();

  @override
  void didUpdateWidget(covariant RegionCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldUrls = oldWidget.places
        .where((p) => (p.firstImageUrl ?? '').trim().isNotEmpty)
        .take(RegionCarousel.maxPages)
        .map((p) => p.firstImageUrl)
        .toList();
    final newUrls = _imageUrls;
    final changed =
        oldUrls.length != newUrls.length ||
        List.generate(
          newUrls.length,
          (i) => oldUrls[i] != newUrls[i],
        ).any((e) => e);
    if (changed) {
      _index = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _withImages;
    final pageCount = items.isEmpty ? 1 : items.length;
    final safeIndex = _index >= pageCount ? pageCount - 1 : _index;
    const fallbackMood = PlacePlaceholderMood.forest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.md),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ChaerokRadius.lg),
        child: SizedBox(
          height: RegionCarousel._height,
          child: Stack(
            children: [
              PageView.builder(
                controller: _controller,
                itemCount: pageCount,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) {
                  if (items.isEmpty) {
                    return const PlaceImagePlaceholder(mood: fallbackMood);
                  }
                  final place = items[i];
                  return PlaceImage(
                    imageUrl: place.firstImageUrl,
                    mood: PlacePlaceholderMood
                        .values[i % PlacePlaceholderMood.values.length],
                  );
                },
              ),
              Positioned(
                right: ChaerokSpacing.sm,
                bottom: ChaerokSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChaerokSpacing.xs,
                    vertical: 2, // Figma 뱃지 세로 패딩. 토큰 없음.
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5), // 스크림.
                    borderRadius: BorderRadius.circular(ChaerokRadius.sm),
                  ),
                  child: Text(
                    '${safeIndex + 1}/$pageCount',
                    style: ChaerokTypography.caption.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
