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
import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:chaerok/features/film_roll/domain/usecase/cache_filtered_photos_use_case.dart';
import 'package:chaerok/features/film_roll/domain/usecase/get_film_roll_result_photos_use_case.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_result_photo_viewer_page.dart';
import 'package:chaerok/features/film_roll/presentation/page/film_roll_result_photos_screen.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_result_featured_frame.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_result_photo_image.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_result_photo_strip.dart';
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
///
/// 서버는 현상 결과를 현상 완료 후 일정 기간만 보관한다. 보관 기간 안에 이
/// 화면을 열면 필터 사진을 기기에 받아 두고, 기간이 지나면(`EXPIRED`) 릴스는
/// 보관 종료로 안내하되 사진은 기기에 있는 것으로 계속 보여준다.
class FilmRollResultScreen extends StatefulWidget {
  const FilmRollResultScreen({
    super.key,
    required this.filmRoll,
    this.initialResult,
    Future<FilmRollResultResponse> Function(int filmRollId)? getFilmRollResult,
    GetFilmRollResultPhotosUseCase? getResultPhotos,
    CacheFilteredPhotosUseCase? cacheFilteredPhotos,
  }) : _getFilmRollResult = getFilmRollResult,
       _getResultPhotos = getResultPhotos,
       _cacheFilteredPhotos = cacheFilteredPhotos;

  final FilmRoll filmRoll;
  final FilmRollResultResponse? initialResult;
  final Future<FilmRollResultResponse> Function(int filmRollId)?
  _getFilmRollResult;
  final GetFilmRollResultPhotosUseCase? _getResultPhotos;
  final CacheFilteredPhotosUseCase? _cacheFilteredPhotos;

  @override
  State<FilmRollResultScreen> createState() => _FilmRollResultScreenState();
}

class _FilmRollResultScreenState extends State<FilmRollResultScreen> {
  static const _tag = 'FilmRollResultScreen';
  static const _reelExpiredMessage = '릴스 보관 기간이 끝났어요. 촬영한 사진은 계속 볼 수 있어요.';
  static const _reelNotDevelopedMessage = '현상된 릴스가 없어요. 촬영한 사진은 계속 볼 수 있어요.';

  late final Future<FilmRollResultResponse> Function(int filmRollId)
  _getFilmRollResult =
      widget._getFilmRollResult ?? FilmRollsApi.getFilmRollResult;
  late final GetFilmRollResultPhotosUseCase _getResultPhotos =
      widget._getResultPhotos ??
      FilmRollModule.instance.getFilmRollResultPhotos;
  late final CacheFilteredPhotosUseCase _cacheFilteredPhotos =
      widget._cacheFilteredPhotos ??
      FilmRollModule.instance.cacheFilteredPhotos;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSharing = false;
  bool _isCachingPhotos = false;
  String? _errorMessage;
  FilmRollResultResponse? _result;

  /// 화면에 보여줄 사진(촬영 순서). [_result]가 바뀔 때마다 [_loadPhotos]가
  /// 기기에 보관된 사진까지 반영해 다시 채운다.
  List<FilmRollResultPhoto> _photos = const [];

  /// iOS 공유 창은 기준 위치(sharePositionOrigin)가 반드시 필요해서, 공유하기
  /// 버튼의 화면 좌표를 여기서 얻는다.
  final GlobalKey _shareButtonKey = GlobalKey();

  final PageController _representativePageController = PageController();
  int _representativePageIndex = 0;

  @override
  void initState() {
    super.initState();
    final initialResult = widget.initialResult;
    if (initialResult != null) {
      _result = initialResult;
      _photos = GetFilmRollResultPhotosUseCase.fromServer(initialResult);
      // 보관 기간이 지난 결과는 서버 사진이 없어 기기 사진을 읽어야 그릴 수 있다.
      _isLoading = initialResult.isExpired;
      unawaited(_loadPhotos(initialResult));
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

    final FilmRollResultResponse result;
    try {
      result = await _getFilmRollResult(serverFilmRollId);
    } catch (e, st) {
      log('현상 결과 조회 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _errorMessage = '필름롤 결과를 불러오지 못했어요.';
        _isLoading = false;
      });
      return;
    }
    if (!mounted) return;
    _applyResult(result);
  }

  /// 새로 받은 결과를 화면에 반영한다. 보관 기간 안이면 서버 사진으로 바로
  /// 그리고, 기간이 지났으면 기기 사진을 읽을 때까지 로딩을 유지한다.
  void _applyResult(FilmRollResultResponse result) {
    setState(() {
      _result = result;
      // URL만 갱신된 재조회라면 [_loadPhotos]가 끝날 때까지 보던 사진을 그대로
      // 둬, 기기 파일로 그리던 사진이 잠깐 서버 사진으로 바뀌며 깜빡이지 않게 한다.
      if (_photos.isEmpty || result.isExpired) {
        _photos = GetFilmRollResultPhotosUseCase.fromServer(result);
      }
      _isLoading = result.isExpired;
    });
    unawaited(_loadPhotos(result));
  }

  /// 기기에 보관된 사진을 반영해 [_photos]를 채우고, 보관 기간 안이면 아직
  /// 받지 않은 필터 사진을 기기에 내려받아 둔다. 실패해도 서버 사진만으로
  /// 화면은 계속 쓸 수 있으므로 오류 화면으로 바꾸지 않는다.
  Future<void> _loadPhotos(FilmRollResultResponse result) async {
    // 보관 기간 안인데 사진이 없으면 읽을 것도 받을 것도 없다.
    if (result.isCompleted && result.filteredPhotos.isEmpty) return;

    try {
      final photos = await _getResultPhotos(
        filmRollId: widget.filmRoll.id,
        result: result,
      );
      // 읽는 사이 결과가 다시 조회됐으면 오래된 목록으로 덮어쓰지 않는다.
      if (mounted && identical(_result, result)) {
        setState(() => _photos = photos);
      }
    } catch (e, st) {
      log('현상 결과 사진 조회 실패', name: _tag, error: e, stackTrace: st);
      if (mounted && identical(_result, result)) {
        setState(
          () => _photos = GetFilmRollResultPhotosUseCase.fromServer(result),
        );
      }
    } finally {
      if (mounted && identical(_result, result) && _isLoading) {
        setState(() => _isLoading = false);
      }
    }

    if (!result.isCompleted || _isCachingPhotos) return;
    _isCachingPhotos = true;
    try {
      await _cacheFilteredPhotos(
        filmRollId: widget.filmRoll.id,
        photos: result.filteredPhotos,
      );
    } catch (e, st) {
      log('필터 사진 보관 실패', name: _tag, error: e, stackTrace: st);
    } finally {
      _isCachingPhotos = false;
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
  /// 없으면(이론상 발생하지 않음) 기존 값을 그대로 반환한다. 다시 조회했더니
  /// 결과 보관 기간이 지나 있으면 화면을 보관 종료 상태로 바꾸고 null을 반환한다.
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
      final refreshed = await _getFilmRollResult(serverFilmRollId);
      if (!mounted) return null;
      _applyResult(refreshed);
      if (refreshed.isExpired) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text(_reelExpiredMessage)));
        return null;
      }
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

  void _openPhotoViewer(int index) {
    final photos = _photos;
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FilmRollResultPhotoViewerPage(
            photos: photos,
            initialIndex: index,
          ),
        ),
      ),
    );
  }

  void _openAllPhotos() {
    // 대표 사진 캐러셀([_buildBody])과 같은 목록([_photos], 촬영 순서)을
    // 넘겨 대표 사진과 "전체 사진" 화면의 순서가 어긋나지 않게 한다.
    final photos = _photos;
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

    final photos = _photos;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: ChaerokSpacing.xl,
        bottom: ChaerokSpacing.xxl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _padded(_buildHeader(result)),
          const SizedBox(height: ChaerokSpacing.xl),
          _padded(_buildRepresentativeImage(photos)),
          _buildSectionDivider(),
          _padded(
            _buildSectionTitle(
              '오늘의 사진',
              count: photos.isEmpty ? null : '${photos.length}장',
              onSeeAll: photos.isEmpty ? null : _openAllPhotos,
            ),
          ),
          const SizedBox(height: ChaerokSpacing.sm),
          _buildPhotoFilmStrip(photos),
          _buildSectionDivider(),
          _padded(_buildReelTitle(result)),
          const SizedBox(height: ChaerokSpacing.md),
          _padded(
            _buildReelSection(result, photos.isEmpty ? null : photos.first),
          ),
          const SizedBox(height: ChaerokSpacing.xl),
          _padded(_buildActionButtons(result)),
        ],
      ),
    );
  }

  Widget _padded(Widget child) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.lg),
      child: child,
    );
  }

  Widget _buildSectionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ChaerokSpacing.lg,
        vertical: ChaerokSpacing.xl,
      ),
      child: Divider(height: 1, thickness: 1, color: ChaerokColors.border),
    );
  }

  /// 현상 완료 제목과 이 필름롤의 지역·날짜·방문/촬영 수.
  Widget _buildHeader(FilmRollResultResponse result) {
    final regionCode = widget.filmRoll.regionCode;
    final completedAt = widget.filmRoll.completedAt;
    final secondaryStyle = ChaerokTypography.bodyMedium.copyWith(
      color: ChaerokColors.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DEVELOPED FILM',
          style: ChaerokTypography.caption.copyWith(
            color: ChaerokColors.textSecondary,
            fontSize: 10,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: ChaerokSpacing.xs),
        Text(
          '현상 완료',
          style: ChaerokTypography.displayMedium.copyWith(
            color: ChaerokColors.primaryDark,
            fontSize: 40,
            height: 1.2,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: ChaerokSpacing.xs),
        Text(
          '${regionCode.displayName}에서 담은 순간들이 도착했어요.',
          style: ChaerokTypography.bodyLarge.copyWith(
            color: ChaerokColors.textPrimary,
          ),
        ),
        const SizedBox(height: ChaerokSpacing.md),
        Text(
          '${regionCode.name.toUpperCase()} · ${regionCode.cityCountyName}',
          style: secondaryStyle.copyWith(letterSpacing: 1),
        ),
        const SizedBox(height: ChaerokSpacing.xxs),
        Text(
          [
            if (completedAt != null) _formatDate(completedAt),
            '방문 ${widget.filmRoll.visitedPlaceCount}곳',
            '촬영 ${result.totalPhotoCount}장',
          ].join(' · '),
          style: secondaryStyle,
        ),
      ],
    );
  }

  /// 코스 순서([FilmRollResultPhoto.sequence] 오름차순)대로 좌우 스와이프되는
  /// 대표 사진. 관광지 → 식당 → 카페 순으로 방문·촬영되므로 정렬된 목록을
  /// 그대로 넘기면 스와이프 순서가 코스 순서와 일치한다. 필름 띠에는 지역과
  /// 현상 날짜, 지금 보는 칸 번호를 새기고, 틀 아래에 필름롤 이름과 위치를 둔다.
  Widget _buildRepresentativeImage(List<FilmRollResultPhoto> photos) {
    final pageCount = photos.isEmpty ? 1 : photos.length;
    final safeIndex = _representativePageIndex >= pageCount
        ? pageCount - 1
        : _representativePageIndex;
    final completedAt = widget.filmRoll.completedAt;
    String twoDigits(int n) => n.toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilmRollResultFeaturedFrame(
          topLabel:
              'CHAEROK · ${widget.filmRoll.regionCode.name.toUpperCase()}',
          dateLabel: completedAt == null ? null : _formatDate(completedAt),
          frameLabel: photos.isEmpty
              ? null
              : twoDigits(photos[safeIndex].sequence),
          child: PageView.builder(
            controller: _representativePageController,
            itemCount: pageCount,
            onPageChanged: (i) => setState(() => _representativePageIndex = i),
            itemBuilder: (context, i) {
              if (photos.isEmpty) {
                return const ColoredBox(color: ChaerokColors.sageLight);
              }
              return GestureDetector(
                onTap: () => _openPhotoViewer(i),
                child: FilmRollResultPhotoImage(photo: photos[i]),
              );
            },
          ),
        ),
        const SizedBox(height: ChaerokSpacing.sm),
        Row(
          children: [
            Expanded(
              child: Text(
                widget.filmRoll.title,
                overflow: TextOverflow.ellipsis,
                style: ChaerokTypography.bodyMedium.copyWith(
                  color: ChaerokColors.textSecondary,
                ),
              ),
            ),
            if (photos.isNotEmpty)
              Text(
                '${twoDigits(safeIndex + 1)} / ${twoDigits(pageCount)}',
                style: ChaerokTypography.bodyMedium.copyWith(
                  color: ChaerokColors.textSecondary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    String title, {
    String? count,
    VoidCallback? onSeeAll,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(title, style: ChaerokTypography.titleMedium),
        if (count != null) ...[
          const SizedBox(width: ChaerokSpacing.xs),
          Text(
            count,
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
        ],
        const Spacer(),
        if (onSeeAll != null)
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              foregroundColor: ChaerokColors.textSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: ChaerokSpacing.xs,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('전체 보기', style: ChaerokTypography.bodyMedium),
                Icon(Icons.chevron_right, size: 18),
              ],
            ),
          ),
      ],
    );
  }

  /// 촬영한 사진 전체를 가로로 넘겨 보는 필름 스트립. 화면 오른쪽 끝까지
  /// 필름이 이어지고, 칸을 누르면 그 사진부터 전체 화면으로 본다.
  Widget _buildPhotoFilmStrip(List<FilmRollResultPhoto> photos) {
    if (photos.isEmpty) {
      return _padded(
        Text(
          '표시할 사진이 없어요.',
          style: ChaerokTypography.bodyMedium.copyWith(
            color: ChaerokColors.textSecondary,
          ),
        ),
      );
    }

    return FilmRollResultPhotoStrip(
      photos: photos,
      onPhotoTap: _openPhotoViewer,
      padding: const EdgeInsets.symmetric(horizontal: ChaerokSpacing.lg),
    );
  }

  Widget _buildReelTitle(FilmRollResultResponse result) {
    final secondaryStyle = ChaerokTypography.bodyMedium.copyWith(
      color: ChaerokColors.textSecondary,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Text('오늘의 릴스', style: ChaerokTypography.titleMedium),
            const Spacer(),
            if (!result.isExpired && result.reel != null)
              Text('9:16', style: secondaryStyle),
          ],
        ),
        const SizedBox(height: ChaerokSpacing.xxs),
        Text('한 롤의 순간을 하나의 영상으로', style: secondaryStyle),
      ],
    );
  }

  /// 보관 기간이 지났으면 릴스 대신 보관 종료 안내를, 기간 안이면 릴스 카드와
  /// 언제까지 볼 수 있는지를 보여준다.
  Widget _buildReelSection(
    FilmRollResultResponse result,
    FilmRollResultPhoto? thumbnail,
  ) {
    if (result.isExpired) {
      return _buildReelExpiredNotice(
        result.isRetentionExpired
            ? _reelExpiredMessage
            : _reelNotDevelopedMessage,
      );
    }

    final expiresAt = result.expiresAt;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildReelCard(result.reel, thumbnail),
        if (result.reel != null && expiresAt != null) ...[
          const SizedBox(height: ChaerokSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.schedule,
                size: 18,
                color: ChaerokColors.textSecondary,
              ),
              const SizedBox(width: ChaerokSpacing.xxs),
              Flexible(
                child: Text(
                  '${_formatDateTime(expiresAt.toLocal())}까지 볼 수 있어요',
                  style: ChaerokTypography.bodyMedium.copyWith(
                    color: ChaerokColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: ChaerokSpacing.xxs),
          Text(
            '기간이 지나기 전에 저장해 주세요.',
            textAlign: TextAlign.center,
            style: ChaerokTypography.caption.copyWith(
              color: ChaerokColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildReelExpiredNotice(String message) {
    return Container(
      padding: const EdgeInsets.all(ChaerokSpacing.md),
      decoration: BoxDecoration(
        color: ChaerokColors.sageLight,
        borderRadius: BorderRadius.circular(ChaerokRadius.md),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: ChaerokTypography.bodyMedium.copyWith(
          color: ChaerokColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildReelCard(
    DownloadResponse? reel,
    FilmRollResultPhoto? thumbnail,
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
              borderRadius: BorderRadius.circular(ChaerokRadius.sm),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  thumbnail == null
                      ? const ColoredBox(color: ChaerokColors.cameraBlack)
                      : FilmRollResultPhotoImage(
                          photo: thumbnail,
                          placeholderColor: ChaerokColors.cameraBlack,
                          showUnfilteredLabel: false,
                        ),
                  ColoredBox(color: Colors.black.withValues(alpha: 0.12)),
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.25),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
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
    final isEnabled = result.reel != null && !_isBusyWithReel;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(ChaerokRadius.md),
    );
    final textStyle = ChaerokTypography.bodyMedium.copyWith(
      fontWeight: FontWeight.w600,
    );
    // 저장이 주된 동작이라 채운 버튼으로, 공유는 보조 동작이라 외곽선 버튼으로 둔다.
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: SizedBox(
            key: _shareButtonKey,
            height: 48,
            child: OutlinedButton(
              onPressed: isEnabled ? _onShareTap : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: ChaerokColors.textPrimary,
                disabledForegroundColor: ChaerokColors.textDisabled,
                side: const BorderSide(color: ChaerokColors.border, width: 1.5),
                shape: shape,
                textStyle: textStyle,
              ),
              child: _isSharing
                  ? const ChaerokLoadingIndicator(
                      color: ChaerokColors.primaryDark,
                      size: 20,
                      strokeWidth: 2,
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.ios_share, size: 18),
                        SizedBox(width: ChaerokSpacing.xxs),
                        Flexible(
                          child: Text('공유하기', overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
            ),
          ),
        ),
        const SizedBox(width: ChaerokSpacing.sm),
        Expanded(
          flex: 3,
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: isEnabled ? _onSaveTap : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: ChaerokColors.primaryDark,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _isSaving
                    ? ChaerokColors.primaryDark
                    : ChaerokColors.border,
                disabledForegroundColor: ChaerokColors.textDisabled,
                elevation: 0,
                shape: shape,
                textStyle: textStyle,
              ),
              child: _isSaving
                  ? const ChaerokLoadingIndicator(
                      color: ChaerokColors.background,
                      size: 20,
                      strokeWidth: 2,
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.file_download_outlined, size: 20),
                        SizedBox(width: ChaerokSpacing.xs),
                        Text('저장하기'),
                      ],
                    ),
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

  String _formatDateTime(DateTime date) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    return '${date.month}월 ${date.day}일 '
        '${twoDigits(date.hour)}:${twoDigits(date.minute)}';
  }
}
