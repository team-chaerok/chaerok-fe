import 'package:chaerok/data/models/film_roll_photo_response.dart';

class FilmRollPhotoListResponse {
  const FilmRollPhotoListResponse({
    required this.filmRollId,
    required this.filmRollStatus,
    required this.totalPhotoCount,
    required this.photos,
  });

  factory FilmRollPhotoListResponse.fromJson(Map<String, dynamic> json) {
    return FilmRollPhotoListResponse(
      filmRollId: json['filmRollId'] as int,
      filmRollStatus: json['filmRollStatus'] as String,
      totalPhotoCount: json['totalPhotoCount'] as int,
      photos: (json['photos'] as List<dynamic>)
          .map((e) => FilmRollPhotoResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  factory FilmRollPhotoListResponse.empty() {
    return const FilmRollPhotoListResponse(
      filmRollId: 0,
      filmRollStatus: '',
      totalPhotoCount: 0,
      photos: [],
    );
  }

  final int filmRollId;
  final String filmRollStatus;
  final int totalPhotoCount;
  final List<FilmRollPhotoResponse> photos;
}
