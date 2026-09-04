import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/visit_category_progress.dart';
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
    this.developAvailableAt,
    this.visitRequirementMet,
    this.visitedCategoryCount,
    this.requiredCategoryCount,
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

  /// 지역 이탈 확정([FilmRollStatus.developing]) 시 서버가 알려준 현상 완료
  /// 예정 시각. developing 상태에서만 값이 있다.
  final DateTime? developAvailableAt;

  /// 백엔드 지역 ID(`RegionsApi.resolveRegion`이 반환). 서버 필름롤 생성에 필요.
  final int? regionId;

  /// 연결된 서버 필름롤 PK. null이면 아직 서버에 생성되지 않은 상태.
  final int? serverFilmRollId;

  /// 마지막으로 미러링한 서버 필름롤 status 원문(CAPTURING 등).
  final String? serverStatus;

  /// 서버가 판정한 현상(완료) 조건 충족 여부(`VisitsApi.getVisits`의
  /// `visitRequirementMet`). 아직 조회하지 않았으면 null.
  final bool? visitRequirementMet;

  /// 서버가 집계한, 방문한 서로 다른 관광 유형 수. 아직 조회하지 않았으면 null.
  final int? visitedCategoryCount;

  /// 현상 조건을 충족하는 데 필요한 관광 유형 수. 아직 조회하지 않았으면 null.
  final int? requiredCategoryCount;

  /// 0.0 ~ 1.0 범위의 방문 진행률. 코스를 아직 선택하지 않았으면 0.
  double get progress =>
      totalPlaceCount == 0 ? 0 : visitedPlaceCount / totalPlaceCount;

  /// 현상(완료) 가능 여부. 서버 판정([visitRequirementMet])을 우선 신뢰하고,
  /// 아직 서버와 동기화되지 않아 값이 없으면 [places]의 로컬 방문 기록으로
  /// 근사 판정한다(서로 다른 관광 유형 [requiredVisitCategoryCount]개 이상).
  bool isCompletable(List<FilmRollPlace> places) =>
      selectedCourseId != null &&
      (visitRequirementMet ?? hasMetLocalCategoryRequirement(places));

  /// 지역 이탈이 확정되어 현상 완료를 기다리는 중인지 여부.
  bool get isDeveloping => status == FilmRollStatus.developing;

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
    DateTime? developAvailableAt,
    bool? visitRequirementMet,
    int? visitedCategoryCount,
    int? requiredCategoryCount,
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
      developAvailableAt: developAvailableAt ?? this.developAvailableAt,
      visitRequirementMet: visitRequirementMet ?? this.visitRequirementMet,
      visitedCategoryCount: visitedCategoryCount ?? this.visitedCategoryCount,
      requiredCategoryCount:
          requiredCategoryCount ?? this.requiredCategoryCount,
    );
  }
}
