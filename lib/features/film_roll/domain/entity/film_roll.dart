import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/shared/region/region_code.dart';

/// 필름롤 도메인 엔티티.
/// [totalPlaceCount]/[visitedPlaceCount]는 DB에 별도 컬럼으로 저장하지 않고
/// 조회 시점에 [FilmRollPlaces]를 집계해 계산한 값이다(중복 저장으로 인한 불일치 방지).
class FilmRoll {
  const FilmRoll({
    required this.id,
    required this.regionCode,
    required this.regionName,
    required this.title,
    required this.status,
    required this.totalPlaceCount,
    required this.visitedPlaceCount,
    required this.createdAt,
    required this.updatedAt,
    this.selectedCourseId,
    this.selectedCourseTitle,
    this.completedAt,
    this.regionId,
    this.serverFilmRollId,
    this.serverStatus,
  });

  /// 필름롤당 촬영 가능한 고정 노출수(실제 필름 카메라의 24매 필름 컨셉).
  static const int maxExposureCount = 24;

  final String id;
  final RegionCode regionCode;
  final String regionName;
  final String title;
  final FilmRollStatus status;
  final String? selectedCourseId;
  final String? selectedCourseTitle;
  final int totalPlaceCount;
  final int visitedPlaceCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? completedAt;

  /// 백엔드 지역 ID(`RegionsApi.resolveRegion`이 반환). 서버 필름롤 생성에 필요.
  final int? regionId;

  /// 연결된 서버 필름롤 PK. null이면 아직 서버에 생성되지 않은 상태.
  final int? serverFilmRollId;

  /// 마지막으로 미러링한 서버 필름롤 status 원문(CAPTURING 등).
  final String? serverStatus;

  /// 0.0 ~ 1.0 범위의 방문 진행률. 코스를 아직 선택하지 않았으면 0.
  double get progress =>
      totalPlaceCount == 0 ? 0 : visitedPlaceCount / totalPlaceCount;

  /// 완료 조건(코스 선택 + 전체 장소 방문)을 충족했는지 여부.
  bool get isCompletable =>
      selectedCourseId != null &&
      totalPlaceCount > 0 &&
      visitedPlaceCount >= totalPlaceCount;

  FilmRoll copyWith({
    String? selectedCourseId,
    String? selectedCourseTitle,
    FilmRollStatus? status,
    int? totalPlaceCount,
    int? visitedPlaceCount,
    DateTime? updatedAt,
    DateTime? completedAt,
    int? regionId,
    int? serverFilmRollId,
    String? serverStatus,
  }) {
    return FilmRoll(
      id: id,
      regionCode: regionCode,
      regionName: regionName,
      title: title,
      status: status ?? this.status,
      selectedCourseId: selectedCourseId ?? this.selectedCourseId,
      selectedCourseTitle: selectedCourseTitle ?? this.selectedCourseTitle,
      totalPlaceCount: totalPlaceCount ?? this.totalPlaceCount,
      visitedPlaceCount: visitedPlaceCount ?? this.visitedPlaceCount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      regionId: regionId ?? this.regionId,
      serverFilmRollId: serverFilmRollId ?? this.serverFilmRollId,
      serverStatus: serverStatus ?? this.serverStatus,
    );
  }
}
