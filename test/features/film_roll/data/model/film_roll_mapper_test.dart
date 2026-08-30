import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/data/model/film_roll_mapper.dart';
import 'package:chaerok/features/film_roll/data/model/film_roll_place_mapper.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FilmRollMapper.toEntity가 서버 동기화 필드를 매핑한다', () {
    final row = FilmRollRow(
      id: 'r1',
      userId: 7,
      regionCode: RegionCode.buyeo,
      regionName: '부여군',
      title: '부여 필름롤',
      status: FilmRollStatus.inProgress,
      createdAt: DateTime(2026, 8, 30),
      updatedAt: DateTime(2026, 8, 30),
      regionId: 22,
      serverFilmRollId: 555,
      serverStatus: 'CAPTURING',
    );

    final entity = row.toEntity(totalPlaceCount: 0, visitedPlaceCount: 0);

    expect(entity.regionId, 22);
    expect(entity.serverFilmRollId, 555);
    expect(entity.serverStatus, 'CAPTURING');
  });

  test('FilmRollMapper.toEntity: 서버 미연동 행은 null로 매핑된다', () {
    final row = FilmRollRow(
      id: 'r2',
      regionCode: RegionCode.gongju,
      regionName: '공주시',
      title: '공주 필름롤',
      status: FilmRollStatus.inProgress,
      createdAt: DateTime(2026, 8, 30),
      updatedAt: DateTime(2026, 8, 30),
    );

    final entity = row.toEntity(totalPlaceCount: 0, visitedPlaceCount: 0);

    expect(entity.regionId, isNull);
    expect(entity.serverFilmRollId, isNull);
    expect(entity.serverStatus, isNull);
  });

  test('FilmRollPlaceMapper.toEntity가 visitSyncedAt을 매핑한다', () {
    final syncedAt = DateTime(2026, 8, 30, 12);
    final row = FilmRollPlaceRow(
      id: 'p1',
      filmRollId: 'r1',
      name: '장소1',
      address: '주소1',
      category: '카테고리',
      latitude: 36.0,
      longitude: 126.0,
      visitOrder: 0,
      isVisited: true,
      visitSyncedAt: syncedAt,
    );

    final entity = row.toEntity(photoCount: 0);

    expect(entity.visitSyncedAt, syncedAt);
  });
}
