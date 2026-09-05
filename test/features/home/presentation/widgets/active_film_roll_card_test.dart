import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/active_film_roll_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('썸네일 파일이 없으면 예외 없이 플레이스홀더로 대체된다', (tester) async {
    const data = FilmRollSummaryData(
      name: '공주',
      capturedCount: 1,
      totalCount: 5,
      photoThumbnailPaths: ['/nonexistent/path/does-not-exist.jpg'],
    );

    await tester.pumpWidget(wrap(const ActiveFilmRollCard(data: data)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // errorBuilder가 그려진 뒤에도 Image 위젯 자체는 트리에 남는다.
    expect(find.byType(Image), findsOneWidget);
  });
}
