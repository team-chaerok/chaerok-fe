import 'package:chaerok/features/explore/presentation/explore_screen.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // ExploreScreen.initState → reevaluate()가 AppPreferences(SharedPreferences)를
  // 태우므로 다른 위젯 테스트(signup_navigation_test)와 동일하게 mock 값을 채운다.
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('selectRegion은 예외 없이 호출되고 지역 셀렉터가 갱신된다', (tester) async {
    // 관광지 조회 실패 시 노출되는 에러 UI가 기본 테스트 뷰포트에서 오버플로우
    // 하지 않도록 넉넉한 표면을 준다.
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final key = GlobalKey<ExploreScreenState>();
    await tester.pumpWidget(MaterialApp(home: ExploreScreen(key: key)));
    await tester.pump(); // reevaluate/initState 비동기 1프레임

    key.currentState!.selectRegion(RegionCode.seosan);
    await tester.pump();

    // ChoiceChip('서산')이 선택 상태로 표시된다.
    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '서산'),
    );
    expect(chip.selected, isTrue);

    // 뒤이어 도는 _fetchPlaces(네트워크 실패 → _errorMessage 흡수)의
    // 남은 타이머를 정리한다.
    await tester.pumpAndSettle();
  });
}
