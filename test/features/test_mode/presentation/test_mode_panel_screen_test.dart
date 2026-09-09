import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/test_mode/test_mode_session.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/features/test_mode/presentation/test_mode_panel_screen.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocationVerificationResult.sessionCache = null;
    LocationVerificationResult.outOfServiceSessionCache = false;
    LocationVerificationResult.qaLocationDirty = false;
  });

  tearDown(() {
    TestModeSession.instance.reset();
    LocationVerificationResult.sessionCache = null;
    LocationVerificationResult.outOfServiceSessionCache = false;
    LocationVerificationResult.qaLocationDirty = false;
  });

  // 네이티브 카카오맵 플랫폼 뷰를 위젯 테스트에서 띄우지 않도록
  // debugDisableMapPicker로 지도를 placeholder로 대체한다.
  Future<void> pumpPanel(
    WidgetTester tester, {
    GlobalKey<TestModePanelScreenState>? key,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: TestModePanelScreen(key: key, debugDisableMapPicker: true),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('지역 칩을 고르면 mock 위치가 켜지고 재판정 플래그가 선다', (tester) async {
    await pumpPanel(tester);

    final buyeoChip = find.widgetWithText(ChoiceChip, '부여');
    await tester.ensureVisible(buyeoChip);
    await tester.tap(buyeoChip);
    await tester.pumpAndSettle();

    expect(
      await AppPreferences.instance.getMockRegionCodeName(),
      RegionCode.buyeo.name,
    );
    expect(await AppPreferences.instance.isMockLocationEnabled(), isTrue);
    expect(LocationVerificationResult.qaLocationDirty, isTrue);
  });

  testWidgets('지도에서 선택한 위치를 적용하면 custom 모드로 저장되고 mock 위치가 켜진다', (tester) async {
    final key = GlobalKey<TestModePanelScreenState>();
    await pumpPanel(tester, key: key);

    final mapModeChip = find.widgetWithText(ChoiceChip, '지도에서 선택');
    await tester.ensureVisible(mapModeChip);
    await tester.tap(mapModeChip);
    await tester.pumpAndSettle();

    // 지도 탭(onMapClick)을 시뮬레이션한다.
    key.currentState!.debugPickMockLocation(37.5665, 126.9780);
    await tester.pumpAndSettle();

    final applyButton = find.widgetWithText(OutlinedButton, '이 위치로 적용');
    await tester.ensureVisible(applyButton);
    await tester.tap(applyButton);
    await tester.pumpAndSettle();

    expect(await AppPreferences.instance.isMockCustomLocation(), isTrue);
    expect(await AppPreferences.instance.getMockCustomLatitude(), 37.5665);
    expect(await AppPreferences.instance.getMockCustomLongitude(), 126.9780);
    expect(await AppPreferences.instance.isMockLocationEnabled(), isTrue);
    expect(LocationVerificationResult.qaLocationDirty, isTrue);
  });

  testWidgets('지도에서 위치를 찍기 전에는 "이 위치로 적용" 버튼이 비활성이다', (tester) async {
    await pumpPanel(tester);

    final mapModeChip = find.widgetWithText(ChoiceChip, '지도에서 선택');
    await tester.ensureVisible(mapModeChip);
    await tester.tap(mapModeChip);
    await tester.pumpAndSettle();

    final applyButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '이 위치로 적용'),
    );
    expect(applyButton.onPressed, isNull);
    expect(find.text('선택한 위치 없음'), findsOneWidget);
    expect(await AppPreferences.instance.isMockCustomLocation(), isFalse);
  });

  testWidgets('"테스트 상태 초기화"가 mock 위치 설정을 모두 되돌린다', (tester) async {
    final key = GlobalKey<TestModePanelScreenState>();
    await pumpPanel(tester, key: key);

    final seosanChip = find.widgetWithText(ChoiceChip, '서산');
    await tester.ensureVisible(seosanChip);
    await tester.tap(seosanChip);
    await tester.pumpAndSettle();
    expect(await AppPreferences.instance.isMockLocationEnabled(), isTrue);

    final resetButton = find.widgetWithText(OutlinedButton, '테스트 상태 초기화');
    await tester.ensureVisible(resetButton);
    await tester.tap(resetButton);
    await tester.pumpAndSettle();

    expect(await AppPreferences.instance.getMockRegionCodeName(), isNull);
    expect(await AppPreferences.instance.isMockLocationEnabled(), isFalse);
    expect(await AppPreferences.instance.isMockCustomLocation(), isFalse);
    expect(await AppPreferences.instance.isDebugOutOfServiceArea(), isFalse);
  });
}
