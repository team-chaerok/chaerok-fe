import 'package:chaerok/features/film_roll/domain/entity/film_roll_photo.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/home/presentation/widgets/region_photo_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 존재하지 않는 파일 경로를 넘기면 `Image.file`이 비동기로 실패하고
/// errorBuilder(회색 슬롯)로 폴백한다 — 실제 이미지 디코딩은 검증 대상이
/// 아니므로 렌더/탭 동작 검증에는 이 폴백 경로로도 충분하다.
FilmRollPlace _place(String id, {required String category}) => FilmRollPlace(
  id: id,
  filmRollId: 'fr1',
  name: '장소 $id',
  address: '충남 어딘가',
  category: category,
  latitude: 36.0,
  longitude: 127.0,
  visitOrder: 0,
  isVisited: true,
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

void main() {
  final places = [
    _place('p-tour', category: 'HERITAGE'),
    _place('p-food', category: 'RESTAURANT'),
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

  Widget host() => MaterialApp(
    home: Scaffold(
      body: RegionPhotoGallery(photos: photos, places: places),
    ),
  );

  testWidgets('기본 카테고리는 관광지이고, 카운터는 전체 사진 수/최대치를 보여준다', (tester) async {
    await tester.pumpWidget(host());

    expect(find.text('관광지'), findsOneWidget);
    expect(find.text('식당'), findsOneWidget);
    expect(find.text('카페'), findsOneWidget);
    expect(find.text('3 / 24'), findsOneWidget);
    expect(find.text('지역 내 최대 24장'), findsOneWidget);
  });

  testWidgets('필름스트립은 활성 카테고리(관광지) 사진만 sequence 순으로 보여준다', (tester) async {
    await tester.pumpWidget(host());

    // 관광지로 분류되는 사진은 photo-1, photo-2 두 장뿐이라 필름스트립에는
    // 그 두 장만 렌더된다(총 사진 수는 여전히 3으로 카운터에 표시).
    expect(find.byType(Image), findsNWidgets(3)); // 큰 사진 1 + 필름스트립 2
  });

  testWidgets('카테고리 칩을 누르면 필름스트립이 해당 카테고리로 필터링된다', (tester) async {
    await tester.pumpWidget(host());
    expect(find.byType(Image), findsNWidgets(3)); // 큰 사진 1 + 관광지 2

    await tester.tap(find.text('식당'));
    await tester.pump();

    // 식당 카테고리는 photo-3 한 장뿐 → 큰 사진 1 + 필름스트립 1.
    expect(find.byType(Image), findsNWidgets(2));
  });

  testWidgets('사진이 없는 카테고리를 선택하면 안내 문구를 보여준다', (tester) async {
    await tester.pumpWidget(host());

    await tester.tap(find.text('카페'));
    await tester.pump();

    expect(find.text('이 카테고리에는 아직 사진이 없어요'), findsOneWidget);
  });
}
