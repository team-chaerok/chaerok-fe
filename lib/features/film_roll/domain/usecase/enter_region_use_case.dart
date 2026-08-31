import 'dart:async';

import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_service.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/shared/region/region_normalizer.dart';

/// 행정구역명을 정규화해 지원 지역인지 확인하고, 해당 지역의 진행중 필름롤을
/// 찾거나 새로 생성한다. 성공 시 앱 재시작 복구를 위해 마지막 필름롤 ID를 저장하고,
/// 백엔드 동기화(서버 필름롤 생성)를 백그라운드로 시도한다.
class EnterRegionUseCase {
  const EnterRegionUseCase({
    required FilmRollRepository filmRollRepository,
    required FilmRollSyncService syncService,
    AppPreferences? appPreferences,
  }) : _filmRollRepository = filmRollRepository,
       _syncService = syncService,
       _appPreferences = appPreferences;

  final FilmRollRepository _filmRollRepository;
  final FilmRollSyncService _syncService;
  final AppPreferences? _appPreferences;

  Future<FilmRoll> call(String cityCountyName, {required int regionId}) async {
    final regionCode = RegionNormalizer.fromCityCountyName(cityCountyName);
    if (regionCode == null) {
      throw UnsupportedRegionException(cityCountyName);
    }

    final filmRoll = await _filmRollRepository.findOrCreateActiveByRegion(
      regionCode: regionCode,
      regionName: cityCountyName,
      regionId: regionId,
    );

    final preferences = _appPreferences ?? AppPreferences.instance;
    await preferences.setLastActiveFilmRollId(filmRoll.id);

    // 서버 필름롤 생성은 best-effort. 실패해도 로컬 진입은 그대로 진행한다.
    unawaited(_syncService.syncFilmRoll(filmRoll.id));

    return filmRoll;
  }
}
