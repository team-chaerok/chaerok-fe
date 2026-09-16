import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/data/models/film_roll_result_response.dart';
import 'package:chaerok/data/remote/film_rolls_api.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_result_photos_screen.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/reel_player_page.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/widgets/chaerok_appbar.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 현상(릴스 생성)이 완료된 필름롤의 결과 — 방문 장소 수/촬영 사진/릴스를
/// 보여주는 화면. [initialResult]가 있으면(현상 대기 화면에서 방금 완료를
/// 감지해 넘어온 경우) 추가 조회 없이 바로 그리고, 없으면(필름 컬렉션에서
/// 다시 열람하는 경우) presigned URL이 만료됐을 수 있으므로 새로 조회한다.
class FilmRollResultScreen extends StatefulWidget {
  const FilmRollResultScreen({
    super.key,
    required this.filmRoll,
    this.initialResult,
  });

  final FilmRoll filmRoll;
  final FilmRollResultResponse? initialResult;

  @override
  State<FilmRollResultScreen> createState() => _FilmRollResultScreenState();
}

class _FilmRollResultScreenState extends State<FilmRollResultScreen> {
  static const _tag = 'FilmRollResultScreen';

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSharing = false;
  String? _errorMessage;
  FilmRollResultResponse? _result;

  @override
  void initState() {
    super.initState();
    if (widget.initialResult != null) {
      _result = widget.initialResult;
    } else {
      unawaited(_fetchResult());
    }
  }

  Future<void> _fetchResult() async {
    final serverFilmRollId = widget.filmRoll.serverFilmRollId;
    if (serverFilmRollId == null) {
      setState(() => _errorMessage = '필름롤 결과를 불러오지 못했어요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await FilmRollsApi.getFilmRollResult(serverFilmRollId);
      if (!mounted) return;
      setState(() {
        _result = result;
        _isLoading = false;
      });
    } catch (e, st) {
      log('현상 결과 조회 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _errorMessage = '필름롤 결과를 불러오지 못했어요.';
        _isLoading = false;
      });
    }
  }

  Future<String> _downloadReelToTempFile(DownloadResponse reel) async {
    final dio = Dio();
    final response = await dio.get<List<int>>(
      reel.downloadUrl,
      options: Options(responseType: ResponseType.bytes),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/film-roll-${widget.filmRoll.id}-reel.mp4');
    await file.writeAsBytes(response.data!);
    return file.path;
  }

  Future<void> _onSaveTap() async {
    final reel = _result?.reel;
    if (reel == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final path = await _downloadReelToTempFile(reel);
      await Gal.putVideo(path);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('갤러리에 저장했어요.')));
    } catch (e, st) {
      log('릴스 저장 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('저장에 실패했어요.')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _onShareTap() async {
    final reel = _result?.reel;
    if (reel == null || _isSharing) return;

    setState(() => _isSharing = true);
    try {
      final path = await _downloadReelToTempFile(reel);
      await Share.shareXFiles([XFile(path)]);
    } catch (e, st) {
      log('릴스 공유 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('공유에 실패했어요.')));
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _openReelPlayer(String url) {
    unawaited(
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => ReelPlayerPage(videoUrl: url))),
    );
  }

  void _openAllPhotos() {
    final photos = _result?.filteredPhotos ?? const [];
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FilmRollResultPhotosScreen(photos: photos),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      appBar: ChaerokAppbar(title: widget.filmRoll.title),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: ChaerokLoadingIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ChaerokSpacing.xxl),
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: ChaerokTypography.bodyMedium.copyWith(
              color: ChaerokColors.error,
            ),
          ),
        ),
      );
    }

    final result = _result;
    if (result == null) {
      return const SizedBox.shrink();
    }

    final photos = result.filteredPhotos;
    final representative = photos.isEmpty ? null : photos.first;
    final previewPhotos = photos.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: ChaerokSpacing.md),
          _buildRepresentativeImage(representative),
          const SizedBox(height: ChaerokSpacing.sm),
          _buildStatsRow(result),
          const SizedBox(height: ChaerokSpacing.xl),
          _buildSectionTitle('오늘의 사진', onSeeAll: _openAllPhotos),
          const SizedBox(height: ChaerokSpacing.sm),
          _buildPhotoPreviewRow(previewPhotos),
          const SizedBox(height: ChaerokSpacing.xl),
          _buildSectionTitle('오늘의 릴스'),
          const SizedBox(height: ChaerokSpacing.sm),
          _buildReelCard(result.reel, representative),
          const SizedBox(height: ChaerokSpacing.xl),
          _buildActionButtons(result),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final regionCode = widget.filmRoll.regionCode;
    final completedAt = widget.filmRoll.completedAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '${regionCode.name.toUpperCase()} · ${regionCode.displayName}',
          style: ChaerokTypography.caption.copyWith(
            color: ChaerokColors.textSecondary,
          ),
        ),
        if (completedAt != null) ...[
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(_formatDate(completedAt), style: ChaerokTypography.caption),
        ],
      ],
    );
  }

  Widget _buildRepresentativeImage(FilteredPhotoResponse? representative) {
    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ChaerokRadius.lg),
        child: representative == null
            ? const ColoredBox(color: ChaerokColors.sageLight)
            : Image.network(
                representative.downloadUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const ColoredBox(color: ChaerokColors.sageLight),
              ),
      ),
    );
  }

  Widget _buildStatsRow(FilmRollResultResponse result) {
    return Text(
      '방문 ${widget.filmRoll.visitedPlaceCount}곳 · 촬영 ${result.totalPhotoCount}장',
      textAlign: TextAlign.center,
      style: ChaerokTypography.bodyMedium.copyWith(
        color: ChaerokColors.textSecondary,
      ),
    );
  }

  Widget _buildSectionTitle(String title, {VoidCallback? onSeeAll}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: ChaerokTypography.titleMedium),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              '전체 >',
              style: ChaerokTypography.bodyMedium.copyWith(
                color: ChaerokColors.textSecondary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoPreviewRow(List<FilteredPhotoResponse> photos) {
    if (photos.isEmpty) {
      return Text(
        '표시할 사진이 없어요.',
        style: ChaerokTypography.bodyMedium.copyWith(
          color: ChaerokColors.textSecondary,
        ),
      );
    }

    return Row(
      children: [
        for (final photo in photos)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: ChaerokSpacing.xs),
              child: AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(ChaerokRadius.sm),
                  child: Image.network(
                    photo.downloadUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const ColoredBox(color: ChaerokColors.sageLight),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReelCard(
    DownloadResponse? reel,
    FilteredPhotoResponse? thumbnail,
  ) {
    if (reel == null) {
      return Text(
        '릴스를 준비하지 못했어요.',
        style: ChaerokTypography.bodyMedium.copyWith(
          color: ChaerokColors.textSecondary,
        ),
      );
    }

    return GestureDetector(
      onTap: () => _openReelPlayer(reel.downloadUrl),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(ChaerokRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              thumbnail == null
                  ? const ColoredBox(color: ChaerokColors.cameraBlack)
                  : Image.network(
                      thumbnail.downloadUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(color: ChaerokColors.cameraBlack),
                    ),
              ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  size: 56,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(FilmRollResultResponse result) {
    final hasReel = result.reel != null;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: hasReel && !_isSaving ? _onSaveTap : null,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: ChaerokLoadingIndicator(strokeWidth: 2),
                  )
                : const Text('저장하기'),
          ),
        ),
        const SizedBox(width: ChaerokSpacing.sm),
        Expanded(
          child: ElevatedButton(
            onPressed: hasReel && !_isSharing ? _onShareTap : null,
            child: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: ChaerokLoadingIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('공유하기'),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${date.year}.${twoDigits(date.month)}.${twoDigits(date.day)}';
  }
}
