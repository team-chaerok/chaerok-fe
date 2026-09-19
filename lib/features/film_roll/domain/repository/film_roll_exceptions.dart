/// 방문/사진 기록이 있는 상태에서 코스 변경을 시도할 때 발생하는 예외(안전 기본값 정책).
class CourseChangeBlockedException implements Exception {
  const CourseChangeBlockedException();

  @override
  String toString() =>
      'CourseChangeBlockedException: 방문 또는 사진 기록이 있어 코스를 변경할 수 없습니다.';
}

/// 지원하지 않는 지역에 진입을 시도할 때 발생하는 예외.
class UnsupportedRegionException implements Exception {
  const UnsupportedRegionException(this.cityCountyName);

  final String cityCountyName;

  @override
  String toString() =>
      'UnsupportedRegionException: 지원하지 않는 지역입니다($cityCountyName).';
}

/// 추천 코스 후보의 장소에 좌표(위도/경도)가 없거나 유효하지 않은 상태로
/// 코스를 확정하려 할 때 발생하는 예외. 좌표를 0으로 대체해 저장하면 실제
/// 위치(기니만)로 오인될 수 있으므로, 확정 자체를 차단한다.
class InvalidCoursePlaceException implements Exception {
  const InvalidCoursePlaceException(this.placeName, [this.reason]);

  final String placeName;
  final String? reason;

  @override
  String toString() =>
      'InvalidCoursePlaceException: "$placeName" 장소의 좌표 정보가 유효하지 않아 '
      '코스를 확정할 수 없습니다${reason == null ? '' : ' ($reason)'}.';
}

/// 지역 이탈을 확정(`exitFilmRoll`)하려는데 서버 필름롤이 아직 없고, 이 시점에
/// 동기화를 시도해도 서버 필름롤을 확보하지 못했을 때 발생하는 예외.
class ExitNotSyncedException implements Exception {
  const ExitNotSyncedException();

  @override
  String toString() =>
      'ExitNotSyncedException: 서버와 동기화되지 않아 지역 이탈을 확정할 수 없습니다.';
}

/// 필름롤에 이미 [FilmRoll.maxExposureCount]장이 저장돼 있는데 사진을 한 장 더
/// 저장하려 할 때 발생하는 예외. UI(자유 촬영 버튼 노출 등)에서도 사전에
/// 막지만, 로딩 중이던 매수 표시가 최신이 아니었거나 여러 진입점이 동시에
/// 촬영을 시도하는 경우를 대비해 실제 저장 경계([PhotoRepositoryImpl.savePhoto])
/// 에서도 한 번 더 강제한다.
class FilmRollExposureLimitExceededException implements Exception {
  const FilmRollExposureLimitExceededException();

  @override
  String toString() =>
      'FilmRollExposureLimitExceededException: 필름을 다 써서 더 이상 촬영할 수 없습니다.';
}

/// 이 계정에 이탈 처리되지 않은 다른 활성 필름롤이 서버에 이미 있어(clientFilmRollId가
/// 다름) 지금 필름롤을 서버에 생성/연결할 수 없을 때 발생하는 예외. [ExitNotSyncedException]과
/// 달리 재시도로 해결되지 않는 영구적인 상태이므로 화면에서 구분해 안내해야 한다.
class ActiveFilmRollConflictException implements Exception {
  const ActiveFilmRollConflictException();

  @override
  String toString() =>
      'ActiveFilmRollConflictException: 이탈 처리되지 않은 다른 활성 필름롤이 있어 '
      '지역 이탈을 확정할 수 없습니다.';
}
