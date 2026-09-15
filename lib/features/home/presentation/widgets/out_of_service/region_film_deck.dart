import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/widgets/folder_deck/folder_card_deck.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_card.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_load_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';

/// 지역별 필름롤 카드 한 장의 데이터(로드 상태 + 장소 목록).
typedef RegionFilmData = ({
  RegionLoadStatus status,
  List<PlaceListResponse> places,
});

/// 충남 외 지역 홈 상단의 "필름롤" 스택. 쌓임·전환 애니메이션은 공통
/// [FolderCardDeck]에 위임하고, 이 위젯은 지역 데이터를 [RegionFilmCard]로
/// 변환하는 얇은 어댑터다.
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

  @override
  Widget build(BuildContext context) {
    return FolderCardDeck<RegionCode>(
      deckOrder: deckOrder,
      onOpen: onOpen,
      cardBuilder: (context, region, opened) => RegionFilmCard(
        region: region,
        status: dataByRegion[region]?.status ?? RegionLoadStatus.loading,
        places: dataByRegion[region]?.places ?? const <PlaceListResponse>[],
        onRetry: () => onRetry(region),
        onExploreRegionRequested: onExploreRegionRequested,
        opened: opened,
      ),
    );
  }
}
