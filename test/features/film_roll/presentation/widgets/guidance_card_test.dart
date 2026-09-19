import 'package:chaerok/features/film_roll/presentation/widgets/guidance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('제목과 child를 함께 렌더한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: GuidanceCard(title: '다음 장소', child: Text('공주 한옥마을')),
        ),
      ),
    );

    expect(find.text('다음 장소'), findsOneWidget);
    expect(find.text('공주 한옥마을'), findsOneWidget);
  });
}
