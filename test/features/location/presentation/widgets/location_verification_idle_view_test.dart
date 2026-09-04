import 'package:chaerok/features/location/presentation/widgets/location_verification_idle_view.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const whyAnswer =
      '채록은 실제 여행 중인 지역을 기준으로 필름롤을 만들어요. '
      '현재 위치를 확인하면 해당 지역의 필름롤과 채록장소를 이용할 수 있어요.';
  const troubleFirstItem = '휴대폰의 위치 서비스가 켜져 있는지 확인해주세요.';
  const reloadLabel = '현재 위치 다시 불러오기';

  Future<void> pumpIdleView(
    WidgetTester tester, {
    VoidCallback? onVerifyTap,
    VoidCallback? onReloadTap,
    bool isReloading = false,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocationVerificationIdleView(
            mapPreview: const ColoredBox(color: Color(0xFFEEEEEE)),
            isReloading: isReloading,
            onVerifyTap: onVerifyTap ?? () {},
            onReloadTap: onReloadTap ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('FAQ는 기본적으로 모두 접혀 있다', (tester) async {
    await pumpIdleView(tester);

    expect(find.text('왜 위치 인증이 필요한가요?'), findsOneWidget);
    expect(find.text('위치 인증이 잘 안 되나요?'), findsOneWidget);
    expect(find.text(whyAnswer), findsNothing);
    expect(find.text(troubleFirstItem), findsNothing);
  });

  testWidgets('"왜 위치 인증이 필요한가요?"는 개별로 펼쳐지고 다시 접힌다', (tester) async {
    await pumpIdleView(tester);

    await tester.tap(find.text('왜 위치 인증이 필요한가요?'));
    await tester.pumpAndSettle();
    expect(find.text(whyAnswer), findsOneWidget);
    // 다른 패널은 그대로 접힌 상태.
    expect(find.text(troubleFirstItem), findsNothing);

    await tester.tap(find.text('왜 위치 인증이 필요한가요?'));
    await tester.pumpAndSettle();
    expect(find.text(whyAnswer), findsNothing);
  });

  testWidgets('"위치 인증이 잘 안 되나요?"를 펼치면 체크리스트와 재조회 버튼이 보인다', (tester) async {
    await pumpIdleView(tester);

    await tester.tap(find.text('위치 인증이 잘 안 되나요?'));
    await tester.pumpAndSettle();

    expect(find.text('아래 항목을 확인해주세요.'), findsOneWidget);
    expect(find.text(troubleFirstItem), findsOneWidget);
    expect(find.text(reloadLabel), findsOneWidget);
  });

  testWidgets('CTA를 탭하면 onVerifyTap이 호출된다', (tester) async {
    var verifyCount = 0;
    await pumpIdleView(tester, onVerifyTap: () => verifyCount++);

    await tester.tap(find.text('위치 인증하기'));
    await tester.pump();

    expect(verifyCount, 1);
  });

  testWidgets('"현재 위치 다시 불러오기"를 탭하면 onReloadTap이 호출된다', (tester) async {
    var reloadCount = 0;
    await pumpIdleView(tester, onReloadTap: () => reloadCount++);

    await tester.tap(find.text('위치 인증이 잘 안 되나요?'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(reloadLabel));
    await tester.tap(find.text(reloadLabel));
    await tester.pump();

    expect(reloadCount, 1);
  });

  testWidgets('isReloading이면 재조회 버튼이 로딩 인디케이터를 표시하고 콜백을 막는다', (tester) async {
    var reloadCount = 0;
    await pumpIdleView(
      tester,
      onReloadTap: () => reloadCount++,
      isReloading: true,
    );

    await tester.tap(find.text('위치 인증이 잘 안 되나요?'));
    // 로딩 인디케이터(CircularProgressIndicator)는 계속 회전하므로 pumpAndSettle 대신
    // 펼침 애니메이션(150ms)이 끝날 만큼만 진행한다.
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text(reloadLabel), findsNothing);
    expect(find.byType(ChaerokLoadingIndicator), findsOneWidget);

    await tester.tap(find.byType(ChaerokLoadingIndicator), warnIfMissed: false);
    await tester.pump();
    expect(reloadCount, 0);
  });
}
