import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';

/// Drift Row([FilmRollPlaceRow]) ↔ 도메인 엔티티([FilmRollPlace]) 매핑.
extension FilmRollPlaceMapper on FilmRollPlaceRow {
  /// [photoCount]는 저장된 컬럼이 아니라 호출부에서 `photos` 집계를 통해 계산해 전달해야 한다.
  FilmRollPlace toEntity({required int photoCount}) {
    return FilmRollPlace(
      id: id,
      filmRollId: filmRollId,
      serverPlaceId: serverPlaceId,
      externalPlaceId: externalPlaceId,
      name: name,
      address: address,
      category: category,
      latitude: latitude,
      longitude: longitude,
      imageUrl: imageUrl,
      visitOrder: visitOrder,
      isVisited: isVisited,
      visitedAt: visitedAt,
      visitSyncedAt: visitSyncedAt,
      photoCount: photoCount,
    );
  }
}
