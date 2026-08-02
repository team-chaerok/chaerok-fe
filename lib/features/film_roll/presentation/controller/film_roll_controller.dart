import 'dart:developer';

import 'package:chaerok/data/models/course_response.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_place_repository.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_repository.dart';
import 'package:chaerok/features/film_roll/domain/usecase/complete_film_roll_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/complete_visit_use_case.dart';
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
    CompleteFilmRollUseCase? completeFilmRollUseCase,
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
       _completeFilmRollUseCase =
           completeFilmRollUseCase ?? FilmRollModule.instance.completeFilmRoll;

  final String filmRollId;
  final void Function(FilmRollState state) _onStateChanged;
  final FilmRollRepository _filmRollRepository;
  final FilmRollPlaceRepository _filmRollPlaceRepository;
  final SelectCourseUseCase _selectCourseUseCase;
  final CompleteVisitUseCase _completeVisitUseCase;
  final CompleteFilmRollUseCase _completeFilmRollUseCase;

  FilmRollState _state = const FilmRollState.initial();

  FilmRollState get state => _state;

  Future<void> load() async {
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

  Future<bool> completeFilmRoll() async {
    try {
      await _completeFilmRollUseCase(filmRollId);
      await load();
      return true;
    } on FilmRollNotCompletableException {
      _emit(
        _state.copyWith(
          status: FilmRollLoadStatus.loaded,
          errorMessage: '완료 조건(코스 선택 + 전체 방문)을 충족하지 못했습니다.',
        ),
      );
      return false;
    } catch (e, st) {
      log('필름롤 완료 실패', name: _tag, error: e, stackTrace: st);
      _emit(
        _state.copyWith(
          status: FilmRollLoadStatus.loaded,
          errorMessage: e.toString(),
        ),
      );
      return false;
    }
  }

  void _emit(FilmRollState state) {
    _state = state;
    _onStateChanged(state);
  }
}
