import 'package:chaerok/data/models/failure_response.dart';

class FilmRollResponse {
  const FilmRollResponse({
    required this.filmRollId,
    required this.regionId,
    required this.filterId,
    required this.filterStrength,
    required this.filterVersion,
    required this.status,
    required this.totalPhotoCount,
    required this.processedPhotoCount,
    required this.maxPhotoCount,
    required this.exitConfirmed,
    required this.developAvailable,
    required this.createdAt,
    required this.updatedAt,
    this.exitedAt,
    this.developAvailableAt,
    this.requestedAt,
    this.completedAt,
    this.expiresAt,
    this.failure,
  });

  factory FilmRollResponse.fromJson(Map<String, dynamic> json) {
    return FilmRollResponse(
      filmRollId: json['filmRollId'] as int,
      regionId: json['regionId'] as int,
      filterId: json['filterId'] as String,
      filterStrength: (json['filterStrength'] as num).toDouble(),
      filterVersion: json['filterVersion'] as int,
      status: json['status'] as String,
      totalPhotoCount: json['totalPhotoCount'] as int,
      processedPhotoCount: json['processedPhotoCount'] as int,
      maxPhotoCount: json['maxPhotoCount'] as int,
      exitedAt: json['exitedAt'] != null
          ? DateTime.parse(json['exitedAt'] as String)
          : null,
      developAvailableAt: json['developAvailableAt'] != null
          ? DateTime.parse(json['developAvailableAt'] as String)
          : null,
      exitConfirmed: json['exitConfirmed'] as bool,
      developAvailable: json['developAvailable'] as bool,
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      failure: json['failure'] != null
          ? FailureResponse.fromJson(json['failure'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory FilmRollResponse.empty() {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return FilmRollResponse(
      filmRollId: 0,
      regionId: 0,
      filterId: '',
      filterStrength: 0,
      filterVersion: 0,
      status: '',
      totalPhotoCount: 0,
      processedPhotoCount: 0,
      maxPhotoCount: 0,
      exitConfirmed: false,
      developAvailable: false,
      createdAt: epoch,
      updatedAt: epoch,
    );
  }

  final int filmRollId;
  final int regionId;
  final String filterId;
  final double filterStrength;
  final int filterVersion;
  final String status;
  final int totalPhotoCount;
  final int processedPhotoCount;
  final int maxPhotoCount;
  final DateTime? exitedAt;
  final DateTime? developAvailableAt;
  final bool exitConfirmed;
  final bool developAvailable;
  final DateTime? requestedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final FailureResponse? failure;
  final DateTime createdAt;
  final DateTime updatedAt;
}
