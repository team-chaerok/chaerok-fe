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
import 'package:chaerok/shared/widgets/chaerok_button.dart';
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

  /// iOS 공유 창은 기준 위치(sharePositionOrigin)가 반드시 필요해서, 공유하기
  /// 버튼의 화면 좌표를 여기서 얻는다.
  final GlobalKey _shareButtonKey = GlobalKey();

  final PageController _representativePageController = PageController();
  int _representativePageIndex = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialResult != null) {
      _result = widget.initialResult;
    } else {
      unawaited(_fetchResult());
    }
  }

  @override
  void dispose() {
    _representativePageController.dispose();
    super.dispose();
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

  /// 저장/공유 둘 다 같은 임시 파일 경로를 쓰므로([_downloadReelToTempFile])
  /// 동시에 실행되면 한쪽이 쓰는 중인 파일을 다른 쪽이 읽어 손상된 파일을
  /// 저장/공유할 수 있다. 두 동작을 상호 배타적으로 만든다.
  bool get _isBusyWithReel => _isSaving || _isSharing;

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

  /// 저장/공유 직전에 릴스 다운로드 URL의 유효기간을 확인하고, 만료(임박)면
  /// `/results`를 다시 조회해 새 presigned URL로 교체한다. 서버 필름롤 id가
  /// 없으면(이론상 발생하지 않음) 기존 값을 그대로 반환한다.
  Future<DownloadResponse?> _freshReel() async {
    final reel = _result?.reel;
    if (reel == null) return null;

    const refreshBuffer = Duration(seconds: 30);
    if (reel.downloadUrlExpiresAt.isAfter(DateTime.now().add(refreshBuffer))) {
      return reel;
    }

    final serverFilmRollId = widget.filmRoll.serverFilmRollId;
    if (serverFilmRollId == null) return reel;

    try {
      final refreshed = await FilmRollsApi.getFilmRollResult(serverFilmRollId);
      if (mounted) setState(() => _result = refreshed);
      return refreshed.reel ?? reel;
    } catch (e, st) {
      log('릴스 URL 갱신 실패', name: _tag, error: e, stackTrace: st);
      return reel;
    }
  }

  Future<void> _onSaveTap() async {
    if (_result?.reel == null || _isBusyWithReel) return;

    setState(() => _isSaving = true);
    try {
      final reel = await _freshReel();
      if (reel == null) return;
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
    if (_result?.reel == null || _isBusyWithReel) return;

    // 다운로드 등 await 이전에 버튼 위치를 잡아 둔다(이후엔 레이아웃이 바뀔 수 있음).
    final shareBox = _shareButtonKey.currentContext?.findRenderObject();
    final shareOrigin = shareBox is RenderBox && shareBox.hasSize
        ? shareBox.localToGlobal(Offset.zero) & shareBox.size
        : null;

    setState(() => _isSharing = true);
    try {
      final reel = await _freshReel();
      if (reel == null) return;
      final path = await _downloadReelToTempFile(reel);
      await Share.shareXFiles([XFile(path)], sharePositionOrigin: shareOrigin);
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

  /// 결과 화면을 오래 열어 둔 뒤 재생하면 presigned URL이 만료돼 있을 수
  /// 있으므로, 재생 직전에 [_freshReel]로 유효기간을 확인·갱신한다.
  Future<void> _openReelPlayer() async {
    final reel = await _freshReel();
    if (reel == null || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ReelPlayerPage(videoUrl: reel.downloadUrl),
      ),
    );
  }

  void _openAllPhotos() {
    // 대표 사진 캐러셀([_buildBody])과 같은 순서(코스 sequence 오름차순)로
    // 보여준다 — 정렬하지 않으면 서버가 준 순서 그대로라 대표 사진과
    // "전체 사진" 화면의 순서가 어긋날 수 있다.
    final photos = List<FilteredPhotoResponse>.of(
      _result?.filteredPhotos ?? const [],
    )..sort((a, b) => a.sequence.compareTo(b.sequence));
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

    final photos = [...result.filteredPhotos]
      ..sort((a, b) => a.sequence.compareTo(b.sequence));
    final previewPhotos = photos.take(3).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(),
          const SizedBox(height: ChaerokSpacing.md),
          _buildRepresentativeImage(photos),
          const SizedBox(height: ChaerokSpacing.sm),
          _buildStatsRow(result),
          const SizedBox(height: ChaerokSpacing.xl),
          _buildSectionTitle('오늘의 사진', onSeeAll: _openAllPhotos),
          const SizedBox(height: ChaerokSpacing.sm),
          _buildPhotoPreviewRow(previewPhotos),
          const SizedBox(height: ChaerokSpacing.xl),
          _buildSectionTitle('오늘의 릴스'),
          const SizedBox(height: ChaerokSpacing.sm),
          _buildReelCard(result.reel, photos.isEmpty ? null : photos.first),
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

  /// 코스 순서([FilteredPhotoResponse.sequence] 오름차순)대로 좌우 스와이프되는
  /// 대표 사진. 관광지 → 식당 → 카페 순으로 방문·촬영되므로 정렬된 목록을
  /// 그대로 넘기면 스와이프 순서가 코스 순서와 일치한다.
  Widget _buildRepresentativeImage(List<FilteredPhotoResponse> photos) {
    final pageCount = photos.isEmpty ? 1 : photos.length;
    final safeIndex = _representativePageIndex >= pageCount
        ? pageCount - 1
        : _representativePageIndex;

    return AspectRatio(
      aspectRatio: 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(ChaerokRadius.lg),
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _representativePageController,
              itemCount: pageCount,
              onPageChanged: (i) =>
                  setState(() => _representativePageIndex = i),
              itemBuilder: (context, i) {
                if (photos.isEmpty) {
                  return const ColoredBox(color: ChaerokColors.sageLight);
                }
                return Image.network(
                  photos[i].downloadUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const ColoredBox(color: ChaerokColors.sageLight),
                );
              },
            ),
            if (photos.length > 1)
              Positioned(
                right: ChaerokSpacing.sm,
                bottom: ChaerokSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: ChaerokSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(ChaerokRadius.sm),
                  ),
                  child: Text(
                    '${safeIndex + 1}/$pageCount',
                    style: ChaerokTypography.caption.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
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

    // 릴스는 9:16 세로 영상이라 카드도 세로형으로 그리되, 스크롤 화면에서
    // 화면을 다 차지하지 않도록 폭을 제한해 가운데 정렬한다.
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.6,
        child: GestureDetector(
          onTap: () => unawaited(_openReelPlayer()),
          child: AspectRatio(
            aspectRatio: 9 / 16,
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
                              const ColoredBox(
                                color: ChaerokColors.cameraBlack,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildActionButtons(FilmRollResultResponse result) {
    final hasReel = result.reel != null;
    // 테마 primary가 연한 세이지색이라 기본 스타일에서는 글자가 배경에 묻힌다.
    // 강조색(primaryDark)을 글자/배경에 명시해 대비를 확보한다.
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton(
              onPressed: hasReel && !_isBusyWithReel ? _onSaveTap : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: ChaerokColors.primaryDark,
                disabledForegroundColor: ChaerokColors.textDisabled,
                side: BorderSide(
                  color: hasReel && !_isBusyWithReel
                      ? ChaerokColors.primaryDark
                      : ChaerokColors.border,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ChaerokRadius.md),
                ),
                textStyle: ChaerokTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: ChaerokLoadingIndicator(
                        color: ChaerokColors.primaryDark,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('저장하기'),
            ),
          ),
        ),
        const SizedBox(width: ChaerokSpacing.sm),
        Expanded(
          child: KeyedSubtree(
            key: _shareButtonKey,
            child: ChaerokButton(
              text: '공유하기',
              backgroundColor: ChaerokColors.primaryDark,
              isEnabled: hasReel && !_isBusyWithReel,
              isLoading: _isSharing,
              onPressed: _onShareTap,
            ),
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
