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
    LocationVerificationResult.outOfServiceSessionCache = false;
  });

  tearDown(() {
    LocationVerificationResult.sessionCache = null;
    LocationVerificationResult.outOfServiceSessionCache = false;
  });

  testWidgets('조용한 위치 확인이 서비스 지역 외면 화면 전환 없이 OutOfServiceHomeView를 렌더한다', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: HomeDashboardScreen(
          debugRunLocationVerification: () async =>
              const LocationOutOfService(),
        ),
      ),
    );
    await tester.pump(); // postFrameCallback → 러너 호출
    await tester.pump(); // 러너 Future 완료 → 결과 반영

    // 기존 회원은 위치 인증 화면(온보딩/에러)을 거치지 않는다.
    expect(find.byType(LocationVerificationScreen), findsNothing);
    expect(find.byType(OutOfServiceHomeView), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
