import 'package:chaerok/core/network/dio_client.dart';
import 'package:chaerok/data/models/visit_create_request.dart';
import 'package:chaerok/data/models/visit_create_response.dart';
import 'package:chaerok/data/models/visit_list_response.dart';

/// VisitsApi 클래스는 필름 롤 방문(Visit) 인증 관련 API 호출을 제공합니다.
class VisitsApi {
  const VisitsApi._();

  /// [방문 현황 조회] API 호출
  /// 필름 롤의 방문 기록과 방문 유형 진행도를 조회한다. 관광지(TOURISM), 식당(FOOD),
  /// 카페·디저트(CAFE_DESSERT)를 각각 1곳 이상 방문하면 현상용 Visit 조건을 충족한다.
  static Future<VisitListResponse> getVisits(int filmRollId) async {
    final response = await DioClient.instance.get<VisitListResponse>(
      '/api/film-rolls/$filmRollId/visits',
      fromJson: (data) =>
          VisitListResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? VisitListResponse.empty();
  }

  /// [방문 인증] API 호출
  /// 프론트가 GPS와 장소 간 거리를 검증한 뒤 placeId만 전달한다. 백엔드는 GPS 좌표,
  /// 정확도, 거리, 이동 경로를 받거나 저장하지 않는다. 같은 필름 롤의 같은 장소는
  /// 한 번만 인증할 수 있다.
  static Future<VisitCreateResponse> createVisit(
    int filmRollId,
    VisitCreateRequest request,
  ) async {
    final response = await DioClient.instance.post<VisitCreateResponse>(
      '/api/film-rolls/$filmRollId/visits',
      data: request.toJson(),
      fromJson: (data) =>
          VisitCreateResponse.fromJson(data as Map<String, dynamic>),
    );
    return response.data ?? VisitCreateResponse.empty();
  }
}
