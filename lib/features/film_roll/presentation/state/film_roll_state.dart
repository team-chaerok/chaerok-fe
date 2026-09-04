import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';

enum FilmRollLoadStatus { loading, loaded, error }

/// [FilmRollController]가 관리하는 필름롤 상세 화면의 상태.
class FilmRollState {
  const FilmRollState({
    required this.status,
    this.filmRoll,
    this.places = const [],
    this.errorMessage,
    this.lastSyncHadError = false,
    this.isLoadingVisits = false,
    this.visitsLoadFailed = false,
  });

  const FilmRollState.initial() : this(status: FilmRollLoadStatus.loading);

  final FilmRollLoadStatus status;
  final FilmRoll? filmRoll;
  final List<FilmRollPlace> places;
  final String? errorMessage;

  /// 직전 백엔드 동기화 시도가 부분 실패했는지 여부(재시도 어피던스 노출용).
  final bool lastSyncHadError;

  /// 현상 조건 조회(`VisitsApi.getVisits`)가 진행 중인지 여부.
  final bool isLoadingVisits;

  /// 직전 현상 조건 조회가 실패했는지 여부.
  final bool visitsLoadFailed;

  bool get hasSelectedCourse => filmRoll?.selectedCourseId != null;

  FilmRollState copyWith({
    FilmRollLoadStatus? status,
    FilmRoll? filmRoll,
    List<FilmRollPlace>? places,
    String? errorMessage,
    bool? lastSyncHadError,
    bool? isLoadingVisits,
    bool? visitsLoadFailed,
  }) {
    return FilmRollState(
      status: status ?? this.status,
      filmRoll: filmRoll ?? this.filmRoll,
      places: places ?? this.places,
      errorMessage: errorMessage,
      lastSyncHadError: lastSyncHadError ?? this.lastSyncHadError,
      isLoadingVisits: isLoadingVisits ?? this.isLoadingVisits,
      visitsLoadFailed: visitsLoadFailed ?? this.visitsLoadFailed,
    );
  }
}
