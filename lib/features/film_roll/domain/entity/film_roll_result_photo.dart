/// 현상 결과 화면에 표시할 사진 한 장. 서버가 내려준 필터 사진, 기기에 보관한
/// 필터 사진, 기기의 촬영 원본 중 무엇을 보여줄지가 결정된 상태다.
class FilmRollResultPhoto {
  const FilmRollResultPhoto({
    required this.sequence,
    this.localPath,
    this.remoteUrl,
    this.isFiltered = true,
    this.filmRollPlaceId,
    this.placeName,
  }) : assert(localPath != null || remoteUrl != null);

  /// 필름롤 안에서의 촬영 순서. 화면은 이 값의 오름차순으로 보여준다.
  final int sequence;

  /// 기기에 있는 파일의 절대 경로. 있으면 [remoteUrl]보다 우선해 보여준다.
  final String? localPath;

  /// 서버 다운로드 URL. 유효기간이 짧아 결과를 다시 조회하면 바뀐다.
  final String? remoteUrl;

  /// 필터가 적용된 사진인지. false면 보관한 필터 사진이 없어 촬영 원본으로
  /// 대체한 것이다.
  final bool isFiltered;

  /// 촬영한 장소의 로컬 id. 기기에 촬영 기록이 없으면(다른 기기에서 찍은 롤 등)
  /// 알 수 없어 null이다.
  final String? filmRollPlaceId;

  /// 촬영한 장소 이름. 장소를 알 수 없으면 null이다.
  final String? placeName;
}
