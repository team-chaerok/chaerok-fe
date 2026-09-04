import 'dart:async';
import 'dart:developer';

import 'package:chaerok/data/models/course_response.dart';
import 'package:chaerok/data/models/visit_list_response.dart';
import 'package:chaerok/data/remote/visits_api.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_result.dart';
import 'package:chaerok/features/film_roll/data/sync/film_roll_sync_service.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_place_repository.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/complete_visit_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/exit_film_roll_result.dart';
import 'package:chaerok/features/film_roll/domain/usecase/exit_film_roll_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/select_course_use_case.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/state/film_roll_state.dart';

const _tag = 'FilmRollController';

/// 필름롤 상세 화면(코스 선택/방문 인증/완료)의 상태와 로직을 담당하는
/// setState 기반 Controller. 이 프로젝트는 Provider/Riverpod 등 별도 상태관리
/// 라이브러리를 쓰지 않으므로, 화면(State)이 이 클래스를 들고 콜백으로 setState한다.
class FilmRollController {
  FilmRollController({
    required this.filmRollId,
    required void Function(FilmRollState state) onStateChanged,
    FilmRollRepository? filmRollRepository,
    FilmRollPlaceRepository? filmRollPlaceRepository,
    SelectCourseUseCase? selectCourseUseCase,
    CompleteVisitUseCase? completeVisitUseCase,
    ExitFilmRollUseCase? exitFilmRollUseCase,
    FilmRollSyncService? syncService,
    Future<VisitListResponse> Function(int filmRollId)? getVisits,
  }) : _onStateChanged = onStateChanged,
       _filmRollRepository =
           filmRollRepository ?? FilmRollModule.instance.filmRollRepository,
       _filmRollPlaceRepository =
           filmRollPlaceRepository ??
           FilmRollModule.instance.filmRollPlaceRepository,
       _selectCourseUseCase =
           selectCourseUseCase ?? FilmRollModule.instance.selectCourse,
       _completeVisitUseCase =
           completeVisitUseCase ?? FilmRollModule.instance.completeVisit,
       _exitFilmRollUseCase =
           exitFilmRollUseCase ?? FilmRollModule.instance.exitFilmRoll,
       _syncService =
           syncService ?? FilmRollModule.instance.filmRollSyncService,
       _getVisits = getVisits ?? VisitsApi.getVisits;

  final String filmRollId;
  final void Function(FilmRollState state) _onStateChanged;
  final FilmRollRepository _filmRollRepository;
  final FilmRollPlaceRepository _filmRollPlaceRepository;
  final SelectCourseUseCase _selectCourseUseCase;
  final CompleteVisitUseCase _completeVisitUseCase;
  final ExitFilmRollUseCase _exitFilmRollUseCase;
  final FilmRollSyncService _syncService;
  final Future<VisitListResponse> Function(int filmRollId) _getVisits;

  FilmRollState _state = const FilmRollState.initial();

  /// 진행 중인 동기화. 같은 필름롤에 대해 동시에 하나만 돌게 하고, 여러 트리거
  /// (화면 로드·방문 후·재시도 버튼)가 겹치면 이 Future를 공유한다.
  Future<FilmRollSyncResult>? _inFlightSync;

  FilmRollState get state => _state;

  /// 로컬 DB에서 필름롤/장소를 다시 읽어 상태에 반영한다(동기화는 시작하지 않음).
  Future<void> _reload() async {
    _emit(_state.copyWith(status: FilmRollLoadStatus.loading));
    try {
      final filmRoll = await _filmRollRepository.findById(filmRollId);
      if (filmRoll == null) {
        _emit(
          const FilmRollState(
            status: FilmRollLoadStatus.error,
            errorMessage: '필름롤을 찾을 수 없습니다.',
          ),
        );
        return;
      }
      final places = await _filmRollPlaceRepository.findByFilmRoll(filmRollId);
      _emit(
        FilmRollState(
          status: FilmRollLoadStatus.loaded,
          filmRoll: filmRoll,
          places: places,
          lastSyncHadError: _state.lastSyncHadError,
        ),
      );
    } catch (e, st) {
      log('필름롤 조회 실패', name: _tag, error: e, stackTrace: st);
      _emit(
        _state.copyWith(
          status: FilmRollLoadStatus.error,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> load() async {
    await _reload();
    if (_state.status == FilmRollLoadStatus.loaded) {
      _triggerSync();
      unawaited(loadVisits());
    }
  }

  /// 현상 조건(`VisitsApi.getVisits`)을 조회해 [state.filmRoll]에 반영한다.
  /// 서버 필름롤이 아직 없으면(미동기화) 아무것도 하지 않는다.
  Future<void> loadVisits() async {
    final serverFilmRollId = _state.filmRoll?.serverFilmRollId;
    if (serverFilmRollId == null || _state.isLoadingVisits) return;

    _emit(_state.copyWith(isLoadingVisits: true, visitsLoadFailed: false));
    try {
      final visits = await _getVisits(serverFilmRollId);
      final filmRoll = _state.filmRoll;
      if (filmRoll != null) {
        _emit(
          _state.copyWith(
            filmRoll: filmRoll.copyWith(
              visitRequirementMet: visits.visitRequirementMet,
              visitedCategoryCount: visits.visitedCategoryCount,
              requiredCategoryCount: visits.requiredCategoryCount,
            ),
          ),
        );
      }
    } catch (e, st) {
      log('현상 조건 조회 실패', name: _tag, error: e, stackTrace: st);
      _emit(_state.copyWith(visitsLoadFailed: true));
    } finally {
      _emit(_state.copyWith(isLoadingVisits: false));
    }
  }

  /// 진행 중인 동기화가 있으면 그 Future를, 없으면 새로 시작해 반환한다.
  /// 완료되면 [_inFlightSync]를 비워 다음 호출이 새 동기화를 시작하게 한다.
  Future<FilmRollSyncResult> _sync() {
    return _inFlightSync ??= _syncService
        .syncFilmRoll(filmRollId)
        .whenComplete(() => _inFlightSync = null);
  }

  /// 백엔드 동기화를 백그라운드로 시도하고, 완료되면 부분 실패 여부를 상태에
  /// 반영한다. 화면 진입/방문 후 자동으로 호출된다(fire-and-forget).
  void _triggerSync() {
    unawaited(
      _sync()
          .then((result) {
            _emit(_state.copyWith(lastSyncHadError: result.hasError));
          })
          .catchError((_) {
            // syncFilmRoll은 예외를 던지지 않지만, 방어적으로 무시한다.
          }),
    );
  }

  /// 사용자가 "동기화 재시도"를 눌렀을 때. 결과를 기다렸다가 상태를 갱신한다.
  /// 진행 중인 동기화가 있으면 [_sync]를 통해 그것을 공유한다(중복 요청 방지).
  /// [_reload]를 쓰는 이유: [load]는 끝에 다시 [_triggerSync]를 돌려 불필요한
  /// 백그라운드 동기화와 [lastSyncHadError] 재변경을 일으킨다.
  Future<FilmRollSyncResult> retrySync() async {
    final result = await _sync();
    await _reload();
    _emit(_state.copyWith(lastSyncHadError: result.hasError));
    return result;
  }

  /// 코스를 확정한다. 코스 변경 차단 정책 등으로 실패하면 false를 반환하고
  /// [state.errorMessage]에 사유를 채운다.
  Future<bool> selectCourse(CourseResponse course) async {
    try {
      await _selectCourseUseCase(filmRollId: filmRollId, course: course);
      await load();
      return true;
    } on CourseChangeBlockedException {
      _emit(
        _state.copyWith(
          status: FilmRollLoadStatus.loaded,
          errorMessage: '이미 방문/촬영 기록이 있어 코스를 변경할 수 없습니다.',
        ),
      );
      return false;
    } catch (e, st) {
      log('코스 선택 실패', name: _tag, error: e, stackTrace: st);
      _emit(
        _state.copyWith(
          status: FilmRollLoadStatus.loaded,
          errorMessage: e.toString(),
        ),
      );
      return false;
    }
  }

  Future<void> completeVisit(String filmRollPlaceId) async {
    try {
      await _completeVisitUseCase(filmRollPlaceId);
      await load();
    } catch (e, st) {
      log('방문 인증 실패', name: _tag, error: e, stackTrace: st);
      _emit(
        _state.copyWith(
          status: FilmRollLoadStatus.loaded,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  /// 지역 이탈을 확정해 현상을 시작한다([ExitFilmRollUseCase]). 완료 후 최신
  /// 상태를 다시 불러온다. [ExitNotSyncedException] 등 예외는 화면이 처리하도록
  /// 그대로 던진다(다이얼로그/스낵바 등 UI 대응이 화면마다 다르기 때문).
  Future<ExitFilmRollResult> exitFilmRoll() async {
    final filmRoll = _state.filmRoll;
    if (filmRoll == null) {
      throw StateError('필름롤이 로드되지 않아 지역 이탈을 확정할 수 없습니다.');
    }
    final result = await _exitFilmRollUseCase(filmRoll);
    await load();
    return result;
  }

  void _emit(FilmRollState state) {
    _state = state;
    _onStateChanged(state);
  }
}
