import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/data/models/o_auth_login_request.dart';
import 'package:chaerok/data/models/user_response.dart';
import 'package:chaerok/features/auth/data/current_account_sync.dart';
import 'package:chaerok/features/film_roll/domain/entity/course_candidate_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeFilmRollRepository implements FilmRollRepository {
  int claimCallCount = 0;
  int? claimedUserId;

  @override
  Future<void> claimLegacyData(int userId) async {
    claimCallCount++;
    claimedUserId = userId;
  }

  @override
  Future<void> completeFilmRoll(String filmRollId) =>
      throw UnimplementedError();

  @override
  Future<void> deleteFilmRoll(String filmRollId) => throw UnimplementedError();

  @override
  Future<List<FilmRoll>> findAll() => throw UnimplementedError();

  @override
  Future<FilmRoll?> findById(String filmRollId) => throw UnimplementedError();

  @override
  Future<FilmRoll> findOrCreateActiveByRegion({
    required RegionCode regionCode,
    required String regionName,
  }) => throw UnimplementedError();

  @override
  Future<void> selectCourse({
    required String filmRollId,
    required String courseId,
    required String courseTitle,
    required List<CourseCandidatePlace> places,
  }) => throw UnimplementedError();

  @override
  Stream<FilmRoll?> watchById(String filmRollId) => throw UnimplementedError();
}

const _testUser = UserResponse(
  id: 42,
  provider: OAuthProvider.kakao,
  nickname: '테스터',
  email: null,
  role: UserRole.user,
);

void main() {
  late _FakeFilmRollRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = _FakeFilmRollRepository();
  });

  test('로컬에 저장된 계정 id가 없으면 서버에서 조회해 저장하고 레거시 데이터를 귀속시킨다', () async {
    await CurrentAccountSync.sync(
      fetchCurrentUser: () async => _testUser,
      filmRollRepository: repository,
    );

    expect(repository.claimCallCount, 1);
    expect(repository.claimedUserId, 42);
    expect(await AppPreferences.instance.getCurrentUserId(), 42);
  });

  test('로컬에 이미 계정 id가 있으면 네트워크 조회/귀속 없이 그대로 둔다', () async {
    await AppPreferences.instance.setCurrentUserId(7);

    await CurrentAccountSync.sync(
      fetchCurrentUser: () async {
        fail('이미 계정을 알고 있으면 서버 조회를 호출하면 안 된다');
      },
      filmRollRepository: repository,
    );

    expect(repository.claimCallCount, 0);
    expect(await AppPreferences.instance.getCurrentUserId(), 7);
  });

  test('서버 조회가 실패해도 예외를 밖으로 던지지 않고 계정 id를 갱신하지 않는다', () async {
    await CurrentAccountSync.sync(
      fetchCurrentUser: () async => throw Exception('네트워크 오류'),
      filmRollRepository: repository,
    );

    expect(repository.claimCallCount, 0);
    expect(await AppPreferences.instance.getCurrentUserId(), isNull);
  });
}
