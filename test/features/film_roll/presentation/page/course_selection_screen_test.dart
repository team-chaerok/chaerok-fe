import 'package:chaerok/data/models/course_place_response.dart';
import 'package:chaerok/data/models/course_response.dart';
import 'package:chaerok/data/models/place_category.dart';
import 'package:chaerok/features/explore/domain/explore_place.dart';
import 'package:chaerok/features/film_roll/presentation/page/course_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CoursePlaceResponse _place(String title) => CoursePlaceResponse(
  source: 'kakao',
  title: title,
  categoryGroup: '카페',
  address: '주소',
  latitude: 36.45,
  longitude: 127.12,
);

final _courses = [
  CourseResponse(
    title: '제민천 산책 코스',
    score: 0.9,
    places: [_place('공산성'), _place('제민천'), _place('공주 한옥마을')],
  ),
  CourseResponse(
    title: '무령왕릉 코스',
    score: 0.8,
    places: [_place('무령왕릉'), _place('국립공주박물관')],
  ),
];

/// 지도 대신 현재 전달받은 코스/강조 순번을 텍스트로 그리는 테스트용 지도.
Widget _fakeMap(
  BuildContext context,
  List<CoursePlaceResponse> places,
  int? focusOrder,
  ValueChanged<int> onMarkerTap,
) {
  return GestureDetector(
    key: const ValueKey('fake-map'),
    onTap: () => onMarkerTap(1),
    child: Text('map:${places.first.title}:focus=$focusOrder'),
  );
}

Future<void> _pumpScreen(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: CourseSelectionScreen(
        regionId: 1,
        filmRollId: 'roll-1',
        debugFetchCourses: () async => _courses,
        debugMapBuilder: _fakeMap,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('첫 코스가 선택된 상태로 지도와 카드, 확정 버튼을 함께 보여준다', (tester) async {
    await _pumpScreen(tester);

    expect(find.text('map:공산성:focus=null'), findsOneWidget);
    expect(find.text('제민천 산책 코스'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('이 코스로 시작하기'), findsOneWidget);
    expect(find.text('지도로 보기'), findsNothing);
  });

  testWidgets('카드를 옆으로 넘기면 지도가 그 코스로 바뀌고 확정되지는 않는다', (tester) async {
    await _pumpScreen(tester);

    await tester.drag(find.text('제민천 산책 코스'), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('map:무령왕릉:focus=null'), findsOneWidget);
    expect(find.byType(CourseSelectionScreen), findsOneWidget);
  });

  testWidgets('장소 행을 탭하면 지도가 그 장소를 강조하고, 다시 탭하면 전체 보기로 돌아간다', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.text('제민천'));
    await tester.pumpAndSettle();
    expect(find.text('map:공산성:focus=2'), findsOneWidget);

    await tester.tap(find.text('제민천'));
    await tester.pumpAndSettle();
    expect(find.text('map:공산성:focus=null'), findsOneWidget);
  });

  testWidgets('마커를 탭하면 해당 장소가 강조되고, 코스를 넘기면 강조가 풀린다', (tester) async {
    await _pumpScreen(tester);

    await tester.tap(find.byKey(const ValueKey('fake-map')));
    await tester.pumpAndSettle();
    expect(find.text('map:공산성:focus=1'), findsOneWidget);

    await tester.drag(find.text('제민천 산책 코스'), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(find.text('map:무령왕릉:focus=null'), findsOneWidget);
  });

  testWidgets('추천 코스가 없으면 안내 문구를 보여준다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CourseSelectionScreen(
          regionId: 1,
          filmRollId: 'roll-1',
          debugFetchCourses: () async => const [],
          debugMapBuilder: _fakeMap,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('추천 코스가 없어요'), findsOneWidget);
    expect(find.text('이 코스로 시작하기'), findsNothing);
  });

  group('직접 만들기 탭', () {
    ExplorePlace explorePlace(String title) => ExplorePlace(
      title: title,
      address: '충남 공주시',
      latitude: 36.45,
      longitude: 127.12,
      categoryGroup: PlaceCategoryGroup.fromWire('CAFE'),
      categoryGroupWire: 'CAFE',
      categoryDetail: PlaceCategoryDetail.fromWire('카페'),
      categoryDetailLabel: '카페',
      source: 'KAKAO_LOCAL',
      identityKey: title,
    );

    Future<void> pumpCustom(
      WidgetTester tester, {
      ExplorePlace? initial,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CourseSelectionScreen(
            regionId: 1,
            filmRollId: 'roll-1',
            initialTab: CourseSelectionInitialTab.custom,
            initialSelectedPlace: initial,
            debugFetchCourses: () async => _courses,
            debugFetchRegionPlaces: () async => const [],
            debugMapBuilder: _fakeMap,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('선택한 장소가 없으면 지도 자리에 안내 문구를 보여준다', (tester) async {
      await pumpCustom(tester);

      expect(find.textContaining('지도에 순서대로 표시돼요'), findsOneWidget);
      expect(find.byKey(const ValueKey('fake-map')), findsNothing);
    });

    testWidgets('미리 담긴 장소가 있으면 지도에 표시하고 행을 탭해 강조를 토글한다', (tester) async {
      await pumpCustom(tester, initial: explorePlace('공산성'));

      expect(find.text('map:공산성:focus=null'), findsOneWidget);

      await tester.tap(find.text('공산성').last);
      await tester.pumpAndSettle();
      expect(find.text('map:공산성:focus=1'), findsOneWidget);

      await tester.tap(find.text('공산성').last);
      await tester.pumpAndSettle();
      expect(find.text('map:공산성:focus=null'), findsOneWidget);
    });

    testWidgets('선택한 장소를 제거하면 지도가 안내 문구로 돌아간다', (tester) async {
      await pumpCustom(tester, initial: explorePlace('공산성'));

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.textContaining('지도에 순서대로 표시돼요'), findsOneWidget);
    });
  });
}
