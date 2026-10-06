import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_collection_screen.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FilmRoll _filmRoll({
  required String id,
  required String title,
  FilmRollStatus status = FilmRollStatus.inProgress,
}) {
  final now = DateTime(2026, 1, 1);
  return FilmRoll(
    id: id,
    regionCode: RegionCode.gongju,
    regionName: '공주시',
    title: title,
    status: status,
    totalPlaceCount: 3,
    visitedPlaceCount: 1,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  testWidgets('목록의 X 아이콘을 누르면 확인 다이얼로그를 거쳐 필름롤을 삭제한다', (tester) async {
    var filmRolls = [_filmRoll(id: 'roll-1', title: '공주 필름롤')];
    final deletedIds = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: FilmRollCollectionScreen(
          debugFetchFilmRolls: () async => filmRolls,
          debugDeleteFilmRoll: (id) async {
            deletedIds.add(id);
            filmRolls = filmRolls.where((roll) => roll.id != id).toList();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('공주 필름롤'), findsOneWidget);

    await tester.tap(find.widgetWithIcon(IconButton, Icons.delete_outline));
    await tester.pumpAndSettle();

    // 확인 다이얼로그가 뜨고, 아직 삭제되지 않았다.
    expect(find.text('필름롤 삭제'), findsOneWidget);
    expect(deletedIds, isEmpty);

    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(deletedIds, ['roll-1']);
    expect(find.text('공주 필름롤'), findsNothing);
    expect(find.text('아직 만든 필름롤이 없어요'), findsOneWidget);
  });

  testWidgets('삭제 확인 다이얼로그에서 취소하면 필름롤이 그대로 남는다', (tester) async {
    final filmRolls = [_filmRoll(id: 'roll-1', title: '공주 필름롤')];
    final deletedIds = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: FilmRollCollectionScreen(
          debugFetchFilmRolls: () async => filmRolls,
          debugDeleteFilmRoll: (id) async => deletedIds.add(id),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.delete_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(deletedIds, isEmpty);
    expect(find.text('공주 필름롤'), findsOneWidget);
  });

  testWidgets('현상 완료된 필름롤을 삭제할 때는 사진·릴스가 함께 사라진다고 안내한다', (tester) async {
    final filmRolls = [
      _filmRoll(
        id: 'roll-1',
        title: '공주 필름롤',
        status: FilmRollStatus.completed,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: FilmRollCollectionScreen(
          debugFetchFilmRolls: () async => filmRolls,
          debugDeleteFilmRoll: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.textContaining('필름 사진과 릴스도 함께 사라지며'), findsOneWidget);
  });

  testWidgets('삭제가 실패하면 목록은 그대로 두고 오류 안내를 보여준다', (tester) async {
    final filmRolls = [_filmRoll(id: 'roll-1', title: '공주 필름롤')];

    await tester.pumpWidget(
      MaterialApp(
        home: FilmRollCollectionScreen(
          debugFetchFilmRolls: () async => filmRolls,
          debugDeleteFilmRoll: (_) async => throw Exception('network error'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithIcon(IconButton, Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('삭제'));
    await tester.pumpAndSettle();

    expect(find.text('필름롤을 삭제하지 못했어요.'), findsOneWidget);
    expect(find.text('공주 필름롤'), findsOneWidget);
  });

  testWidgets('필름롤마다 방문 현황 오른쪽에 촬영한 사진 수를 n/24로 보여준다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FilmRollCollectionScreen(
          debugFetchFilmRolls: () async => [
            _filmRoll(id: 'roll-1', title: '공주 필름롤'),
            _filmRoll(
              id: 'roll-2',
              title: '부여 필름롤',
              status: FilmRollStatus.completed,
            ),
          ],
          debugCountPhotos: (id) async => id == 'roll-1' ? 5 : 12,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 3곳 방문 · 사진 5/24'), findsOneWidget);
    expect(find.text('1곳 방문 · 사진 12/24'), findsOneWidget);
  });

  testWidgets('사진 수를 세지 못한 필름롤은 사진 수 없이 상태만 보여준다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FilmRollCollectionScreen(
          debugFetchFilmRolls: () async => [
            _filmRoll(id: 'roll-1', title: '공주 필름롤'),
          ],
          debugCountPhotos: (_) async => throw Exception('DB 오류'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('공주 필름롤'), findsOneWidget);
    expect(find.text('1 / 3곳 방문'), findsOneWidget);
  });

  testWidgets('필름롤마다 상태 라벨과 대표 사진을 보여주고, 사진이 없으면 빈 필름 칸을 보여준다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FilmRollCollectionScreen(
          debugFetchFilmRolls: () async => [
            _filmRoll(id: 'roll-1', title: '공주 필름롤'),
            _filmRoll(
              id: 'roll-2',
              title: '부여 필름롤',
              status: FilmRollStatus.completed,
            ),
            _filmRoll(
              id: 'roll-3',
              title: '서산 필름롤',
              status: FilmRollStatus.developing,
            ),
            _filmRoll(
              id: 'roll-4',
              title: '예산 필름롤',
              status: FilmRollStatus.expired,
            ),
          ],
          debugFindCoverPhotoPath: (id) async =>
              id == 'roll-2' ? '/docs/thumbnail/cover.jpg' : null,
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['진행 중', '완료', '현상 중', '만료']) {
      expect(find.text(label), findsOneWidget);
    }
    final coverPaths = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as ResizeImage).imageProvider)
        .whereType<FileImage>()
        .map((provider) => provider.file.path);
    expect(coverPaths, ['/docs/thumbnail/cover.jpg']);
    expect(find.byIcon(Icons.camera_roll_outlined), findsNWidgets(3));
  });
}
