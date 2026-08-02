import 'package:chaerok/features/home/presentation/models/home_card_data.dart';

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
    filmRoll: FilmRollSummaryData(
      name: '공주 필름 롤',
      capturedCount: 12,
      totalCount: 36,
    ),
    recommendedPlaces: [
      RecommendedPlaceSummaryData(
        name: '제민천 산책길',
        category: '자연·산책',
        distance: '120m',
        placeholderMood: PlacePlaceholderMood.stream,
      ),
      RecommendedPlaceSummaryData(
        name: '공산성',
        category: '유적·역사',
        distance: '480m',
        placeholderMood: PlacePlaceholderMood.wall,
      ),
      RecommendedPlaceSummaryData(
        name: '연미산 자연미술공원',
        category: '문화·전시',
        distance: '1.8km',
        placeholderMood: PlacePlaceholderMood.forest,
      ),
    ],
  );

  final String regionName;
  final String userNickname;
  final FilmRollSummaryData filmRoll;
  final List<RecommendedPlaceSummaryData> recommendedPlaces;
}
