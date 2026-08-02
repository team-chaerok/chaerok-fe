/// 방문/사진 기록이 있는 상태에서 코스 변경을 시도할 때 발생하는 예외(안전 기본값 정책).
class CourseChangeBlockedException implements Exception {
  const CourseChangeBlockedException();

  @override
  String toString() =>
      'CourseChangeBlockedException: 방문 또는 사진 기록이 있어 코스를 변경할 수 없습니다.';
}

/// 완료 조건(코스 선택 + 전체 장소 방문)을 충족하지 못한 상태에서 완료를 시도할 때 발생하는 예외.
class FilmRollNotCompletableException implements Exception {
  const FilmRollNotCompletableException();

  @override
  String toString() =>
      'FilmRollNotCompletableException: 완료 조건(코스 선택 + 전체 방문)을 충족하지 못했습니다.';
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
