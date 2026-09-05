import 'package:chaerok/features/home/presentation/home_dashboard_screen.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LocationVerificationResult.sessionCache = null;
    LocationVerificationResult.outOfServiceSessionCache = true; // 세션 캐시로 강제
  });

  tearDown(() {
    LocationVerificationResult.outOfServiceSessionCache = false;
  });

  testWidgets('세션 캐시가 out-of-service면 OutOfServiceHomeView를 렌더한다', (
    tester,
  ) async {
    // 진입 직후 로딩/에러 상태가 기본 뷰포트에서 오버플로우하지 않도록 넉넉히 준다.
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: HomeDashboardScreen()));
    await tester.pump(); // postFrameCallback
    await tester.pump();

    expect(find.byType(OutOfServiceHomeView), findsOneWidget);

    // initState의 _fetchUserInfo 등 뒤이어 도는 네트워크 호출의 타이머를 정리한다.
    await tester.pumpAndSettle();
  });
}
