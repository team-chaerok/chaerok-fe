import 'package:chaerok/core/database/local_database.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';

/// Drift Row([FilmRollRow]) ↔ 도메인 엔티티([FilmRoll]) 매핑.
extension FilmRollMapper on FilmRollRow {
  /// [totalPlaceCount]/[visitedPlaceCount]는 저장된 컬럼이 아니라 호출부에서
  /// `film_roll_place_places` 집계를 통해 계산해 전달해야 한다.
  FilmRoll toEntity({
    required int totalPlaceCount,
    required int visitedPlaceCount,
  }) {
    return FilmRoll(
      id: id,
      regionCode: regionCode,
      regionName: regionName,
      title: title,
      status: status,
      selectedCourseId: selectedCourseId,
      selectedCourseTitle: selectedCourseTitle,
      totalPlaceCount: totalPlaceCount,
      visitedPlaceCount: visitedPlaceCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
      completedAt: completedAt,
      regionId: regionId,
      serverFilmRollId: serverFilmRollId,
      serverStatus: serverStatus,
      developAvailableAt: developAvailableAt,
    );
  }
}
