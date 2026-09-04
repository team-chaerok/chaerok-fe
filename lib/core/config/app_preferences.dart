import 'package:shared_preferences/shared_preferences.dart';

const _keyLastActiveFilmRollId = 'last_active_film_roll_id';
const _keyCurrentUserId = 'current_user_id';
const _keyMockLocationEnabled = 'mock_location_enabled';
const _keyMockRegionCode = 'mock_region_code';
const _keyMockSpotIndex = 'mock_spot_index';
const _keyIsTester = 'is_tester';

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

  /// mock 위치가 가리킬 지점 인덱스(`mockLocationSpots[지역]` 기준). 저장된 값이
  /// 없으면 0. 지역별 지점 개수가 다르므로 사용하는 쪽에서 범위를 clamp 한다.
  Future<int> getMockSpotIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMockSpotIndex) ?? 0;
  }

  Future<void> setMockSpotIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMockSpotIndex, index);
  }

  /// 서버가 내려준 테스트 계정 여부(`/api/users/me`의 `isTester`). release
  /// 빌드에서 mock 위치를 허용할지 판단하는 데 쓴다(`MockLocationGate` 참고).
  /// 로그인/세션 재개 시 갱신되고, 기본값은 false다.
  Future<bool> isTester() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsTester) ?? false;
  }

  Future<void> setTester(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsTester, value);
  }
}
