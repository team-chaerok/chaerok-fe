import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/film_tab.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_card.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_load_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';

/// 지역별 필름롤 카드 한 장의 데이터(로드 상태 + 장소 목록).
typedef RegionFilmData = ({
  RegionLoadStatus status,
  List<PlaceListResponse> places,
});

/// 충남 외 지역 홈 상단의 "필름롤" 스택. [deckOrder]의 맨 뒤 원소가 열린 카드이고,
/// 나머지는 위에 탭만 겹쳐 쌓인다. 겹친 탭을 누르면 [onOpen]으로 전환을 요청하며,
/// 부모는 그 지역과 직전에 열려 있던 지역의 덱 순서를 스위치한다.
class RegionFilmDeck extends StatelessWidget {
  const RegionFilmDeck({
    super.key,
    required this.deckOrder,
    required this.dataByRegion,
    required this.onOpen,
    required this.onRetry,
    required this.onExploreRegionRequested,
  });

  final List<RegionCode> deckOrder;
  final Map<RegionCode, RegionFilmData> dataByRegion;
  final ValueChanged<RegionCode> onOpen;
  final ValueChanged<RegionCode> onRetry;
  final ValueChanged<RegionCode> onExploreRegionRequested;

  /// 겹친 탭 사이 간격. 살짝 띄워 층을 구분한다. 토큰 없음.
  static const double _peekGap = 2;

  @override
  Widget build(BuildContext context) {
    final open = deckOrder.last;
    final peeks = deckOrder.sublist(0, deckOrder.length - 1);
    final data = dataByRegion[open];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, region) in peeks.indexed) ...[
          if (index != 0) const SizedBox(height: _peekGap),
          FilmTab(
            label: region.filmStripLabel,
            opened: false,
            onTap: () => onOpen(region),
          ),
        ],
        const SizedBox(height: _peekGap),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            layoutBuilder: (currentChild, previousChildren) => Stack(
              fit: StackFit.expand,
              children: [
                ...previousChildren,
                if (currentChild != null) currentChild,
              ],
            ),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: RegionFilmCard(
              key: ValueKey<RegionCode>(open),
              region: open,
              status: data?.status ?? RegionLoadStatus.loading,
              places: data?.places ?? const <PlaceListResponse>[],
              onRetry: () => onRetry(open),
              onExploreRegionRequested: onExploreRegionRequested,
            ),
          ),
        ),
      ],
    );
  }
}
