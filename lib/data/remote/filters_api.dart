import 'dart:typed_data';

import 'package:chaerok/core/network/dio_client.dart';
import 'package:chaerok/data/models/filter_response.dart';
import 'package:dio/dio.dart';

/// FiltersApi 클래스는 필터(Filter) 및 필터 미리보기 관련 API 호출을 제공합니다.
class FiltersApi {
  const FiltersApi._();

  /// [필터 목록 조회] API 호출
  /// 적용 가능한 필터 목록을 조회한다.
  static Future<List<FilterResponse>> getFilters() async {
    final response = await DioClient.instance.get<List<FilterResponse>>(
      '/api/filters',
      fromJson: (data) => (data as List<dynamic>)
          .map((e) => FilterResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? const [];
  }

  /// [이미지 필터 미리보기] API 호출
  /// 이미지 밝기와 어두운 픽셀 비율을 서버가 분석해 LANDSCAPE 또는 NIGHT 장면으로
  /// 자동 분류한 뒤 필터 강도를 보정하여 적용한다. 응답은 필터가 적용된 JPEG
  /// 이미지 바이트다.
  static Future<Uint8List> previewFilter({
    required String filterId,
    double strength = 1,
    required Uint8List imageBytes,
    String filename = 'image.jpg',
  }) async {
    final response = await DioClient.instance.post<Uint8List>(
      '/api/filters/preview',
      queryParameters: {'filterId': filterId, 'strength': strength},
      data: FormData.fromMap({
        'image': MultipartFile.fromBytes(imageBytes, filename: filename),
      }),
      responseType: ResponseType.bytes,
      fromJson: (data) => data as Uint8List,
    );
    return response.data ?? Uint8List(0);
  }
}
