import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/file/local_photo_storage.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_place_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_place_repository_impl.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_repository_impl.dart';
import 'package:chaerok/features/film_roll/domain/entity/course_candidate_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _testPlace = CourseCandidatePlace(
  name: '장소1',
  address: '주소1',
  category: '카테고리',
  latitude: 0,
  longitude: 0,
  visitOrder: 0,
);

void main() {
  late AppDatabase database;
  late FilmRollRepositoryImpl filmRollRepository;
  late FilmRollPlaceRepositoryImpl placeRepository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    filmRollRepository = FilmRollRepositoryImpl(
      database: database,
      filmRollDataSource: FilmRollLocalDataSource(database),
      placeDataSource: FilmRollPlaceLocalDataSource(database),
      photoDataSource: PhotoLocalDataSource(database),
      photoStorage: LocalPhotoStorage.instance,
    );
    placeRepository = FilmRollPlaceRepositoryImpl(
      placeDataSource: FilmRollPlaceLocalDataSource(database),
      photoDataSource: PhotoLocalDataSource(database),
    );
  });

  tearDown(() async {
    await database.close();
  });

  test('같은 지역에 여러 번 진입해도 진행중 필름롤은 1개만 생성된다', () async {
    final first = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.gongju,
      regionName: '공주시',
    );
    final second = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.gongju,
      regionName: '공주시',
    );

    expect(second.id, first.id);
  });

  test('동시에 findOrCreate를 호출해도 진행중 필름롤은 1개만 생성된다', () async {
    final results = await Future.wait([
      filmRollRepository.findOrCreateActiveByRegion(
        regionCode: RegionCode.buyeo,
        regionName: '부여군',
      ),
      filmRollRepository.findOrCreateActiveByRegion(
        regionCode: RegionCode.buyeo,
        regionName: '부여군',
      ),
      filmRollRepository.findOrCreateActiveByRegion(
        regionCode: RegionCode.buyeo,
        regionName: '부여군',
      ),
    ]);

    final ids = results.map((filmRoll) => filmRoll.id).toSet();
    expect(ids, hasLength(1));
  });

  test('방문 인증을 여러 번 호출해도 visitedPlaceCount는 1회만 증가한다', () async {
    final filmRoll = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.seosan,
      regionName: '서산시',
    );
    await filmRollRepository.selectCourse(
      filmRollId: filmRoll.id,
      courseTitle: '테스트 코스',
      places: const [_testPlace],
    );
    final places = await placeRepository.findByFilmRoll(filmRoll.id);
    final placeId = places.first.id;

    await placeRepository.markVisited(placeId);
    await placeRepository.markVisited(placeId);
    await placeRepository.markVisited(placeId);

    final updated = await filmRollRepository.findById(filmRoll.id);
    expect(updated!.visitedPlaceCount, 1);
  });

  test('완료 조건(코스 선택 + 전체 방문)을 충족하지 못하면 완료가 차단된다', () async {
    final filmRoll = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.yesan,
      regionName: '예산군',
    );

    await expectLater(
      filmRollRepository.completeFilmRoll(filmRoll.id),
      throwsA(isA<FilmRollNotCompletableException>()),
    );
  });

  test('완료 조건을 충족하면 필름롤이 completed 상태가 된다', () async {
    final filmRoll = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.yesan,
      regionName: '예산군',
    );
    await filmRollRepository.selectCourse(
      filmRollId: filmRoll.id,
      courseTitle: '테스트 코스',
      places: const [_testPlace],
    );
    final places = await placeRepository.findByFilmRoll(filmRoll.id);
    await placeRepository.markVisited(places.first.id);

    await filmRollRepository.completeFilmRoll(filmRoll.id);

    final completed = await filmRollRepository.findById(filmRoll.id);
    expect(completed!.status, FilmRollStatus.completed);
  });

  test('방문 기록이 있는 상태에서 다른 코스로 변경하면 차단된다', () async {
    final filmRoll = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.gongju,
      regionName: '공주시',
    );
    await filmRollRepository.selectCourse(
      filmRollId: filmRoll.id,
      courseTitle: '코스 A',
      places: const [_testPlace],
    );
    final places = await placeRepository.findByFilmRoll(filmRoll.id);
    await placeRepository.markVisited(places.first.id);

    await expectLater(
      filmRollRepository.selectCourse(
        filmRollId: filmRoll.id,
        courseTitle: '코스 B',
        places: const [_testPlace],
      ),
      throwsA(isA<CourseChangeBlockedException>()),
    );
  });

  test('방문 기록이 없으면 다른 코스로 자유롭게 교체할 수 있다', () async {
    final filmRoll = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.gongju,
      regionName: '공주시',
    );
    await filmRollRepository.selectCourse(
      filmRollId: filmRoll.id,
      courseTitle: '코스 A',
      places: const [_testPlace],
    );

    await filmRollRepository.selectCourse(
      filmRollId: filmRoll.id,
      courseTitle: '코스 B',
      places: const [_testPlace],
    );

    final updated = await filmRollRepository.findById(filmRoll.id);
    expect(updated!.selectedCourseTitle, '코스 B');
  });
}
