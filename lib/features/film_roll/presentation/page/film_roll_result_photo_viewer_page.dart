import 'dart:async';
import 'dart:developer';

import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_radius.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_result_photo.dart';
import 'package:chaerok/features/film_roll/domain/usecase/save_result_photo_to_gallery_use_case.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_roll_result_photo_image.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

/// 현상 결과 사진을 전체 화면으로 보는 페이지. 좌우로 넘겨 다른 사진을 보고,
/// 확대·축소하고, 지금 보는 사진을 갤러리에 저장할 수 있다.
class FilmRollResultPhotoViewerPage extends StatefulWidget {
  const FilmRollResultPhotoViewerPage({
    super.key,
    required this.photos,
    this.initialIndex = 0,
    SaveResultPhotoToGalleryUseCase? savePhotoToGallery,
  }) : _savePhotoToGallery = savePhotoToGallery;

  final List<FilmRollResultPhoto> photos;
  final int initialIndex;
  final SaveResultPhotoToGalleryUseCase? _savePhotoToGallery;

  @override
  State<FilmRollResultPhotoViewerPage> createState() =>
      _FilmRollResultPhotoViewerPageState();
}

class _FilmRollResultPhotoViewerPageState
    extends State<FilmRollResultPhotoViewerPage> {
  static const _tag = 'FilmRollResultPhotoViewerPage';

  late final SaveResultPhotoToGalleryUseCase _savePhotoToGallery =
      widget._savePhotoToGallery ??
      FilmRollModule.instance.saveResultPhotoToGallery;

  late final PageController _pageController = PageController(
    initialPage: widget.initialIndex,
  );
  late int _index = widget.initialIndex;

  /// 지금 보는 사진이 확대된 상태인지. 확대 중에는 끌기를 사진 이동에 쓰도록
  /// 좌우 넘김을 막는다.
  bool _isZoomed = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _onSaveTap() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    String message;
    try {
      await _savePhotoToGallery(widget.photos[_index]);
      message = '갤러리에 저장했어요.';
    } on GalException catch (e, st) {
      log('사진 저장 실패', name: _tag, error: e, stackTrace: st);
      message = e.type == GalExceptionType.accessDenied
          ? '사진을 저장하려면 설정에서 사진 접근을 허용해 주세요.'
          : '저장에 실패했어요.';
    } catch (e, st) {
      log('사진 저장 실패', name: _tag, error: e, stackTrace: st);
      message = '저장에 실패했어요.';
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final photo = widget.photos[_index];
    return Scaffold(
      backgroundColor: ChaerokColors.cameraBlack,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: _isZoomed
                    ? const NeverScrollableScrollPhysics()
                    : const PageScrollPhysics(),
                itemCount: widget.photos.length,
                onPageChanged: (i) => setState(() {
                  _index = i;
                  _isZoomed = false;
                }),
                itemBuilder: (context, i) => _ZoomablePhoto(
                  key: ValueKey(i),
                  photo: widget.photos[i],
                  onZoomChanged: (isZoomed) {
                    if (i == _index && isZoomed != _isZoomed) {
                      setState(() => _isZoomed = isZoomed);
                    }
                  },
                ),
              ),
            ),
            _buildBottomBar(photo),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    // 닫기 버튼과 같은 폭을 오른쪽에도 비워 두어, 위치 표시가 화면 가운데에
    // 오면서 버튼과 겹치지 않게 한다.
    const sideWidth = 48.0;
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const SizedBox(width: ChaerokSpacing.xxs),
          SizedBox(
            width: sideWidth,
            child: IconButton(
              tooltip: '닫기',
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => unawaited(Navigator.of(context).maybePop()),
            ),
          ),
          Expanded(
            child: Text(
              '${_index + 1} / ${widget.photos.length}',
              textAlign: TextAlign.center,
              style: ChaerokTypography.bodyMedium.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: sideWidth + ChaerokSpacing.xxs),
        ],
      ),
    );
  }

  Widget _buildBottomBar(FilmRollResultPhoto photo) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ChaerokSpacing.md,
        ChaerokSpacing.sm,
        ChaerokSpacing.md,
        ChaerokSpacing.md,
      ),
      child: Row(
        children: [
          if (!photo.isFiltered)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ChaerokSpacing.xs,
                vertical: ChaerokSpacing.xxs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(ChaerokRadius.sm),
              ),
              child: Text(
                FilmRollResultPhotoImage.unfilteredLabel,
                style: ChaerokTypography.caption.copyWith(color: Colors.white),
              ),
            ),
          const Spacer(),
          TextButton.icon(
            onPressed: _isSaving ? null : _onSaveTap,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(
                horizontal: ChaerokSpacing.md,
              ),
              textStyle: ChaerokTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: ChaerokLoadingIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.download_rounded),
            label: const Text('갤러리에 저장'),
          ),
        ],
      ),
    );
  }
}

/// 손가락으로 확대·축소하고, 두 번 탭하면 그 지점을 확대(다시 두 번 탭하면
/// 원래 크기)하는 사진 한 장.
class _ZoomablePhoto extends StatefulWidget {
  const _ZoomablePhoto({
    super.key,
    required this.photo,
    required this.onZoomChanged,
  });

  final FilmRollResultPhoto photo;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePhoto> createState() => _ZoomablePhotoState();
}

class _ZoomablePhotoState extends State<_ZoomablePhoto> {
  static const _maxScale = 4.0;
  static const _doubleTapScale = 2.5;

  final _transformationController = TransformationController();
  Offset _lastDoubleTapPosition = Offset.zero;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformationController
      ..removeListener(_onTransformChanged)
      ..dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final isZoomed = _transformationController.value.getMaxScaleOnAxis() > 1.01;
    if (isZoomed == _isZoomed) return;
    _isZoomed = isZoomed;
    widget.onZoomChanged(isZoomed);
  }

  void _onDoubleTap() {
    if (_isZoomed) {
      _transformationController.value = Matrix4.identity();
      return;
    }
    final position = _lastDoubleTapPosition;
    _transformationController.value = Matrix4.identity()
      ..translateByDouble(
        -position.dx * (_doubleTapScale - 1),
        -position.dy * (_doubleTapScale - 1),
        0,
        1,
      )
      ..scaleByDouble(_doubleTapScale, _doubleTapScale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) =>
          _lastDoubleTapPosition = details.localPosition,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transformationController,
        maxScale: _maxScale,
        child: SizedBox.expand(
          child: FilmRollResultPhotoImage(
            photo: widget.photo,
            fit: BoxFit.contain,
            placeholderColor: ChaerokColors.cameraBlack,
            showUnfilteredLabel: false,
          ),
        ),
      ),
    );
  }
}
