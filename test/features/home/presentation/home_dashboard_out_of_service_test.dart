import 'package:chaerok/features/home/presentation/home_dashboard_screen.dart';
import 'package:chaerok/features/home/presentation/widgets/out_of_service/out_of_service_home_view.dart';
import 'package:chaerok/features/location/data/location_verification_result.dart';
import 'package:chaerok/features/location/presentation/location_verification_screen.dart';
import 'package:chaerok/features/location/presentation/widgets/location_verification_idle_view.dart';
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

  testWidgets('조용한 위치 확인이 실패하면 위치 인증 화면(에러 스텝)으로 폴백한다', (tester) async {
    LocationVerificationResult.outOfServiceSessionCache = false;

    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: HomeDashboardScreen(
          debugRunLocationVerification: () async =>
              const LocationVerificationFailed(
                LocationVerificationFailureReason.locationUnavailable,
              ),
        ),
      ),
    );
    await tester.pump(); // postFrameCallback → 러너 호출
    await tester.pump(); // 러너 Future 완료 → 폴백 push
    await tester.pump(); // 라우트 전환

    // 온보딩(idle) 뷰가 아니라 곧바로 안내 스텝이 뜬다.
    expect(find.byType(LocationVerificationScreen), findsOneWidget);
    expect(find.byType(LocationVerificationIdleView), findsNothing);
    expect(find.text('현재 위치를 확인할 수 없어요'), findsOneWidget);
    expect(find.byType(OutOfServiceHomeView), findsNothing);

    // 폴백 화면이 "서비스 지역 외" 카드를 렌더하며 세션 캐시를 세팅한 상황을 모사.
    LocationVerificationResult.outOfServiceSessionCache = true;

    // 사용자가 CTA 대신 AppBar 뒤로가기를 눌러 화면을 닫는다 → outcome=null.
    await tester.pageBack();
    await tester.pump();
    await tester.pump();

    // _applyLocationOutcome의 null 브랜치가 캐시를 다시 읽어 충남 외 지역 홈으로 복구.
    expect(find.byType(OutOfServiceHomeView), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
