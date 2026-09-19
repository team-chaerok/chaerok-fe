import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/features/film_roll/domain/visit_verification.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/visit_gate_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(VisitGateResult gate) => MaterialApp(
    home: Scaffold(body: VisitGateMessage(gate: gate)),
  );

  testWidgets('인증 가능 상태면 게이트 문구를 primaryDark 색으로 보여준다', (tester) async {
    await tester.pumpWidget(
      host(const VisitGateResult(VisitGateStatus.ok, distanceMeters: 10)),
    );

    final text = tester.widget<Text>(find.text('지금 방문 인증할 수 있어요'));
    expect(text.style?.color, ChaerokColors.primaryDark);
  });

  testWidgets('너무 멀면 게이트 문구를 textSecondary 색으로 보여준다', (tester) async {
    await tester.pumpWidget(
      host(const VisitGateResult(VisitGateStatus.tooFar, distanceMeters: 500)),
    );

    final text = tester.widget<Text>(find.text('장소에 더 가까이 가면 방문 인증할 수 있어요'));
    expect(text.style?.color, ChaerokColors.textSecondary);
  });
}
