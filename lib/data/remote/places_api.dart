import 'package:chaerok/core/network/dio_client.dart';
import 'package:chaerok/data/models/place_detail_response.dart';
import 'package:chaerok/data/models/place_list_response.dart';
import 'package:chaerok/data/models/place_search_response.dart';

/// PlacesApi 클래스는 장소(Place) 리소스 관련 API 호출을 제공합니다.
class PlacesApi {
  const PlacesApi._();

  /// [지역별 장소 목록 조회] API 호출
  /// regionId를 기준으로 해당 지역의 관광지, 음식점, 카페·디저트 장소 목록을 조회합니다.
  static Future<List<PlaceListResponse>> getPlaces(int regionId) async {
    final response = await DioClient.instance.get<List<PlaceListResponse>>(
      '/api/places',
      queryParameters: {'regionId': regionId},
      fromJson: (data) => (data as List<dynamic>)
          .map((e) => PlaceListResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? const [];
  }

  /// [장소 상세 조회] API 호출
  /// placeId를 기준으로 장소 상세 정보를 조회합니다.
  static Future<PlaceDetailResponse> getPlaceDetail(int placeId) async {
    final response = await DioClient.instance.get<PlaceDetailResponse>(
      '/api/places/$placeId',
      fromJson: (data) =>
          PlaceDetailResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? PlaceDetailResponse.empty();
  }

  /// [장소 검색] API 호출
  /// keyword로 장소를 검색합니다. TourAPI를 우선 호출하고, 결과가 부족하면
  /// Kakao Local API로 보완합니다. 검색 결과는 DB에 저장되지 않습니다.
  static Future<List<PlaceSearchResponse>> searchPlaces({
    required int regionId,
    required String keyword,
  }) async {
    final response = await DioClient.instance.get<List<PlaceSearchResponse>>(
      '/api/places/search',
      queryParameters: {'regionId': regionId, 'keyword': keyword},
      fromJson: (data) => (data as List<dynamic>)
          .map((e) => PlaceSearchResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? const [];
  }

  /// [TourAPI 기반 지역 장소 조회] API 호출
  /// regionId를 기준으로 TourAPI에서 해당 지역의 장소 목록을 실시간 조회합니다.
  /// 조회 결과는 DB에 저장되지 않습니다.
  static Future<List<PlaceListResponse>> getExternalPlaces(int regionId) async {
    final response = await DioClient.instance.get<List<PlaceListResponse>>(
      '/api/places/external',
      queryParameters: {'regionId': regionId},
      fromJson: (data) => (data as List<dynamic>)
          .map((e) => PlaceListResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    return response.data ?? const [];
  }
}
