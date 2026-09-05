import 'dart:async';

import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart';
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

void main() {
  Widget host({
    RegionIdResolver? resolver,
    PlacesFetcher? fetcher,
    ValueChanged<RegionCode>? onExplore,
  }) {
    return MaterialApp(
      home: OutOfServiceHomeView(
        onExploreRegionRequested: onExplore ?? (_) {},
        regionIdResolver: resolver ?? (region) async => region.index + 1,
        placesFetcher: fetcher ?? (regionId) async => [_place('장소$regionId')],
      ),
    );
  }

  testWidgets('기본 선택 지역은 예산이고, 로드되면 상세가 예산으로 렌더', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.text('예산'), findsOneWidget);
    expect(find.text('Y E S A N'), findsOneWidget);
  });

  testWidgets('서산 헤더 탭 시 상세가 서산으로 전환', (tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('서산 필름롤'));
    await tester.pumpAndSettle();
    expect(find.text('서산'), findsOneWidget);
    expect(find.text('S E O S A N'), findsOneWidget);
  });

  testWidgets('fetcher가 느리면 로딩 인디케이터', (tester) async {
    final completer = Completer<List<PlaceListResponse>>();
    await tester.pumpWidget(host(fetcher: (_) => completer.future));
    await tester.pump();
    expect(find.byType(ChaerokLoadingIndicator), findsOneWidget);
    completer.complete([_place('a')]);
    await tester.pumpAndSettle();
  });

  testWidgets('fetcher가 throw하면 에러 상태', (tester) async {
    await tester.pumpWidget(
      host(fetcher: (_) async => throw Exception('boom')),
    );
    await tester.pumpAndSettle();
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('한 번 로드한 지역은 재방문 시 fetcher를 다시 부르지 않는다', (tester) async {
    final calls = <int>[];
    await tester.pumpWidget(
      host(
        fetcher: (id) async {
          calls.add(id);
          return [_place('a')];
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('서산 필름롤'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('예산 필름롤'));
    await tester.pumpAndSettle();
    // 예산(4) 1회 + 서산(3) 1회 = 2회, 예산 재방문 시 추가 호출 없음
    expect(calls.length, 2);
  });

  testWidgets('배너/전체보기는 onExploreRegionRequested(선택지역) 호출', (tester) async {
    RegionCode? got;
    await tester.pumpWidget(host(onExplore: (r) => got = r));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('전체보기'));
    await tester.tap(find.text('전체보기'));
    expect(got, RegionCode.yesan);
  });
}
