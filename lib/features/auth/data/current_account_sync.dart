import 'dart:developer';

import 'package:chaerok/core/config/app_preferences.dart';
import 'package:chaerok/data/models/user_response.dart';
import 'package:chaerok/data/remote/users_api.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';

/// 로그인/회원가입 성공 시점과, 이미 인증된 세션으로 앱이 재개되는 시점
/// (스플래시)에 로컬에 저장된 "현재 계정" 정보를 서버 기준으로 맞춘다.
///
/// 계정 전환 시 이전 계정의 로컬 필름롤이 노출되던 버그의 근본 수정 일부로,
/// [FilmRollLocalDataSource]가 조회 시점마다 참조하는 [AppPreferences]의
/// 현재 계정 id를 최신 상태로 유지하는 역할을 한다. 계정 스코프 도입(v2)
/// 이전에 생성돼 계정이 비어있는 레거시 필름롤은, 로컬에 저장된 계정 id가
/// 아직 없는 최초 동기화 시점에만 지금 로그인된 계정 소유로 1회 확정한다.
///
/// auth 기능이면서도 [FilmRollModule](film_roll 기능)을 직접 참조하는 이유:
/// 레거시 필름롤 귀속(claim)은 로그인 직후 계정을 확정하는 이 시점에만
/// 안전하게 1회 수행할 수 있고, 그 대상 데이터(필름롤)는 film_roll 기능이
/// 소유하고 있어 불가피하게 경계를 넘는다. film_roll 쪽에서 auth를
/// 참조하도록 방향을 반대로 두지 않기 위해 이 파일에 모아뒀다.
class CurrentAccountSync {
  const CurrentAccountSync._();

  static const _tag = 'CurrentAccountSync';

  /// 실패해도 로그인/앱 진입 흐름을 막지 않는다 — 실패 시 현재 계정 id가
  /// 갱신되지 않아 필름롤 조회가 "모르면 아무것도 보여주지 않음"으로
  /// 안전하게 저하되고, 다음 성공적인 동기화에서 자연 복구된다.
  ///
  /// 로그아웃/탈퇴가 항상 계정 id를 지우므로(SettingsScreen), 이 값이 이미
  /// 있다는 것은 로그인 상태가 그대로 이어지고 있다는 뜻이다. 그런 경우까지
  /// 매번 `/api/users/me`를 다시 호출할 필요가 없어 스플래시 재개(가장 흔한
  /// 경로) 때는 네트워크 호출 없이 즉시 반환한다.
  ///
  /// [fetchCurrentUser]/[appPreferences]/[filmRollRepository]는 테스트에서
  /// 실제 네트워크(`DioClient.instance`)와 DB 싱글턴을 거치지 않고 이 흐름을
  /// 검증할 수 있도록 둔 선택적 override로, 다른 유스케이스들과 동일한
  /// `X? x` + `?? X.instance` 패턴을 따른다.
  static Future<void> sync({
    Future<UserResponse> Function()? fetchCurrentUser,
    AppPreferences? appPreferences,
    FilmRollRepository? filmRollRepository,
  }) async {
    final preferences = appPreferences ?? AppPreferences.instance;
    final repository =
        filmRollRepository ?? FilmRollModule.instance.filmRollRepository;
    final fetchCurrentUserOrDefault =
        fetchCurrentUser ?? UsersApi.getMyInformation;
    try {
      final previousUserId = await preferences.getCurrentUserId();
      if (previousUserId != null) return;

      final user = await fetchCurrentUserOrDefault();
      await repository.claimLegacyData(user.id);
      await preferences.setCurrentUserId(user.id);
      // 테스터 플래그는 로그인/회원가입 시 갱신된다. 세션 재개(위 조기 반환)
      // 경로에서는 재조회하지 않으므로, 마이 탭 진입 시 재갱신하고
      // 로그아웃·탈퇴 시 false로 지운다(SettingsScreen).
      await preferences.setTester(user.isTester);
    } catch (e, st) {
      log('현재 계정 동기화 실패', name: _tag, error: e, stackTrace: st);
    }
  }
}
