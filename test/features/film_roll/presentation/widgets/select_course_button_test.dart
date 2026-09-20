import 'package:chaerok/features/film_roll/presentation/widgets/select_course_button.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Future<bool> Function() hasRecords,
  required VoidCallback onPressed,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SelectCourseButton(
          filmRollId: 'roll-1',
          onPressed: onPressed,
          debugHasRecords: hasRecords,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('방문/촬영 기록이 없으면 버튼이 활성화되어 눌린다', (tester) async {
    var pressed = 0;
    await _pump(
      tester,
      hasRecords: () async => false,
      onPressed: () => pressed++,
    );

    await tester.tap(find.text('추천 코스 선택하기'));

    expect(pressed, 1);
    expect(find.text(SelectCourseButton.blockedMessage), findsNothing);
  });

  testWidgets('방문/촬영 기록이 있으면 버튼을 비활성화하고 이유를 안내한다', (tester) async {
    var pressed = 0;
    await _pump(
      tester,
      hasRecords: () async => true,
      onPressed: () => pressed++,
    );

    await tester.tap(find.text('추천 코스 선택하기'), warnIfMissed: false);

    expect(pressed, 0);
    expect(find.text(SelectCourseButton.blockedMessage), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.descendant(
        of: find.byType(ChaerokButton),
        matching: find.byType(ElevatedButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('기록 조회에 실패하면 기존처럼 활성 상태를 유지한다', (tester) async {
    var pressed = 0;
    await _pump(
      tester,
      hasRecords: () async => throw StateError('db'),
      onPressed: () => pressed++,
    );

    await tester.tap(find.text('추천 코스 선택하기'));

    expect(pressed, 1);
  });
}
