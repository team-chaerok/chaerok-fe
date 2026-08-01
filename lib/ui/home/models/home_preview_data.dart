class HomePreviewData {
  const HomePreviewData({
    required this.regionName,
    required this.userNickname,
    required this.filmRoll,
    required this.recommendedPlaces,
  });

  static const sample = HomePreviewData(
    regionName: '공주시',
    userNickname: '여행자',
    filmRoll: FilmRollPreviewData(
      name: '공주 필름 롤',
      capturedCount: 12,
      totalCount: 36,
      supportingText: '지금의 빛과 공기를 한 장씩 담아보세요.',
    ),
    recommendedPlaces: [
      RecommendedPlacePreviewData(
        name: '제민천 산책길',
        category: '자연·산책',
        distance: '120m',
        placeholderMood: PlacePlaceholderMood.stream,
      ),
      RecommendedPlacePreviewData(
        name: '공산성',
        category: '유적·역사',
        distance: '480m',
        placeholderMood: PlacePlaceholderMood.wall,
      ),
      RecommendedPlacePreviewData(
        name: '연미산 자연미술공원',
        category: '문화·전시',
        distance: '1.8km',
        placeholderMood: PlacePlaceholderMood.forest,
      ),
    ],
  );

  final String regionName;
  final String userNickname;
  final FilmRollPreviewData filmRoll;
  final List<RecommendedPlacePreviewData> recommendedPlaces;
}

class FilmRollPreviewData {
  const FilmRollPreviewData({
    required this.name,
    required this.capturedCount,
    required this.totalCount,
    required this.supportingText,
  });

  final String name;
  final int capturedCount;
  final int totalCount;
  final String supportingText;

  double get progress => capturedCount / totalCount;
}

class RecommendedPlacePreviewData {
  const RecommendedPlacePreviewData({
    required this.name,
    required this.category,
    required this.distance,
    required this.placeholderMood,
  });

  final String name;
  final String category;
  final String distance;
  final PlacePlaceholderMood placeholderMood;
}

enum PlacePlaceholderMood { stream, wall, forest }
