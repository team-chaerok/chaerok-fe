import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/resolve_region_request.dart';
import 'package:chaerok/data/remote/regions_api.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_status.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/domain/visit_category_progress.dart';
import 'package:chaerok/features/film_roll/presentation/controller/film_roll_controller.dart';
import 'package:chaerok/features/film_roll/presentation/page/course_selection_result.dart';
import 'package:chaerok/features/film_roll/presentation/page/course_selection_screen.dart';
import 'package:chaerok/features/film_roll/presentation/page/visit_capture_screen.dart';
import 'package:chaerok/features/film_roll/presentation/state/film_roll_state.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_developing_view.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';

const _serviceProvinceName = '충청남도';

/// 필름롤 상세 화면: 코스 선택 → 장소별 방문 인증/촬영 → 완료까지의 진입점.
class FilmRollScreen extends StatefulWidget {
  const FilmRollScreen({super.key, required this.filmRollId, this.regionId});

  final String filmRollId;

  /// 추천 코스 조회(`CoursesApi.getRecommendedCourses`)에 필요한 백엔드 지역 ID.
  /// 위치 인증 직후 진입한 경우에만 전달되며, null이면 코스 선택 시점에
  /// `RegionsApi.resolveRegion`으로 다시 조회한다(필름 컬렉션 화면에서 재진입한 경우 등).
  final int? regionId;

  @override
  State<FilmRollScreen> createState() => _FilmRollScreenState();
}

class _FilmRollScreenState extends State<FilmRollScreen> {
  static const _tag = 'FilmRollScreen';

  late final FilmRollController _controller;
  FilmRollState _state = const FilmRollState.initial();
  bool _isResolvingRegion = false;
  bool _isSyncing = false;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _controller = FilmRollController(
      filmRollId: widget.filmRollId,
      onStateChanged: (state) {
        if (!mounted) return;
        setState(() => _state = state);
      },
    );
    unawaited(_controller.load());
  }

  Future<void> _onSelectCourseTap() async {
    final filmRoll = _state.filmRoll;
    if (filmRoll == null) return;

    var regionId = widget.regionId;
    if (regionId == null) {
      setState(() => _isResolvingRegion = true);
      try {
        final region = await RegionsApi.resolveRegion(
          ResolveRegionRequest(
            provinceName: _serviceProvinceName,
            cityCountyName: filmRoll.regionName,
          ),
        );
        regionId = region.regionId;
      } catch (e, st) {
        log('지역 재조회 실패', name: _tag, error: e, stackTrace: st);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(apiErrorMessage(e))));
        return;
      } finally {
        if (mounted) setState(() => _isResolvingRegion = false);
      }
    }

    if (!mounted) return;
    final result = await Navigator.of(context).push<CourseSelectionResult>(
      MaterialPageRoute(
        builder: (_) => CourseSelectionScreen(regionId: regionId!),
      ),
    );
    if (result == null || !mounted) return;

    final success = switch (result.outcome) {
      CourseSelectionOutcome.recommended => await _controller.selectCourse(
        result.recommendedCourse!,
      ),
      CourseSelectionOutcome.custom => await _controller.selectCustomCourse(
        course: result.customCourse!,
        places: result.customPlaces!,
      ),
    };
    if (!mounted || success) return;
    final message = _controller.state.errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _onVisitTap(FilmRollPlace place) async {
    final filmRoll = _state.filmRoll;
    if (filmRoll == null) return;

    final captured = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VisitCaptureScreen(
          filmRollId: filmRoll.id,
          filmRollPlaceId: place.id,
        ),
      ),
    );
    if (captured != true || !mounted) return;
    await _controller.completeVisit(place.id);
  }

  Future<void> _showExitConfirmDialog() async {
    final isCompletable =
        _state.filmRoll?.isCompletable(_state.places) ?? false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('지역을 벗어나 현상할까요?'),
        content: Text(
          isCompletable
              ? '현상을 시작하면 이 필름롤은 더 이상 촬영할 수 없어요.'
              : '아직 현상 조건(서로 다른 유형 $requiredVisitCategoryCount곳 방문)을 채우지 '
                    '못했어요.\n지금 벗어나면 현상되지 않아요.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(isCompletable ? '현상 시작하기' : '그래도 벗어나기'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _startExit();
  }

  Future<void> _startExit() async {
    setState(() => _isExiting = true);
    try {
      final result = await _controller.exitFilmRoll();
      if (!mounted) return;
      if (result.isDeveloping) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('현상을 시작했어요!')));
      } else {
        await _showExpiredDialog();
        if (!mounted) return;
      }
      Navigator.of(context).pop();
    } on ExitNotSyncedException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아직 서버와 동기화되지 않았어요. 잠시 후 다시 시도해 주세요.')),
      );
    } catch (e, st) {
      log('지역 이탈 확정 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지역 이탈을 처리하지 못했어요. 잠시 후 다시 시도해 주세요.')),
      );
    } finally {
      if (mounted) setState(() => _isExiting = false);
    }
  }

  Future<void> _showExpiredDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('필름롤이 종료됐어요'),
        content: const Text('현상 조건을 충족하지 못해 이 필름롤은 종료됐어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: AppBar(
        backgroundColor: ChaerokColors.background,
        elevation: 0,
        title: Text(
          _state.filmRoll?.title ?? '필름롤',
          style: ChaerokTypography.titleMedium,
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_state.status) {
      case FilmRollLoadStatus.loading:
        return const Center(child: ChaerokLoadingIndicator());
      case FilmRollLoadStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(ChaerokSpacing.xxl),
            child: Text(
              _state.errorMessage ?? '오류가 발생했습니다.',
              textAlign: TextAlign.center,
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.error,
              ),
            ),
          ),
        );
      case FilmRollLoadStatus.loaded:
        final filmRoll = _state.filmRoll!;
        if (filmRoll.status == FilmRollStatus.developing) {
          return FilmRollDevelopingView(filmRoll: filmRoll);
        }
        return _buildLoaded();
    }
  }

  Widget _buildLoaded() {
    final filmRoll = _state.filmRoll!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_state.lastSyncHadError) ...[
            _buildSyncErrorBanner(),
            const SizedBox(height: ChaerokSpacing.sm),
          ],
          _buildProgressCard(filmRoll, _state.places),
          const SizedBox(height: ChaerokSpacing.md),
          if (!_state.hasSelectedCourse)
            ChaerokButton(
              text: '추천 코스 선택하기',
              isLoading: _isResolvingRegion,
              onPressed: _onSelectCourseTap,
            )
          else ...[
            ..._state.places.map(_buildPlaceTile),
            const SizedBox(height: ChaerokSpacing.md),
            ChaerokButton(
              text: '지역을 벗어나 현상하기',
              isEnabled: filmRoll.isCompletable(_state.places),
              isLoading: _isExiting,
              onPressed: _isExiting ? null : _showExitConfirmDialog,
            ),
          ],
        ],
      ),
    );
  }

  /// 백엔드 동기화가 부분 실패했을 때 노출되는 배너. 로컬 기록은 안전하며,
  /// 사용자가 직접 재시도할 수 있음을 알린다.
  Widget _buildSyncErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(ChaerokSpacing.sm),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
        border: Border.all(color: ChaerokColors.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: ChaerokSpacing.md,
            color: ChaerokColors.textSecondary,
          ),
          const SizedBox(width: ChaerokSpacing.xs),
          Expanded(
            child: Text(
              '서버 동기화에 실패했어요. 로컬 기록은 안전합니다.',
              style: ChaerokTypography.caption.copyWith(
                color: ChaerokColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: _isSyncing ? null : _onRetrySyncTap,
            child: Text(_isSyncing ? '동기화 중…' : '재시도'),
          ),
        ],
      ),
    );
  }

  Future<void> _onRetrySyncTap() async {
    setState(() => _isSyncing = true);
    try {
      final result = await _controller.retrySync();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.hasError ? '아직 동기화하지 못했어요.' : '동기화 완료')),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Widget _buildProgressCard(FilmRoll filmRoll, List<FilmRollPlace> places) {
    final visitedCategoryCount =
        filmRoll.visitedCategoryCount ?? countDistinctVisitedCategories(places);
    final requiredCategoryCount =
        filmRoll.requiredCategoryCount ?? requiredVisitCategoryCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(ChaerokSpacing.lg),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
        border: Border.all(color: ChaerokColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('현상 조건', style: ChaerokTypography.bodyMedium),
          const SizedBox(height: ChaerokSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(ChaerokRadius.full),
            child: LinearProgressIndicator(
              value: requiredCategoryCount == 0
                  ? 0
                  : visitedCategoryCount / requiredCategoryCount,
              minHeight: 8,
              backgroundColor: ChaerokColors.primaryLight,
              color: ChaerokColors.primary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(
            '서로 다른 관광 유형 $visitedCategoryCount/$requiredCategoryCount',
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(
            '방문 ${filmRoll.visitedPlaceCount} / ${filmRoll.totalPlaceCount} 곳',
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceTile(FilmRollPlace place) {
    return Container(
      margin: const EdgeInsets.only(bottom: ChaerokSpacing.sm),
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      decoration: BoxDecoration(
        color: ChaerokColors.surface,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
        border: Border.all(color: ChaerokColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(place.name, style: ChaerokTypography.bodyLarge),
                const SizedBox(height: ChaerokSpacing.xxs),
                Text(
                  place.address,
                  style: ChaerokTypography.caption.copyWith(
                    color: ChaerokColors.textSecondary,
                  ),
                ),
                if (place.photoCount > 0) ...[
                  const SizedBox(height: ChaerokSpacing.xxs),
                  Text(
                    '사진 ${place.photoCount}장',
                    style: ChaerokTypography.caption.copyWith(
                      color: ChaerokColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: ChaerokSpacing.sm),
          if (place.isVisited)
            const Icon(Icons.check_circle, color: ChaerokColors.primary)
          else
            TextButton(
              onPressed: () => _onVisitTap(place),
              child: const Text('방문 인증'),
            ),
        ],
      ),
    );
  }
}
