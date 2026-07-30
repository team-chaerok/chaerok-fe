import 'dart:io';

import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/core/file/local_photo_storage.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/film_roll_place_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/local/photo_local_data_source.dart';
import 'package:chaerok/features/film_roll/data/repository/film_roll_repository_impl.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/usecase/recover_last_active_film_roll_use_case.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakePathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProviderPlatform(this.dir);
  final Directory dir;

  @override
  Future<String?> getApplicationDocumentsPath() async => dir.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('삭제된 필름롤이 마지막 활성 ID로 남아있어도(정리 단계 실패 등) '
      '앱 시작 시 복구 유스케이스가 이를 감지해 null로 정리한다', () async {
    SharedPreferences.setMockInitialValues({
      'last_active_film_roll_id': 'roll-1',
    });
    final tempDir = await Directory.systemTemp.createTemp(
      'recover_use_case_test',
    );
    PathProviderPlatform.instance = _FakePathProviderPlatform(tempDir);

    final database = AppDatabase.forTesting(NativeDatabase.memory());
    final now = DateTime.now();
    await database
        .into(database.filmRolls)
        .insert(
          FilmRollsCompanion.insert(
            id: 'roll-1',
            regionCode: RegionCode.gongju,
            regionName: '공주시',
            title: '공주',
            status: FilmRollStatus.inProgress,
            createdAt: now,
            updatedAt: now,
          ),
        );

    final repository = FilmRollRepositoryImpl(
      database: database,
      filmRollDataSource: FilmRollLocalDataSource(database),
      placeDataSource: FilmRollPlaceLocalDataSource(database),
      photoDataSource: PhotoLocalDataSource(database),
      photoStorage: LocalPhotoStorage.instance,
    );

    // DeleteFilmRollUseCase의 환경설정 정리 단계가 실패한 것과 동일한
    // 상태를 재현한다: DB에서는 필름롤이 삭제됐지만 마지막 활성 ID
    // preference는 여전히 그 값을 가리킨다(stale).
    await repository.deleteFilmRoll('roll-1');

    final preferences = AppPreferences.instance;
    expect(await preferences.getLastActiveFilmRollId(), 'roll-1');

    final recoverUseCase = RecoverLastActiveFilmRollUseCase(
      filmRollRepository: repository,
      appPreferences: preferences,
    );
    final recovered = await recoverUseCase.call();

    expect(recovered, isNull);
    expect(await preferences.getLastActiveFilmRollId(), isNull);

    await database.close();
    await tempDir.delete(recursive: true);
  });
}
