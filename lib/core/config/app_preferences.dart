import 'package:shared_preferences/shared_preferences.dart';

const _keyLastActiveFilmRollId = 'last_active_film_roll_id';
const _keyCurrentUserId = 'current_user_id';
const _keyMockLocationEnabled = 'mock_location_enabled';
const _keyMockRegionCode = 'mock_region_code';
const _keyDefaultFilterId = 'default_filter_id';

/// 앱 재시작 복구/개발용 mock 설정 등 단순 값을 저장하는 SharedPreferences 래퍼.
class AppPreferences {
  AppPreferences._();

  static AppPreferences? _instance;

  static AppPreferences get instance => _instance ??= AppPreferences._();

  /// 앱 재시작 시 진행중이던 필름롤로 복귀하기 위한 마지막 필름롤 ID.
  Future<String?> getLastActiveFilmRollId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyLastActiveFilmRollId);
  }

  Future<void> setLastActiveFilmRollId(String? filmRollId) async {
    final prefs = await SharedPreferences.getInstance();
    if (filmRollId == null) {
      await prefs.remove(_keyLastActiveFilmRollId);
    } else {
      await prefs.setString(_keyLastActiveFilmRollId, filmRollId);
    }
  }

  /// 로컬 DB에 남은 필름롤을 현재 로그인 계정 기준으로 필터링하기 위한
  /// 계정 식별자. 로그인/세션 재개 시 갱신되고, 로그아웃/탈퇴 시 null로 지워진다.
  Future<int?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyCurrentUserId);
  }

  Future<void> setCurrentUserId(int? userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (userId == null) {
      await prefs.remove(_keyCurrentUserId);
    } else {
      await prefs.setInt(_keyCurrentUserId, userId);
    }
  }

  /// 개발용 mock 위치 사용 여부. release 빌드에서는 항상 비활성화로 취급된다
  /// (`LocationProviderFactory` 참고).
  Future<bool> isMockLocationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMockLocationEnabled) ?? false;
  }

  Future<void> setMockLocationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMockLocationEnabled, enabled);
  }

  /// 개발용 mock 위치가 표현할 지역(RegionCode.name 문자열).
  Future<String?> getMockRegionCodeName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyMockRegionCode);
  }

  Future<void> setMockRegionCodeName(String regionCodeName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMockRegionCode, regionCodeName);
  }

  /// 필름롤 서버 생성(`FilmRollCreateRequest.filterId`)에 사용할 기본 필터 ID.
  /// 필터 선택 UI가 없는 현재는 최초 1회 `FiltersApi.getFilters()` 결과의
  /// 첫 필터를 캐시해두고 이후 재사용한다.
  Future<String?> getDefaultFilterId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultFilterId);
  }

  Future<void> setDefaultFilterId(String? filterId) async {
    final prefs = await SharedPreferences.getInstance();
    if (filterId == null) {
      await prefs.remove(_keyDefaultFilterId);
    } else {
      await prefs.setString(_keyDefaultFilterId, filterId);
    }
  }
}
