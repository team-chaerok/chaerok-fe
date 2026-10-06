import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_result_photo_viewer_page.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_result_photos_screen.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_result_film_frame.dart';
import 'package:chaerok/shared/widgets/chaerok_film_strip_frame.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<FilmRollResultPhoto> _photos(int count) => [
  for (var i = 1; i <= count; i++)
    FilmRollResultPhoto(sequence: i, localPath: '/docs/filtered/$i.jpg'),
];

void main() {
  Future<void> pumpScreen(WidgetTester tester, int photoCount) async {
    // 일반적인 휴대폰 화면 크기에서 확인한다.
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: FilmRollResultPhotosScreen(photos: _photos(photoCount)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('사진을 3장씩 필름 스트립으로 끊어 쌓고, 마지막 줄의 남는 칸은 빈 필름으로 채운다', (
    tester,
  ) async {
    await pumpScreen(tester, 5);

    expect(find.byType(ChaerokFilmStripFrame), findsNWidgets(2));
    expect(find.byType(FilmRollResultFilmFrame), findsNWidgets(6));
    for (final number in ['01', '02', '03', '04', '05']) {
      expect(find.text(number), findsOneWidget);
    }
    expect(find.text('06'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('필름 칸을 누르면 그 사진부터 전체 화면으로 본다', (tester) async {
    await pumpScreen(tester, 5);

    await tester.tap(find.text('04'));
    await tester.pumpAndSettle();

    expect(find.byType(FilmRollResultPhotoViewerPage), findsOneWidget);
    expect(find.text('4 / 5'), findsOneWidget);
  });

  testWidgets('빈 필름 칸은 눌러도 아무 화면도 열지 않는다', (tester) async {
    await pumpScreen(tester, 5);

    await tester.tap(find.byType(FilmRollResultFilmFrame).last);
    await tester.pumpAndSettle();

    expect(find.byType(FilmRollResultPhotoViewerPage), findsNothing);
  });
}
