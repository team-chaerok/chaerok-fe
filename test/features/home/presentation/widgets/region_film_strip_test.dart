import 'package:chaerok/features/home/presentation/widgets/out_of_service/region_film_strip.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required RegionCode selected,
    required ValueChanged<RegionCode> onSelect,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegionFilmStrip(selected: selected, onSelect: onSelect),
        ),
      ),
    );
  }

  testWidgets('4개 지역 필름롤 라벨을 모두 표시한다', (tester) async {
    await pump(tester, selected: RegionCode.yesan, onSelect: (_) {});
    expect(find.text('공주 필름롤'), findsOneWidget);
    expect(find.text('부여 필름롤'), findsOneWidget);
    expect(find.text('서산 필름롤'), findsOneWidget);
    expect(find.text('예산 필름롤'), findsOneWidget);
  });

  testWidgets('접힌 헤더를 탭하면 onSelect가 호출된다', (tester) async {
    RegionCode? tapped;
    await pump(tester, selected: RegionCode.yesan, onSelect: (r) => tapped = r);
    await tester.tap(find.text('서산 필름롤'));
    expect(tapped, RegionCode.seosan);
  });

  testWidgets('이미 선택된 헤더 탭도 onSelect를 호출한다(부모가 no-op 판단)', (tester) async {
    RegionCode? tapped;
    await pump(tester, selected: RegionCode.yesan, onSelect: (r) => tapped = r);
    await tester.tap(find.text('예산 필름롤'));
    expect(tapped, RegionCode.yesan);
  });
}
