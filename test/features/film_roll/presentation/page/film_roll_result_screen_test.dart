import 'package:chaerok/data/models/film_roll_result_response.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_photo.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/repository/photo_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/cache_filtered_photos_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/get_film_roll_result_photos_use_case.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_result_photos_screen.dart';
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

class _FakePhotoRepository implements PhotoRepository {
  _FakePhotoRepository({
    this.filteredPaths = const {},
    this.localPhotos = const [],
  });

  final Map<int, String> filteredPaths;
  final List<FilmRollPhoto> localPhotos;
  final savedPhotoIds = <int>[];

  @override
  Future<Map<int, String>> findFilteredPhotoPaths(String filmRollId) async =>
      filteredPaths;

  @override
  Future<List<FilmRollPhoto>> findByFilmRoll(
    String filmRollId, {
    int? limit,
  }) async => localPhotos;

  @override
  Future<void> saveFilteredPhoto({
    required String filmRollId,
    required int serverPhotoId,
    required List<int> bytes,
  }) async {
    savedPhotoIds.add(serverPhotoId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

FilmRollPhoto _localPhoto(int sequence, {int? serverPhotoId}) {
  return FilmRollPhoto(
    id: 'ph-$sequence',
    filmRollId: 'fr-1',
    filmRollPlaceId: 'p-1',
    originalPath: '/docs/original/ph-$sequence.jpg',
    thumbnailPath: '/docs/thumbnail/ph-$sequence.jpg',
    takenAt: DateTime(2026, 9, 15, 10, sequence),
    sequence: sequence,
    serverPhotoId: serverPhotoId,
    isSynced: serverPhotoId != null,
  );
}

/// 보관 기간(현상 완료 후 48시간)이 지난 결과. 서버는 사진/릴스를 비워서 준다.
FilmRollResultResponse _retentionExpiredResult() {
  return FilmRollResultResponse(
    filmRollId: 900,
    status: 'EXPIRED',
    totalPhotoCount: 2,
    processedPhotoCount: 2,
    filteredPhotos: const [],
    completedAt: DateTime(2026, 9, 15, 12),
    expiresAt: DateTime(2026, 9, 17, 12),
  );
}

Widget _screen({
  FilmRollResultResponse? initialResult,
  Future<FilmRollResultResponse> Function(int filmRollId)? getFilmRollResult,
  required _FakePhotoRepository repository,
}) {
  return MaterialApp(
    home: FilmRollResultScreen(
      filmRoll: _filmRoll(),
      initialResult: initialResult,
      getFilmRollResult: getFilmRollResult,
      getResultPhotos: GetFilmRollResultPhotosUseCase(repository),
      cacheFilteredPhotos: CacheFilteredPhotosUseCase(
        repository,
        download: (url) async => [1, 2, 3],
      ),
    ),
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

  testWidgets('보관 기간 안이면 릴스를 언제까지 볼 수 있는지 보여주고 필터 사진을 기기에 보관한다', (
    tester,
  ) async {
    final repository = _FakePhotoRepository();
    final result = FilmRollResultResponse(
      filmRollId: 900,
      status: 'COMPLETED',
      totalPhotoCount: 2,
      processedPhotoCount: 2,
      filteredPhotos: [
        for (final id in [101, 102])
          FilteredPhotoResponse(
            photoId: id,
            sequence: id - 100,
            downloadUrl: 'https://example.com/photo-$id.jpg',
            downloadUrlExpiresAt: DateTime(2026, 9, 15, 13),
          ),
      ],
      reel: DownloadResponse(
        downloadUrl: 'https://example.com/reel.mp4',
        downloadUrlExpiresAt: DateTime(2026, 9, 15, 13),
        fileSize: 1024,
      ),
      completedAt: DateTime(2026, 9, 15, 12),
      expiresAt: DateTime(2026, 9, 17, 12, 5),
    );

    await tester.pumpWidget(
      _screen(initialResult: result, repository: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('9월 17일 12:05까지 볼 수 있어요'), findsOneWidget);
    expect(find.text('필터 미적용'), findsNothing);
    expect(repository.savedPhotoIds, [101, 102]);
  });

  testWidgets('보관 기간이 지나면 릴스 보관 종료를 안내하고 저장/공유를 막되, 기기 사진은 계속 보여준다', (
    tester,
  ) async {
    final repository = _FakePhotoRepository(
      filteredPaths: {101: '/docs/filtered/101.jpg'},
      localPhotos: [
        _localPhoto(1, serverPhotoId: 101),
        _localPhoto(2, serverPhotoId: 102),
      ],
    );

    // 필름 컬렉션에서 다시 여는 경로: 화면이 직접 조회해 EXPIRED를 받는다.
    await tester.pumpWidget(
      _screen(
        getFilmRollResult: (id) async => _retentionExpiredResult(),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('필름롤 결과를 불러오지 못했어요.'), findsNothing);
    expect(find.text('릴스 보관 기간이 끝났어요. 촬영한 사진은 계속 볼 수 있어요.'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_fill), findsNothing);
    expect(find.text('방문 3곳 · 촬영 2장'), findsOneWidget);

    final saveButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, '저장하기'),
    );
    final shareButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, '공유하기'),
    );
    expect(saveButton.onPressed, isNull);
    expect(shareButton.onPressed, isNull);

    // 대표 사진(1/2)은 보관한 필터 사진, 미리보기 둘째 칸은 촬영 원본이다.
    expect(find.text('1/2'), findsOneWidget);
    final imagePaths = tester
        .widgetList<Image>(find.byType(Image))
        .map((image) => (image.image as FileImage).file.path);
    expect(imagePaths, contains('/docs/filtered/101.jpg'));
    expect(imagePaths, contains('/docs/original/ph-2.jpg'));
    // 원본으로 대체된 사진에만 라벨이 붙는다(이 시점엔 미리보기 둘째 칸 하나).
    expect(find.text('필터 미적용'), findsOneWidget);
    expect(repository.savedPhotoIds, isEmpty);
  });

  testWidgets('보관 기간이 지난 뒤 전체 사진 화면에서도 원본으로 대체된 사진에 필터 미적용을 표시한다', (
    tester,
  ) async {
    final repository = _FakePhotoRepository(
      filteredPaths: {101: '/docs/filtered/101.jpg'},
      localPhotos: [
        _localPhoto(1, serverPhotoId: 101),
        _localPhoto(2, serverPhotoId: 102),
      ],
    );

    await tester.pumpWidget(
      _screen(initialResult: _retentionExpiredResult(), repository: repository),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('전체 >'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('전체 >'));
    await tester.pumpAndSettle();

    expect(find.byType(FilmRollResultPhotosScreen), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FilmRollResultPhotosScreen),
        matching: find.byType(Image),
      ),
      findsNWidgets(2),
    );
    expect(
      find.descendant(
        of: find.byType(FilmRollResultPhotosScreen),
        matching: find.text('필터 미적용'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('현상된 적 없이 종료된 필름롤(completedAt 없음)은 보관 종료 문구를 쓰지 않는다', (
    tester,
  ) async {
    const result = FilmRollResultResponse(
      filmRollId: 900,
      status: 'EXPIRED',
      totalPhotoCount: 1,
      processedPhotoCount: 0,
      filteredPhotos: [],
    );

    await tester.pumpWidget(
      _screen(
        initialResult: result,
        repository: _FakePhotoRepository(localPhotos: [_localPhoto(1)]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('릴스 보관 기간이 끝났어요. 촬영한 사진은 계속 볼 수 있어요.'), findsNothing);
    expect(find.text('현상된 릴스가 없어요. 촬영한 사진은 계속 볼 수 있어요.'), findsOneWidget);
    expect(find.text('필터 미적용'), findsWidgets);
  });
}
