import 'package:chaerok/features/home/presentation/home_dashboard_screen.dart';
import 'package:chaerok/features/home/presentation/main_tab_screen.dart';
import 'package:chaerok/features/home/presentation/widgets/home_bottom_navigation.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/features/location/presentation/location_verification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocationVerificationResult.sessionCache = null;
    LocationVerificationResult.outOfServiceSessionCache = false;
  });

  tearDown(() {
    LocationVerificationResult.sessionCache = null;
    LocationVerificationResult.outOfServiceSessionCache = false;
  });

  // 위치 인증 러너(geolocator)를 태우지 않도록 out-of-service 상태로 홈을 띄운다.
  // 기존 home_dashboard_*_test 들과 동일한 방식.
  Future<void> pumpHome(
    WidgetTester tester,
    GlobalKey<HomeDashboardScreenState> key,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: HomeDashboardScreen(
          key: key,
          debugRunLocationVerification: () async =>
              const LocationOutOfService(),
        ),
      ),
    );
    await tester.pump(); // postFrameCallback → 러너 호출
    await tester.pump(); // 러너 Future 완료 → 결과 반영
  }

  testWidgets('refresh()는 예외 없이 완료되고 위치 인증 화면으로 이동하지 않으며 홈 상태를 유지한다', (
    tester,
  ) async {
    final key = GlobalKey<HomeDashboardScreenState>();
    await pumpHome(tester, key);
    expect(find.byType(OutOfServiceHomeView), findsOneWidget);

    await key.currentState!.refresh();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(LocationVerificationScreen), findsNothing);
    expect(find.byType(OutOfServiceHomeView), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('refresh()를 동시에 여러 번 호출해도 _isRefreshing 가드로 안전하게 반환한다', (
    tester,
  ) async {
    final key = GlobalKey<HomeDashboardScreenState>();
    await pumpHome(tester, key);

    await Future.wait([
      key.currentState!.refresh(),
      key.currentState!.refresh(),
      key.currentState!.refresh(),
    ]);
    await tester.pump();

    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
  });

  testWidgets('앱이 포그라운드로 복귀하면(resumed) refresh가 돌지만 네비게이션은 없다', (tester) async {
    final key = GlobalKey<HomeDashboardScreenState>();
    await pumpHome(tester, key);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.byType(LocationVerificationScreen), findsNothing);
    expect(find.byType(OutOfServiceHomeView), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('MainTabScreen에서 채록길 탭 → 홈 탭 왕복 시 예외가 발생하지 않는다', (tester) async {
    // MainTabScreen 자식 홈에는 debug 훅을 주입할 수 없으므로, 세션 캐시로
    // 위치 인증 러너를 건너뛰게 해서 pending 타이머를 만들지 않는다.
    LocationVerificationResult.outOfServiceSessionCache = true;

    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: MainTabScreen()));
    await tester.pumpAndSettle();

    final navBar = find.byType(HomeBottomNavigation);
    await tester.tap(find.descendant(of: navBar, matching: find.text('채록길')));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: navBar, matching: find.text('홈')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(HomeDashboardScreen), findsOneWidget);
  });
}
