import 'package:chaerok/features/home/presentation/models/home_card_data.dart';
import 'package:chaerok/features/home/presentation/widgets/place_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('imageUrl이 null이면 PlaceImagePlaceholder를 그린다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: PlaceImage(
              imageUrl: null,
              mood: PlacePlaceholderMood.forest,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(PlaceImagePlaceholder), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('imageUrl이 빈 문자열이어도 플레이스홀더로 폴백한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 100,
            height: 100,
            child: PlaceImage(imageUrl: '  ', mood: PlacePlaceholderMood.wall),
          ),
        ),
      ),
    );

    expect(find.byType(PlaceImagePlaceholder), findsOneWidget);
  });
}
