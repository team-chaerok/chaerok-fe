import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_deck.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_load_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PlaceListResponse _place(String title) => PlaceListResponse(
  id: title.hashCode,
  title: title,
  address: '충남',
  latitude: 36,
  longitude: 126,
  categoryGroup: 'AT4',
  categoryDetail: '관광지',
  isRepresentative: false,
  source: 'TOUR_API',
);

Map<RegionCode, RegionFilmData> _dataFor(RegionLoadStatus status) => {
  for (final r in RegionCode.values)
    r: (
      status: status,
      places: status == RegionLoadStatus.ready
          ? [_place('${r.displayName} 장소')]
          : const <PlaceListResponse>[],
    ),
};

void main() {
  Widget host({
    required List<RegionCode> deckOrder,
    Map<RegionCode, RegionFilmData>? data,
    ValueChanged<RegionCode>? onOpen,
    ValueChanged<RegionCode>? onRetry,
    ValueChanged<RegionCode>? onExplore,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: RegionFilmDeck(
          deckOrder: deckOrder,
          dataByRegion: data ?? _dataFor(RegionLoadStatus.ready),
          onOpen: onOpen ?? (_) {},
          onRetry: onRetry ?? (_) {},
          onExploreRegionRequested: onExplore ?? (_) {},
        ),
      ),
    );
  }

  testWidgets('맨 뒤가 열린 카드, 나머지는 겹친 탭', (tester) async {
    await tester.pumpWidget(host(deckOrder: RegionCode.values.toList()));
    await tester.pumpAndSettle();

    expect(find.text('공주 필름롤'), findsOneWidget);
    expect(find.text('부여 필름롤'), findsOneWidget);
    expect(find.text('서산 필름롤'), findsOneWidget);
    // 열린 카드(예산)의 인트로.
    expect(find.text('예산'), findsOneWidget);
    expect(find.text('Y E S A N'), findsOneWidget);
  });

  testWidgets('겹친 탭을 누르면 onOpen(해당 지역)을 호출한다', (tester) async {
    RegionCode? opened;
    await tester.pumpWidget(
      host(deckOrder: RegionCode.values.toList(), onOpen: (r) => opened = r),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('서산 필름롤'));
    expect(opened, RegionCode.seosan);
  });

  testWidgets('열린 카드의 탭은 onOpen을 호출하지 않는다', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(deckOrder: RegionCode.values.toList(), onOpen: (_) => calls++),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('예산 필름롤'), warnIfMissed: false);
    expect(calls, 0);
  });

  testWidgets('loading 상태면 로딩 인디케이터', (tester) async {
    await tester.pumpWidget(
      host(
        deckOrder: RegionCode.values.toList(),
        data: _dataFor(RegionLoadStatus.loading),
      ),
    );
    await tester.pump();
    expect(find.byType(ChaerokLoadingIndicator), findsOneWidget);
  });

  testWidgets('error 상태에서 다시 시도 → onRetry(열린 지역)', (tester) async {
    RegionCode? retried;
    await tester.pumpWidget(
      host(
        deckOrder: RegionCode.values.toList(),
        data: _dataFor(RegionLoadStatus.error),
        onRetry: (r) => retried = r,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('다시 시도'));
    expect(retried, RegionCode.yesan);
  });

  testWidgets('deckOrder가 바뀌면 전환 애니메이션이 재생되고 새 카드가 열린다', (tester) async {
    var order = RegionCode.values.toList();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => RegionFilmDeck(
              deckOrder: order,
              dataByRegion: _dataFor(RegionLoadStatus.ready),
              onOpen: (r) => setState(() {
                final next = [...order];
                final i = next.indexOf(r);
                next[i] = next.last;
                next[next.length - 1] = r;
                order = next;
              }),
              onRetry: (_) {},
              onExploreRegionRequested: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('예산'), findsOneWidget); // 예산 인트로 = 열림

    await tester.tap(find.text('부여 필름롤'));
    await tester.pump(); // 스왑 → 애니메이션 시작
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.hasRunningAnimations, isTrue); // 즉시 스왑이 아니라 전환 중

    await tester.pumpAndSettle();
    expect(find.text('부여'), findsOneWidget); // 부여 열림
    expect(find.text('예산'), findsNothing); // 예산은 탭만
    expect(find.text('예산 필름롤'), findsOneWidget); // 겹친 탭으로 내려옴
  });
}
