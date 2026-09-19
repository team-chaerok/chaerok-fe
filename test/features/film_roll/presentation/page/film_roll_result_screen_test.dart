import 'package:chaerok/data/models/film_roll_result_response.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_result_screen.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FilmRoll _filmRoll() {
  final now = DateTime(2026, 9, 15);
  return FilmRoll(
    id: 'fr-1',
    regionCode: RegionCode.gongju,
    regionName: '공주시',
    title: '공주 필름롤',
    status: FilmRollStatus.completed,
    totalPlaceCount: 3,
    visitedPlaceCount: 3,
    createdAt: now,
    updatedAt: now,
    serverFilmRollId: 900,
    completedAt: DateTime(2026, 9, 15, 12),
  );
}

void main() {
  testWidgets('목업 데이터를 기준으로 타이틀/지역/카운트/사진/릴스 섹션을 렌더링한다', (tester) async {
    final result = FilmRollResultResponse(
      filmRollId: 900,
      status: 'COMPLETED',
      totalPhotoCount: 12,
      processedPhotoCount: 12,
      filteredPhotos: List.generate(
        12,
        (i) => FilteredPhotoResponse(
          photoId: i,
          sequence: i + 1,
          downloadUrl: 'https://example.com/photo-$i.jpg',
          downloadUrlExpiresAt: DateTime(2026, 9, 15, 13),
        ),
      ),
      reel: DownloadResponse(
        downloadUrl: 'https://example.com/reel.mp4',
        downloadUrlExpiresAt: DateTime(2026, 9, 15, 13),
        fileSize: 1024,
      ),
      completedAt: DateTime(2026, 9, 15, 12),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FilmRollResultScreen(
          filmRoll: _filmRoll(),
          initialResult: result,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('공주 필름롤'), findsOneWidget);
    expect(find.text('GONGJU · 공주'), findsOneWidget);
    expect(find.text('2026.09.15'), findsOneWidget);
    expect(find.text('방문 3곳 · 촬영 12장'), findsOneWidget);
    expect(find.text('오늘의 사진'), findsOneWidget);
    expect(find.text('오늘의 릴스'), findsOneWidget);
    expect(find.text('저장하기'), findsOneWidget);
    expect(find.text('공유하기'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
  });

  testWidgets('대표 사진을 좌우로 스와이프하면 sequence 오름차순(코스 순서)으로 전환된다', (tester) async {
    final result = FilmRollResultResponse(
      filmRollId: 900,
      status: 'COMPLETED',
      totalPhotoCount: 3,
      processedPhotoCount: 3,
      // 역순으로 내려와도 sequence 기준으로 재정렬돼야 한다.
      filteredPhotos: [
        FilteredPhotoResponse(
          photoId: 3,
          sequence: 3,
          downloadUrl: 'https://example.com/cafe.jpg',
          downloadUrlExpiresAt: DateTime(2026, 9, 15, 13),
        ),
        FilteredPhotoResponse(
          photoId: 1,
          sequence: 1,
          downloadUrl: 'https://example.com/tourism.jpg',
          downloadUrlExpiresAt: DateTime(2026, 9, 15, 13),
        ),
        FilteredPhotoResponse(
          photoId: 2,
          sequence: 2,
          downloadUrl: 'https://example.com/food.jpg',
          downloadUrlExpiresAt: DateTime(2026, 9, 15, 13),
        ),
      ],
      completedAt: DateTime(2026, 9, 15, 12),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FilmRollResultScreen(
          filmRoll: _filmRoll(),
          initialResult: result,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1/3'), findsOneWidget);

    String currentPageImageUrl() {
      final image = tester.widget<Image>(
        find.descendant(
          of: find.byType(PageView),
          matching: find.byType(Image),
        ),
      );
      return (image.image as NetworkImage).url;
    }

    expect(currentPageImageUrl(), 'https://example.com/tourism.jpg');

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('2/3'), findsOneWidget);
    expect(currentPageImageUrl(), 'https://example.com/food.jpg');

    await tester.fling(find.byType(PageView), const Offset(-600, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('3/3'), findsOneWidget);
    expect(currentPageImageUrl(), 'https://example.com/cafe.jpg');
  });

  testWidgets('릴스가 없으면 저장/공유 버튼이 비활성화된다', (tester) async {
    const result = FilmRollResultResponse(
      filmRollId: 900,
      status: 'COMPLETED',
      totalPhotoCount: 0,
      processedPhotoCount: 0,
      filteredPhotos: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FilmRollResultScreen(
          filmRoll: _filmRoll(),
          initialResult: result,
        ),
      ),
    );
    await tester.pump();

    final saveButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '저장하기'),
    );
    final shareButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '공유하기'),
    );
    expect(saveButton.onPressed, isNull);
    expect(shareButton.onPressed, isNull);
  });
}
