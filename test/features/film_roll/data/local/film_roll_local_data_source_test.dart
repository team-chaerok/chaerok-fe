import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_local_data_source.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _insertFilmRoll(
  AppDatabase database, {
  required String id,
  int? userId,
  RegionCode regionCode = RegionCode.gongju,
}) {
  final now = DateTime.now();
  return database
      .into(database.filmRolls)
      .insert(
        FilmRollsCompanion.insert(
          id: id,
          userId: userId == null ? const Value.absent() : Value(userId),
          regionCode: regionCode,
          regionName: '공주시',
          title: '공주',
          status: FilmRollStatus.inProgress,
          createdAt: now,
          updatedAt: now,
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late FilmRollLocalDataSource dataSource;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    database = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = FilmRollLocalDataSource(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('findAll은 현재 로그인 계정 소유의 필름롤만 반환한다', () async {
    await _insertFilmRoll(database, id: 'kakao-roll', userId: 1);
    await _insertFilmRoll(
      database,
      id: 'google-roll',
      userId: 2,
      regionCode: RegionCode.buyeo,
    );

    await AppPreferences.instance.setCurrentUserId(2);
    final googleAccountRolls = await dataSource.findAll();
    expect(googleAccountRolls.map((r) => r.id), ['google-roll']);

    await AppPreferences.instance.setCurrentUserId(1);
    final kakaoAccountRolls = await dataSource.findAll();
    expect(kakaoAccountRolls.map((r) => r.id), ['kakao-roll']);
  });

  test('findById는 다른 계정 소유의 필름롤 id를 조회하면 null을 반환한다', () async {
    await _insertFilmRoll(database, id: 'kakao-roll', userId: 1);

    await AppPreferences.instance.setCurrentUserId(2);
    expect(await dataSource.findById('kakao-roll'), isNull);

    await AppPreferences.instance.setCurrentUserId(1);
    expect(await dataSource.findById('kakao-roll'), isNotNull);
  });

  test('findActiveByRegion은 다른 계정 소유의 진행중 필름롤을 무시한다', () async {
    await _insertFilmRoll(database, id: 'kakao-roll', userId: 1);

    await AppPreferences.instance.setCurrentUserId(2);
    expect(await dataSource.findActiveByRegion(RegionCode.gongju), isNull);
  });

  test('현재 계정을 알 수 없으면 전체 대신 빈 결과를 반환한다', () async {
    await _insertFilmRoll(database, id: 'kakao-roll', userId: 1);

    expect(await AppPreferences.instance.getCurrentUserId(), isNull);
    expect(await dataSource.findAll(), isEmpty);
    expect(await dataSource.findById('kakao-roll'), isNull);
  });

  test('watchById는 구독 이후 발생하는 변경마다 현재 계정을 다시 확인한다', () async {
    await _insertFilmRoll(database, id: 'kakao-roll', userId: 1);
    await AppPreferences.instance.setCurrentUserId(1);

    final events = <FilmRollRow?>[];
    final subscription = dataSource.watchById('kakao-roll').listen(events.add);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(events, [predicate<FilmRollRow?>((row) => row?.id == 'kakao-roll')]);

    // DB에 변경이 없으면 계정만 바꿔도 새 이벤트가 발생하지 않는다(drift
    // watch는 테이블 변경을 트리거로 삼기 때문). 그래서 계정 전환 뒤
    // 아무 갱신이나 발생시켜 스트림이 재평가되도록 만든다.
    await AppPreferences.instance.setCurrentUserId(2);
    await dataSource.update(
      'kakao-roll',
      const FilmRollsCompanion(title: Value('업데이트된 제목')),
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    await subscription.cancel();
    expect(events.last, isNull);
  });

  test('claimLegacyData은 계정이 비어있는 레거시 행만 지정한 계정으로 확정한다', () async {
    await _insertFilmRoll(database, id: 'legacy-roll'); // userId: null
    await _insertFilmRoll(
      database,
      id: 'already-claimed-roll',
      userId: 2,
      regionCode: RegionCode.buyeo,
    );

    await dataSource.claimLegacyData(1);

    await AppPreferences.instance.setCurrentUserId(1);
    expect(await dataSource.findById('legacy-roll'), isNotNull);
    expect(await dataSource.findById('already-claimed-roll'), isNull);

    await AppPreferences.instance.setCurrentUserId(2);
    expect(await dataSource.findById('legacy-roll'), isNull);
    expect(await dataSource.findById('already-claimed-roll'), isNotNull);
  });
}
