import 'package:chaerok/features/home/presentation/home_dashboard_screen.dart';
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
  });

  tearDown(() {
    LocationVerificationResult.outOfServiceSessionCache = false;
  });

  testWidgets('세션 캐시가 out-of-service면 OutOfServiceHomeView를 렌더한다', (
    tester,
  ) async {
    LocationVerificationResult.outOfServiceSessionCache = true; // 세션 캐시로 강제

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

  testWidgets('위치 인증 게이트를 뒤로가기로 빠져나와도(outcome=null) 캐시가 세팅됐으면 복구한다', (
    tester,
  ) async {
    // 게이트를 아직 타지 않은 상태로 진입 → _ensureLocationVerified가
    // LocationVerificationScreen을 push 한다.
    LocationVerificationResult.outOfServiceSessionCache = false;

    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: HomeDashboardScreen()));
    await tester.pump(); // postFrameCallback → 게이트 push
    await tester.pump();

    // 게이트가 떠 있고, 아직 홈은 빈 대시보드 상태.
    expect(find.byType(LocationVerificationScreen), findsOneWidget);
    expect(find.byType(OutOfServiceHomeView), findsNothing);

    // 게이트가 "서비스 지역 외" 카드를 렌더하며 세션 캐시를 세팅한 상황을 모사.
    LocationVerificationResult.outOfServiceSessionCache = true;

    // 사용자가 CTA 대신 AppBar 뒤로가기를 눌러 게이트를 닫는다 → outcome=null.
    await tester.pageBack();
    await tester.pump();
    await tester.pump();

    // case null 브랜치가 캐시를 다시 읽어 빈 대시보드 대신 충남 외 지역 홈으로 복구.
    expect(find.byType(OutOfServiceHomeView), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
