import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_photo.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/presentation/page/visit_capture_screen.dart';
import 'package:chaerok/features/home/presentation/widgets/region_photo_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 존재하지 않는 파일 경로를 넘기면 `Image.file`이 비동기로 실패하고
/// errorBuilder(회색 슬롯)로 폴백한다 — 실제 이미지 디코딩은 검증 대상이
/// 아니므로 렌더/탭 동작 검증에는 이 폴백 경로로도 충분하다.
FilmRollPlace _place(
  String id, {
  required String category,
  int visitOrder = 0,
  bool isVisited = true,
}) => FilmRollPlace(
  id: id,
  filmRollId: 'fr1',
  name: '장소 $id',
  address: '충남 어딘가',
  category: category,
  latitude: 36.0,
  longitude: 127.0,
  visitOrder: visitOrder,
  isVisited: isVisited,
  photoCount: 1,
);

FilmRollPhoto _photo(
  String id, {
  required String placeId,
  required int sequence,
  required DateTime takenAt,
}) => FilmRollPhoto(
  id: id,
  filmRollId: 'fr1',
  filmRollPlaceId: placeId,
  originalPath: '/tmp/$id-original.jpg',
  thumbnailPath: '/tmp/$id-thumb.jpg',
  takenAt: takenAt,
  sequence: sequence,
  isSynced: false,
);

/// 큰 사진은 디코딩 메모리를 줄이려고 `cacheHeight`를 줘서 `FileImage`가
/// `ResizeImage`로 한 번 더 감싸진다 — 어느 쪽이든 실제 `FileImage`까지
/// 벗겨서 파일 경로를 얻는다.
String _filePath(ImageProvider provider) {
  final inner = provider is ResizeImage ? provider.imageProvider : provider;
  return (inner as FileImage).file.path;
}

/// 필름스트립 썸네일(원본이 아닌) `Image.file` 경로만 순서대로 뽑는다.
List<String> _thumbnailPaths(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((image) => _filePath(image.image))
    .where((path) => path.contains('-thumb.jpg'))
    .toList();

/// 큰 사진(원본) `Image.file` 경로. 없으면(미리보기/플레이스홀더 상태) null.
String? _heroImagePath(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((image) => _filePath(image.image))
    .where((path) => path.contains('-original.jpg'))
    .firstOrNull;

/// 아직 인증(촬영) 전인 필름스트립 빈 프레임(연한 회색 ColoredBox) 찾기.
final Finder _unvisitedTileFinder = find.byWidgetPredicate(
  (widget) => widget is ColoredBox && widget.color == ChaerokColors.border,
);

/// 필름스트립 칸 위 카테고리 태그(라벨 텍스트)의 글자 색 — 선택된 칸은
/// 흰 글자(초록 배경), 아니면 textSecondary(연한 배경)다.
Color? _tagTextColor(WidgetTester tester, String label) =>
    tester.widget<Text>(find.text(label)).style?.color;

void main() {
  // 관광지(p-tour)만 사진 2장(가장 최근 photo-2), 식당(p-food)은 1장(photo-3),
  // 카페(p-cafe)는 아직 인증 전(사진 없음) — 필름스트립은 장소 3칸이어야 한다.
  final places = [
    _place('p-tour', category: 'HERITAGE', visitOrder: 0),
    _place('p-food', category: 'RESTAURANT', visitOrder: 1),
    _place('p-cafe', category: 'CAFE', visitOrder: 2, isVisited: false),
  ];

  final photos = [
    _photo(
      'photo-1',
      placeId: 'p-tour',
      sequence: 1,
      takenAt: DateTime(2026, 1, 1, 9),
    ),
    _photo(
      'photo-2',
      placeId: 'p-tour',
      sequence: 2,
      takenAt: DateTime(2026, 1, 1, 10),
    ),
    _photo(
      'photo-3',
      placeId: 'p-food',
      sequence: 3,
      takenAt: DateTime(2026, 1, 1, 11),
    ),
  ];

  Widget host({
    List<FilmRollPhoto>? overridePhotos,
    List<FilmRollPlace>? overridePlaces,
  }) => MaterialApp(
    home: Scaffold(
      body: RegionPhotoGallery(
        filmRollId: 'fr1',
        photos: overridePhotos ?? photos,
        places: overridePlaces ?? places,
        onVisitCompleted: () async {},
      ),
    ),
  );

  testWidgets('카테고리 태그는 필름스트립 각 칸 위에 개별로 뜨고, 카운터는 전체 사진 수/최대치를 보여준다', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    expect(find.text('관광지'), findsOneWidget);
    expect(find.text('식당'), findsOneWidget);
    expect(find.text('카페'), findsOneWidget);
    expect(find.text('3 / 24'), findsOneWidget);
    expect(find.text('지역 내 최대 24장'), findsOneWidget);
  });

  testWidgets('필름스트립 칸은 사진이 아니라 코스 장소 단위다 — 관광지→식당→카페 순, 인증한 장소는 사진을 보여준다', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    // 관광지는 가장 최근 사진(photo-2), 식당은 photo-3이 대표 썸네일로
    // 뜨고, 아직 인증 전인 카페는 사진 타일이 없다(대신 빈 프레임).
    expect(_thumbnailPaths(tester), [
      '/tmp/photo-2-thumb.jpg',
      '/tmp/photo-3-thumb.jpg',
    ]);
    expect(_unvisitedTileFinder, findsOneWidget);
  });

  testWidgets('필름스트립에서 인증된 다른 장소를 고르면 큰 사진이 그 장소 사진으로 바뀐다', (tester) async {
    await tester.pumpWidget(host());

    // 기본은 관광지 최근 사진(photo-2)이 큰 사진 자리에 있다.
    expect(_heroImagePath(tester), '/tmp/photo-2-original.jpg');

    // 필름스트립에서 식당(photo-3) 타일을 고른다.
    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is FileImage &&
            (widget.image as FileImage).file.path == '/tmp/photo-3-thumb.jpg',
      ),
    );
    await tester.pump();

    expect(_heroImagePath(tester), '/tmp/photo-3-original.jpg');
  });

  testWidgets('필름스트립 카테고리 태그를 눌러도 사진 타일과 동일하게 큰 사진이 바뀐다', (tester) async {
    await tester.pumpWidget(host());

    // 기본은 관광지 최근 사진(photo-2)이 큰 사진 자리에 있다.
    expect(_heroImagePath(tester), '/tmp/photo-2-original.jpg');

    // 필름스트립 위 "식당" 태그를 누른다(사진 타일이 아니라 태그).
    await tester.tap(find.text('식당'));
    await tester.pump();

    expect(_heroImagePath(tester), '/tmp/photo-3-original.jpg');
    expect(_tagTextColor(tester, '식당'), Colors.white);
  });

  testWidgets('아직 인증하지 않은 장소의 태그를 눌러도 카메라로 이어지지 않고 큰 사진만 그 장소로 넘어간다', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    await tester.tap(find.text('카페'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(VisitCaptureScreen), findsNothing);
    expect(_heroImagePath(tester), isNull);
    expect(find.textContaining('가 볼 장소 · 장소 p-cafe'), findsOneWidget);
    expect(_tagTextColor(tester, '카페'), Colors.white);
  });

  testWidgets('아직 인증하지 않은 장소 타일을 누르면 그 장소를 인증하는 카메라 화면이 열린다', (tester) async {
    await tester.pumpWidget(host());

    await tester.tap(_unvisitedTileFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final pushed = tester.widget<VisitCaptureScreen>(
      find.byType(VisitCaptureScreen),
    );
    expect(pushed.filmRollId, 'fr1');
    expect(pushed.filmRollPlaceId, 'p-cafe');
  });

  testWidgets('필름스트립에서 사진을 고르면 그 칸의 카테고리 태그만 초록(선택) 색으로 바뀐다', (tester) async {
    await tester.pumpWidget(host());

    // 기본은 관광지 최근 사진(photo-2)이 선택돼 있어 관광지 태그만 흰 글자다.
    expect(_tagTextColor(tester, '관광지'), Colors.white);
    expect(_tagTextColor(tester, '식당'), ChaerokColors.textSecondary);

    await tester.tap(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is FileImage &&
            (widget.image as FileImage).file.path == '/tmp/photo-3-thumb.jpg',
      ),
    );
    await tester.pump();

    expect(_tagTextColor(tester, '식당'), Colors.white);
    expect(_tagTextColor(tester, '관광지'), ChaerokColors.textSecondary);
  });

  testWidgets('필름스트립은 내용과 무관하게 항상 검은 필름 띠(스프라켓 구멍) 안에 놓인다', (tester) async {
    await tester.pumpWidget(host());

    // 인증된 장소가 있는 정상 상태에서도 필름 띠 틀 자체는 항상 렌더된다 —
    // 예전엔 사진이 있으면 이 틀 없이 사진만 맨몸으로 떴던 회귀가 있었다.
    expect(find.byKey(const ValueKey('filmStripFrame')), findsOneWidget);
  });

  testWidgets('코스에 담긴 장소가 하나도 없어도 필름 띠 틀은 그대로 보여준다', (tester) async {
    await tester.pumpWidget(
      host(overridePhotos: const [], overridePlaces: const []),
    );

    expect(find.byKey(const ValueKey('filmStripFrame')), findsOneWidget);
  });

  testWidgets(
    '기본 카테고리(관광지)에 찍은 사진이 없으면 큰 사진 자리에 코스에 담긴 관광지 장소를 "가 볼 장소"로 미리 보여준다',
    (tester) async {
      final photosWithoutTourism = [
        _photo(
          'photo-3',
          placeId: 'p-food',
          sequence: 1,
          takenAt: DateTime(2026, 1, 1, 11),
        ),
      ];
      await tester.pumpWidget(host(overridePhotos: photosWithoutTourism));

      expect(find.textContaining('가 볼 장소'), findsOneWidget);
      expect(find.textContaining('장소 p-tour'), findsOneWidget);
    },
  );

  testWidgets('기본 카테고리(관광지)에 찍은 사진이 있으면 장소 미리보기 대신 실제 사진을 보여준다', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    expect(find.textContaining('가 볼 장소'), findsNothing);
  });

  testWidgets('큰 사진을 좌우로 스와이프하면 코스 순서(관광지→식당→카페)대로 넘어가고 태그 선택도 같이 바뀐다', (
    tester,
  ) async {
    await tester.pumpWidget(host());

    expect(_heroImagePath(tester), '/tmp/photo-2-original.jpg');
    expect(_tagTextColor(tester, '관광지'), Colors.white);

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
    await tester.pumpAndSettle();

    expect(_heroImagePath(tester), '/tmp/photo-3-original.jpg');
    expect(_tagTextColor(tester, '식당'), Colors.white);
    expect(_tagTextColor(tester, '관광지'), ChaerokColors.textSecondary);

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
    await tester.pumpAndSettle();

    // 아직 인증 전인 카페 차례 — 사진 대신 "가 볼 장소" 미리보기로 넘어간다.
    expect(_heroImagePath(tester), isNull);
    expect(find.textContaining('가 볼 장소 · 장소 p-cafe'), findsOneWidget);
    expect(_tagTextColor(tester, '카페'), Colors.white);
    expect(_tagTextColor(tester, '식당'), ChaerokColors.textSecondary);
  });
}
