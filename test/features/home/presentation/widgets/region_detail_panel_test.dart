import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/recommended_course_banner.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_carousel.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_detail_panel.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_place_strip.dart';
import 'package:chaerok/features/home/presentation/widgets/place_image.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

PlaceListResponse _place(String title, {String? image}) => PlaceListResponse(
  id: title.hashCode,
  title: title,
  address: '충남 어딘가',
  latitude: 36.0,
  longitude: 126.0,
  categoryGroup: 'AT4',
  categoryDetail: '관광지',
  isRepresentative: false,
  source: 'TOUR_API',
  firstImageUrl: image,
);

void main() {
  testWidgets('RegionCarousel: 이미지 없는 장소만 있으면 플레이스홀더 1장 + 1/1 뱃지', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegionCarousel(places: [_place('a'), _place('b')]),
        ),
      ),
    );
    expect(find.byType(PlaceImagePlaceholder), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('RegionCarousel: 이미지 있는 장소는 최대 5장까지 페이지', (tester) async {
    final places = [
      for (var i = 0; i < 7; i++) _place('p$i', image: 'http://x/$i.jpg'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RegionCarousel(places: places)),
      ),
    );
    expect(find.text('1/5'), findsOneWidget);
  });

  testWidgets('RegionCarousel: places가 바뀌면 인덱스를 0으로 리셋한다', (tester) async {
    final regionA = [
      for (var i = 0; i < 5; i++) _place('a$i', image: 'http://x/a$i.jpg'),
    ];
    final regionB = [
      for (var i = 0; i < 2; i++) _place('b$i', image: 'http://x/b$i.jpg'),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RegionCarousel(places: regionA)),
      ),
    );
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-600, 0));
    await tester.pumpAndSettle();
    expect(find.text('3/5'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: RegionCarousel(places: regionB)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('1/2'), findsOneWidget);
    expect(find.text('3/2'), findsNothing);
  });

  testWidgets('RecommendedCourseBanner: 지역명 문구 + 탭 콜백', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecommendedCourseBanner(
            region: RegionCode.seosan,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('서산 추천 채록길'), findsOneWidget);
    expect(find.text('서산의 매력을 담은 코스를 확인해보세요'), findsOneWidget);
    await tester.tap(find.byType(RecommendedCourseBanner));
    expect(tapped, isTrue);
  });

  testWidgets('RegionPlaceStrip: 헤더 문구 + 전체보기 탭 + 카드 이름', (tester) async {
    var seeAll = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegionPlaceStrip(
            region: RegionCode.yesan,
            places: [_place('수덕사'), _place('예당호')],
            onSeeAll: () => seeAll = true,
          ),
        ),
      ),
    );
    expect(find.text('예산에서 이런 장소를 만나보세요'), findsOneWidget);
    expect(find.text('수덕사'), findsOneWidget);
    await tester.tap(find.text('전체보기'));
    expect(seeAll, isTrue);
  });

  group('RegionDetailPanel', () {
    Widget host({
      required RegionLoadStatus status,
      List<PlaceListResponse> places = const [],
      VoidCallback? onRetry,
      ValueChanged<RegionCode>? onExplore,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: RegionDetailPanel(
            region: RegionCode.yesan,
            status: status,
            places: places,
            onRetry: onRetry ?? () {},
            onExploreRegionRequested: onExplore ?? (_) {},
          ),
        ),
      );
    }

    testWidgets('loading이면 인디케이터', (tester) async {
      await tester.pumpWidget(host(status: RegionLoadStatus.loading));
      expect(find.byType(ChaerokLoadingIndicator), findsOneWidget);
    });

    testWidgets('error이면 다시 시도 버튼, 탭 시 onRetry', (tester) async {
      var retried = false;
      await tester.pumpWidget(
        host(status: RegionLoadStatus.error, onRetry: () => retried = true),
      );
      await tester.tap(find.text('다시 시도'));
      expect(retried, isTrue);
    });

    testWidgets('ready + 빈 목록이면 안내 문구', (tester) async {
      await tester.pumpWidget(host(status: RegionLoadStatus.ready));
      expect(find.text('이 지역의 장소 정보가 없어요'), findsOneWidget);
    });

    testWidgets('ready + 목록이면 소개/해시태그/배너 렌더', (tester) async {
      await tester.pumpWidget(
        host(
          status: RegionLoadStatus.ready,
          places: [_place('수덕사', image: 'http://x/a.jpg')],
        ),
      );
      expect(find.text('예산'), findsOneWidget); // 정림사지체 타이틀
      expect(find.text('Y E S A N'), findsOneWidget);
      expect(find.text('# 수덕사'), findsOneWidget);
      expect(find.text('# 예당호'), findsOneWidget);
      expect(find.text('# 예산시장'), findsOneWidget);
      expect(find.text('예산 추천 채록길'), findsOneWidget);
    });

    testWidgets('배너 탭 시 onExploreRegionRequested(region)', (tester) async {
      RegionCode? got;
      await tester.pumpWidget(
        host(
          status: RegionLoadStatus.ready,
          places: [_place('수덕사', image: 'http://x/a.jpg')],
          onExplore: (r) => got = r,
        ),
      );
      await tester.tap(find.byType(RecommendedCourseBanner));
      expect(got, RegionCode.yesan);
    });
  });
}
