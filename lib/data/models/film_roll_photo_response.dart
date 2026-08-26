import 'package:chaerok/data/models/failure_response.dart';

class FilmRollPhotoResponse {
  const FilmRollPhotoResponse({
    required this.photoId,
    required this.sequence,
    required this.status,
    required this.takenAt,
    this.uploadCompletedAt,
    this.processedAt,
    this.failure,
  });

  factory FilmRollPhotoResponse.fromJson(Map<String, dynamic> json) {
    return FilmRollPhotoResponse(
      photoId: json['photoId'] as int,
      sequence: json['sequence'] as int,
      status: json['status'] as String,
      takenAt: DateTime.parse(json['takenAt'] as String),
      uploadCompletedAt: json['uploadCompletedAt'] != null
          ? DateTime.parse(json['uploadCompletedAt'] as String)
          : null,
      processedAt: json['processedAt'] != null
          ? DateTime.parse(json['processedAt'] as String)
          : null,
      failure: json['failure'] != null
          ? FailureResponse.fromJson(json['failure'] as Map<String, dynamic>)
          : null,
    );
  }

  final int photoId;
  final int sequence;
  final String status;
  final DateTime takenAt;
  final DateTime? uploadCompletedAt;
  final DateTime? processedAt;
  final FailureResponse? failure;
}
