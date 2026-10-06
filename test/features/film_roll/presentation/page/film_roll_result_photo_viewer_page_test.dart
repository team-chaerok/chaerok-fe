import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:chaerok/features/film_roll/domain/usecase/save_result_photo_to_gallery_use_case.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_result_photo_viewer_page.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_result_photos_screen.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_result_film_frame.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gal/gal.dart';

const _photos = [
  FilmRollResultPhoto(sequence: 1, localPath: '/docs/filtered/101.jpg'),
  FilmRollResultPhoto(
    sequence: 2,
    localPath: '/docs/original/ph-2.jpg',
    isFiltered: false,
  ),
  FilmRollResultPhoto(sequence: 3, localPath: '/docs/filtered/103.jpg'),
];

void main() {
  late List<FilmRollResultPhoto> savedPhotos;
  late Object? saveError;

  SaveResultPhotoToGalleryUseCase saveUseCase() {
    return SaveResultPhotoToGalleryUseCase(
      putImage: (path) async {
        if (saveError != null) throw saveError!;
        savedPhotos.add(_photos.firstWhere((p) => p.localPath == path));
      },
    );
  }

  setUp(() {
    savedPhotos = [];
    saveError = null;
  });

  Future<void> openViewerFromGrid(WidgetTester tester, int index) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FilmRollResultPhotosScreen(
          photos: _photos,
          savePhotoToGallery: saveUseCase(),
        ),
      ),
    );
    await tester.tap(find.byType(FilmRollResultFilmFrame).at(index));
    await tester.pumpAndSettle();
  }

  testWidgets('전체 사진 화면에서 사진을 누르면 그 사진부터 전체 화면으로 보여준다', (tester) async {
    await openViewerFromGrid(tester, 1);

    expect(find.byType(FilmRollResultPhotoViewerPage), findsOneWidget);
    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    // 촬영 원본으로 대체된 사진이라 라벨을 보여준다.
    expect(find.text('필터 미적용'), findsOneWidget);
  });

  testWidgets('상단의 닫기 버튼과 위치 표시가 겹치지 않고, 위치 표시는 화면 가운데에 있다', (tester) async {
    await openViewerFromGrid(tester, 1);

    final closeRect = tester.getRect(find.byTooltip('닫기'));
    final indicatorRect = tester.getRect(find.text('2 / 3'));
    final screenWidth = tester.getSize(find.byType(Scaffold).last).width;

    expect(closeRect.overlaps(indicatorRect), isFalse);
    expect(indicatorRect.center.dx, moreOrLessEquals(screenWidth / 2));
  });

  testWidgets('좌우로 넘기면 다음 사진으로 바뀐다', (tester) async {
    await openViewerFromGrid(tester, 1);

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('3 / 3'), findsOneWidget);
    expect(find.text('필터 미적용'), findsNothing);
  });

  testWidgets('두 번 탭해 확대하면 좌우 넘김을 막고, 다시 두 번 탭하면 풀린다', (tester) async {
    await openViewerFromGrid(tester, 0);

    ScrollPhysics? pagePhysics() =>
        tester.widget<PageView>(find.byType(PageView)).physics;
    Future<void> doubleTap() async {
      final center = tester.getCenter(find.byType(InteractiveViewer));
      await tester.tapAt(center);
      await tester.pump(kDoubleTapMinTime);
      await tester.tapAt(center);
      await tester.pumpAndSettle();
    }

    expect(pagePhysics(), isA<PageScrollPhysics>());

    await doubleTap();
    expect(pagePhysics(), isA<NeverScrollableScrollPhysics>());

    await doubleTap();
    expect(pagePhysics(), isA<PageScrollPhysics>());
  });

  testWidgets('저장 버튼을 누르면 지금 보는 사진을 갤러리에 저장하고 안내한다', (tester) async {
    await openViewerFromGrid(tester, 2);

    await tester.tap(find.text('갤러리에 저장'));
    await tester.pumpAndSettle();

    expect(savedPhotos.map((p) => p.sequence), [3]);
    expect(find.text('갤러리에 저장했어요.'), findsOneWidget);
  });

  testWidgets('갤러리 권한이 없으면 설정에서 허용하라고 안내한다', (tester) async {
    saveError = GalException(
      type: GalExceptionType.accessDenied,
      platformException: PlatformException(code: 'ACCESS_DENIED'),
      stackTrace: StackTrace.empty,
    );
    await openViewerFromGrid(tester, 0);

    await tester.tap(find.text('갤러리에 저장'));
    await tester.pumpAndSettle();

    expect(savedPhotos, isEmpty);
    expect(find.text('사진을 저장하려면 설정에서 사진 접근을 허용해 주세요.'), findsOneWidget);
  });
}
