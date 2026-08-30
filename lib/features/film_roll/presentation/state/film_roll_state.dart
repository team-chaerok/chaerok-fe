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
  });

  const FilmRollState.initial() : this(status: FilmRollLoadStatus.loading);

  final FilmRollLoadStatus status;
  final FilmRoll? filmRoll;
  final List<FilmRollPlace> places;
  final String? errorMessage;

  /// 직전 백엔드 동기화 시도가 부분 실패했는지 여부(재시도 어피던스 노출용).
  final bool lastSyncHadError;

  bool get hasSelectedCourse => filmRoll?.selectedCourseId != null;

  FilmRollState copyWith({
    FilmRollLoadStatus? status,
    FilmRoll? filmRoll,
    List<FilmRollPlace>? places,
    String? errorMessage,
    bool? lastSyncHadError,
  }) {
    return FilmRollState(
      status: status ?? this.status,
      filmRoll: filmRoll ?? this.filmRoll,
      places: places ?? this.places,
      errorMessage: errorMessage,
      lastSyncHadError: lastSyncHadError ?? this.lastSyncHadError,
    );
  }
}
