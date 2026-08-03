import 'dart:io';

import 'package:chaerok/core/config/app_preferences.dart';
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
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _testPlace = CourseCandidatePlace(
  name: '장소1',
  address: '주소1',
  category: '카테고리',
  latitude: 0,
  longitude: 0,
  visitOrder: 0,
);

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.dir);
  final Directory dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AppDatabase database;
  late FilmRollRepositoryImpl filmRollRepository;
  late FilmRollPlaceRepositoryImpl placeRepository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'current_user_id': 1});
    tempDir = await Directory.systemTemp.createTemp(
      'film_roll_repository_impl_test',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);
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
    await tempDir.delete(recursive: true);
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

  test('서로 다른 계정은 같은 지역에 각자 진행중 필름롤을 가질 수 있다', () async {
    final userAFilmRoll = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.yesan,
      regionName: '예산군',
    );

    await AppPreferences.instance.setCurrentUserId(2);
    final userBFilmRoll = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.yesan,
      regionName: '예산군',
    );

    expect(userBFilmRoll.id, isNot(userAFilmRoll.id));

    await AppPreferences.instance.setCurrentUserId(1);
    final userAAgain = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.yesan,
      regionName: '예산군',
    );
    expect(userAAgain.id, userAFilmRoll.id);
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
      courseId: 'course-1',
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

    await filmRollRepository.selectCourse(
      filmRollId: filmRoll.id,
      courseId: 'course-1',
      courseTitle: '테스트 코스',
      places: const [_testPlace],
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
      courseId: 'course-1',
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
      courseId: 'course-a',
      courseTitle: '코스 A',
      places: const [_testPlace],
    );
    final places = await placeRepository.findByFilmRoll(filmRoll.id);
    await placeRepository.markVisited(places.first.id);

    await expectLater(
      filmRollRepository.selectCourse(
        filmRollId: filmRoll.id,
        courseId: 'course-b',
        courseTitle: '코스 B',
        places: const [_testPlace],
      ),
      throwsA(isA<CourseChangeBlockedException>()),
    );
  });

  test('장소 구성이 같아도 courseId가 같으면 제목만 달라도 차단되지 않는다', () async {
    final filmRoll = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.gongju,
      regionName: '공주시',
    );
    await filmRollRepository.selectCourse(
      filmRollId: filmRoll.id,
      courseId: 'course-a',
      courseTitle: '코스 A',
      places: const [_testPlace],
    );
    final places = await placeRepository.findByFilmRoll(filmRoll.id);
    await placeRepository.markVisited(places.first.id);

    // title이 바뀌어도 courseId(같은 후보)가 같으면 재선택으로 취급해 차단하지 않는다.
    await filmRollRepository.selectCourse(
      filmRollId: filmRoll.id,
      courseId: 'course-a',
      courseTitle: '코스 A(수정된 제목)',
      places: const [_testPlace],
    );

    final updated = await filmRollRepository.findById(filmRoll.id);
    expect(updated!.selectedCourseTitle, '코스 A(수정된 제목)');
  });

  test('courseId가 다르면 title이 우연히 같아도 방문 기록이 있는 코스 변경이 차단된다', () async {
    final filmRoll = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.gongju,
      regionName: '공주시',
    );
    await filmRollRepository.selectCourse(
      filmRollId: filmRoll.id,
      courseId: 'course-a',
      courseTitle: '중복 제목',
      places: const [_testPlace],
    );
    final places = await placeRepository.findByFilmRoll(filmRoll.id);
    await placeRepository.markVisited(places.first.id);

    // title은 우연히 같지만 courseId가 다른, 실제로는 다른 후보 코스.
    await expectLater(
      filmRollRepository.selectCourse(
        filmRollId: filmRoll.id,
        courseId: 'course-b',
        courseTitle: '중복 제목',
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
      courseId: 'course-a',
      courseTitle: '코스 A',
      places: const [_testPlace],
    );

    await filmRollRepository.selectCourse(
      filmRollId: filmRoll.id,
      courseId: 'course-b',
      courseTitle: '코스 B',
      places: const [_testPlace],
    );

    final updated = await filmRollRepository.findById(filmRoll.id);
    expect(updated!.selectedCourseTitle, '코스 B');
  });

  test('deleteFilmRoll은 다른 계정 소유의 필름롤을 삭제하지 않는다', () async {
    final filmRoll = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.gongju,
      regionName: '공주시',
    );

    await AppPreferences.instance.setCurrentUserId(2);
    await filmRollRepository.deleteFilmRoll(filmRoll.id);

    await AppPreferences.instance.setCurrentUserId(1);
    expect(await filmRollRepository.findById(filmRoll.id), isNotNull);
  });

  test('deleteFilmRoll은 본인 소유의 필름롤을 정상적으로 삭제한다', () async {
    final filmRoll = await filmRollRepository.findOrCreateActiveByRegion(
      regionCode: RegionCode.gongju,
      regionName: '공주시',
    );

    await filmRollRepository.deleteFilmRoll(filmRoll.id);

    expect(await filmRollRepository.findById(filmRoll.id), isNull);
  });
}
