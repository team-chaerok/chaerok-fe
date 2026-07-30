import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/api_error.dart';
import 'package:chaerok/data/models/course_response.dart';
import 'package:chaerok/data/models/resolve_region_request.dart';
import 'package:chaerok/data/remote/regions_api.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/presentation/controller/film_roll_controller.dart';
import 'package:chaerok/features/film_roll/presentation/page/course_selection_screen.dart';
import 'package:chaerok/features/film_roll/presentation/page/visit_capture_screen.dart';
import 'package:chaerok/features/film_roll/presentation/state/film_roll_state.dart';
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
    final selected = await Navigator.of(context).push<CourseResponse>(
      MaterialPageRoute(
        builder: (_) => CourseSelectionScreen(regionId: regionId!),
      ),
    );
    if (selected == null || !mounted) return;

    final success = await _controller.selectCourse(selected);
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
          placeName: place.name,
        ),
      ),
    );
    if (captured != true || !mounted) return;
    await _controller.completeVisit(place.id);
  }

  Future<void> _onCompleteTap() async {
    final success = await _controller.completeFilmRoll();
    if (!mounted) return;
    final message = success ? '필름롤을 완료했어요!' : _controller.state.errorMessage;
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
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
          _buildProgressCard(
            filmRoll.progress,
            filmRoll.visitedPlaceCount,
            filmRoll.totalPlaceCount,
          ),
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
              text: '필름롤 완료하기',
              isEnabled: filmRoll.isCompletable,
              onPressed: _onCompleteTap,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard(double progress, int visited, int total) {
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
          const Text('방문 진행률', style: ChaerokTypography.labelLarge),
          const SizedBox(height: ChaerokSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(ChaerokRadius.full),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: ChaerokColors.primaryLight,
              color: ChaerokColors.primary,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(
            '$visited / $total 곳 방문',
            style: ChaerokTypography.bodyMedium.copyWith(
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
