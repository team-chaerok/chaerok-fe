import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/camera_shutter_button.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/camera_switch_button.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/camera_top_bar.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/camera_zoom_selector.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_viewfinder_frame.dart';
import 'package:chaerok/features/location/data/location_permission_service.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// 목업에 고정된 필름 타입/카메라 브랜드 표기. 실제 데이터 모델과 연동되는
/// 값이 아니라 촬영 화면의 정적인 UI 카피다.
const _filmTypeLabel = '공주:공주의 잔(殘)';
const _cameraName = 'Chaerok';
const _cameraSubtitle = 'Flim Camera';

/// 촬영 화면 우측 줌 셀렉터에 노출할 배율 후보(위→아래 순서).
/// 실제로는 [_VisitCaptureScreenState._availableZoomLevels]에서 기기가
/// 지원하는 범위로 필터링된다.
const _zoomLevelCandidates = [2.0, 1.0, 0.5];

/// 방문 인증 사진을 촬영하는 화면. 촬영에 성공해 저장까지 마치면
/// `Navigator.pop(true)`로 닫히며, 호출부(FilmRollScreen)가 방문 인증을 이어서 기록한다.
class VisitCaptureScreen extends StatefulWidget {
  const VisitCaptureScreen({
    super.key,
    required this.filmRollId,
    required this.filmRollPlaceId,
  });

  final String filmRollId;
  final String filmRollPlaceId;

  @override
  State<VisitCaptureScreen> createState() => _VisitCaptureScreenState();
}

class _VisitCaptureScreenState extends State<VisitCaptureScreen>
    with WidgetsBindingObserver {
  static const _tag = 'VisitCaptureScreen';

  CameraController? _cameraController;
  String? _errorMessage;
  bool _isSaving = false;
  bool _isInitializingCamera = false;
  bool _isPermissionPermanentlyDenied = false;

  CameraLensDirection _lensDirection = CameraLensDirection.back;
  double _zoomLevel = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  FlashMode _flashMode = FlashMode.off;

  int _photoCount = 0;

  List<double> get _availableZoomLevels => _zoomLevelCandidates
      .where((zoom) => zoom >= _minZoom && zoom <= _maxZoom)
      .toList();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]),
    );
    unawaited(_initializeCamera());
    unawaited(_loadPhotoCount());
  }

  Future<void> _loadPhotoCount() async {
    try {
      final count = await FilmRollModule.instance.getFilmRollPhotoCount(
        widget.filmRollId,
      );
      if (!mounted) return;
      setState(() => _photoCount = count);
    } catch (e, st) {
      log('촬영 매수 조회 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> _initializeCamera() async {
    // 권한 요청 다이얼로그가 뜨고 닫히는 과정 자체가 앱 라이프사이클을
    // inactive/resumed로 흔들어 didChangeAppLifecycleState에서 이 메서드를
    // 다시 호출할 수 있다. 이미 진행 중이면 무시해 카메라 컨트롤러가
    // 중복 생성되어 서로 충돌하는 것을 막는다.
    if (_isInitializingCamera) return;
    _isInitializingCamera = true;
    _isPermissionPermanentlyDenied = false;
    try {
      // 이미 영구 거부된 상태라면 OS가 다이얼로그 없이 현재 상태를 그대로
      // 반환한다(iOS는 최초 1회만 다이얼로그를 띄우고, 이후엔 설정 화면에서만
      // 변경 가능). 이 경우 설정으로 안내해야 한다.
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        if (!mounted) return;
        setState(() {
          _isPermissionPermanentlyDenied = status.isPermanentlyDenied;
          _errorMessage = status.isPermanentlyDenied
              ? '설정 화면에서 카메라 권한을 직접 허용해주세요.'
              : '카메라 권한이 필요해요.';
        });
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() => _errorMessage = '사용 가능한 카메라가 없어요.');
        return;
      }
      final selectedCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == _lensDirection,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        selectedCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      final minZoom = await controller.getMinZoomLevel();
      final maxZoom = await controller.getMaxZoomLevel();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      final clampedZoom = _zoomLevel.clamp(minZoom, maxZoom);
      await controller.setZoomLevel(clampedZoom);
      await controller.setFlashMode(_flashMode);
      setState(() {
        _cameraController = controller;
        _errorMessage = null;
        _minZoom = minZoom;
        _maxZoom = maxZoom;
        _zoomLevel = clampedZoom;
      });
    } catch (e, st) {
      log('카메라 초기화 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() => _errorMessage = '카메라를 시작하지 못했어요.');
    } finally {
      _isInitializingCamera = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final controller = _cameraController;
      if (controller == null || !controller.value.isInitialized) return;
      setState(() => _cameraController = null);
      unawaited(controller.dispose());
    } else if (state == AppLifecycleState.resumed) {
      final controller = _cameraController;
      if (controller != null && controller.value.isInitialized) return;
      unawaited(_initializeCamera());
    }
  }

  Future<void> _onOpenSettingsTap() async {
    await openAppSettings();
  }

  Future<void> _onZoomSelected(double zoom) async {
    final controller = _cameraController;
    if (controller == null) return;

    final clampedZoom = zoom.clamp(_minZoom, _maxZoom);
    await controller.setZoomLevel(clampedZoom);
    if (!mounted) return;
    setState(() => _zoomLevel = clampedZoom);
  }

  Future<void> _onFlashToggle() async {
    final controller = _cameraController;
    if (controller == null) return;

    final nextFlashMode = _flashMode == FlashMode.off
        ? FlashMode.always
        : FlashMode.off;
    await controller.setFlashMode(nextFlashMode);
    if (!mounted) return;
    setState(() => _flashMode = nextFlashMode);
  }

  Future<void> _onCameraSwitch() async {
    if (_isInitializingCamera) return;

    final controller = _cameraController;
    if (controller != null) {
      setState(() => _cameraController = null);
      await controller.dispose();
    }
    _lensDirection = _lensDirection == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    await _initializeCamera();
  }

  Future<void> _onCaptureTap() async {
    final controller = _cameraController;
    if (controller == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final file = await controller.takePicture();
      final bytes = await file.readAsBytes();
      final position = await LocationPermissionService.getCurrentPosition();

      await FilmRollModule.instance.savePhoto(
        filmRollId: widget.filmRollId,
        filmRollPlaceId: widget.filmRollPlaceId,
        imageBytes: bytes,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e, st) {
      log('사진 저장 실패', name: _tag, error: e, stackTrace: st);
      if (!mounted) return;
      setState(() {
        _errorMessage = '사진 저장에 실패했어요.';
        _isSaving = false;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_cameraController?.dispose());
    unawaited(
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]),
    );
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.primaryLight,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(ChaerokSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: ChaerokTypography.bodyMedium.copyWith(
                  color: ChaerokColors.textPrimary,
                ),
              ),
              if (_isPermissionPermanentlyDenied) ...[
                const SizedBox(height: ChaerokSpacing.lg),
                ChaerokButton(
                  text: '설정에서 권한 허용하기',
                  onPressed: _onOpenSettingsTap,
                ),
              ],
            ],
          ),
        ),
      );
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: ChaerokLoadingIndicator(color: ChaerokColors.primary),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(ChaerokSpacing.lg),
      child: Column(
        children: [
          CameraTopBar(
            flashMode: _flashMode,
            filmTypeLabel: _filmTypeLabel,
            photoCount: _photoCount,
            maxPhotoCount: FilmRoll.maxExposureCount,
            onFlashToggle: _onFlashToggle,
            onClose: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: ChaerokSpacing.lg),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: FilmViewfinderFrame(
                              child: CameraPreview(controller),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: ChaerokSpacing.md),
                      Text(
                        _cameraName,
                        style: ChaerokTypography.headingLarge.copyWith(
                          color: ChaerokColors.textPrimary,
                        ),
                      ),
                      Text(
                        _cameraSubtitle,
                        style: ChaerokTypography.caption.copyWith(
                          color: ChaerokColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: ChaerokSpacing.lg),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CameraZoomSelector(
                      availableZoomLevels: _availableZoomLevels,
                      selectedZoomLevel: _zoomLevel,
                      onZoomSelected: _onZoomSelected,
                    ),
                    const SizedBox(height: ChaerokSpacing.xl),
                    CameraShutterButton(
                      onPressed: _onCaptureTap,
                      isLoading: _isSaving,
                    ),
                    const SizedBox(height: ChaerokSpacing.lg),
                    CameraSwitchButton(onPressed: _onCameraSwitch),
                  ],
                ),
              ],
            ),
          ),

          ///  TODO : 디자인 수정할 때까지 임시로 주석 처리
          // const SizedBox(height: ChaerokSpacing.lg),
          // CaptureFilmStrip(controller: controller),
        ],
      ),
    );
  }
}
