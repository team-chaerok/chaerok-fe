import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:chaerok/core/design_system/chaerok_colors.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/core/file/captured_photo_orientation.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll_place.dart';
import 'package:chaerok/features/film_roll/domain/repository/film_roll_exceptions.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/camera_bottom_pattern.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/camera_shutter_button.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/camera_switch_button.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/camera_top_bar.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/camera_zoom_selector.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/film_viewfinder_frame.dart';
import 'package:chaerok/features/location/data/location_permission_service.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 카메라 브랜드 표기. 실제 데이터 모델과 연동되는 값이 아니라 촬영 화면의
/// 정적인 UI 카피다.
const _cameraName = 'Chaerok';
const _cameraSubtitle = 'Film Camera';

/// 촬영 화면 우측 줌 셀렉터에 노출할 배율 후보(위→아래 순서, 회전 후 좌→우로 보인다).
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
    @visibleForTesting this.debugFetchPhotoCount,
    @visibleForTesting this.debugFetchRegionCode,
  });

  final String filmRollId;
  final String filmRollPlaceId;

  /// 테스트에서 실제 DB 조회 대신 촬영 매수를 주입하기 위한 훅.
  @visibleForTesting
  final Future<int> Function()? debugFetchPhotoCount;

  /// 테스트에서 실제 DB 조회 대신 필름롤 지역을 주입하기 위한 훅.
  @visibleForTesting
  final Future<RegionCode?> Function()? debugFetchRegionCode;

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
  bool _isSwitchingCamera = false;
  bool _isPermissionPermanentlyDenied = false;

  CameraLensDirection _lensDirection = CameraLensDirection.back;
  double _zoomLevel = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  FlashMode _flashMode = FlashMode.off;

  /// 앱은 세로 전용이고 폰을 돌리지 않는다. 대신 촬영 화면 본문 전체를 이만큼
  /// 회전시켜 그려, 세로로 든 폰에서도 필름 카메라 같은 가로 UI로 보이게 한다.
  /// (iOS 인터페이스 회전 강제는 iOS 16+에서 거부/프리뷰 불일치가 생겨 쓰지 않음)
  /// 방향이 통째로 90° 반대면 이 값을 3으로 바꾼다.
  static const _bodyQuarterTurns = 1;

  /// 저장 사진을 돌릴 횟수. 전면 카메라 파일은 후면과 회전 기준이 180° 달라서
  /// (실기기 셀카가 상하 반전으로 저장됨) 2번을 더한다.
  int get _photoQuarterTurns => _lensDirection == CameraLensDirection.front
      ? (_bodyQuarterTurns + 2) % 4
      : _bodyQuarterTurns;

  /// 뷰파인더 안의 실제 카메라 프리뷰만은 [_bodyQuarterTurns]만큼 반대로 되돌려
  /// 정방향(위아래가 맞는 방향)으로 보이게 한다. 나머지 UI는 회전된 채로 둔다.
  static const _previewCounterQuarterTurns = (4 - _bodyQuarterTurns) % 4;

  int _photoCount = 0;
  FilmRollPlace? _place;

  /// 촬영 중인 필름롤의 지역. 상단 필름 타입 라벨에 쓰며, 조회 전/실패 시 null.
  RegionCode? _regionCode;

  /// 필름 한도 도달 여부. 카메라 초기화 상태와 별개로 유지해, 초기화가 한도 확인보다
  /// 늦게 끝나거나 resume으로 재시작돼도 필름 소진 안내가 덮어써지지 않게 한다.
  bool _isExposureLimitReached = false;

  List<double> get _availableZoomLevels => _zoomLevelCandidates
      .where((zoom) => zoom >= _minZoom && zoom <= _maxZoom)
      .toList();

  /// 전면 카메라는 플래시 유닛이 없어 토글을 노출하지 않는다.
  bool get _isFlashSupported => _lensDirection == CameraLensDirection.back;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 카메라 초기화(권한 다이얼로그 등 사용자 상호작용이 걸릴 수 있음)와 매수
    // 조회(로컬 DB)를 서로 기다리지 않고 동시에 시작한다 — 매수 조회를 먼저
    // 기다리게 하면 그 조회가 늦어지는 동안 카메라 자체가 뜨지 않는다.
    unawaited(_initializeCamera());
    unawaited(_loadPhotoCount());
    unawaited(_loadPlace());
    unawaited(_loadRegionCode());
  }

  Future<int> _fetchPhotoCount() {
    final override = widget.debugFetchPhotoCount;
    return override != null
        ? override()
        : FilmRollModule.instance.getFilmRollPhotoCount(widget.filmRollId);
  }

  /// 상단 필름 타입 라벨을 지역별로 보여주기 위해 필름롤의 지역을 조회한다.
  /// 실패해도 촬영 자체는 계속할 수 있어야 하므로 예외는 삼킨다(라벨만 생략).
  Future<void> _loadRegionCode() async {
    try {
      final override = widget.debugFetchRegionCode;
      final regionCode = override != null
          ? await override()
          : (await FilmRollModule.instance.filmRollRepository.findById(
              widget.filmRollId,
            ))?.regionCode;
      if (!mounted) return;
      setState(() => _regionCode = regionCode);
    } catch (e, st) {
      log('필름롤 지역 조회 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  /// 지금 인증 중인 장소 이름을 안내 문구로 보여주기 위해 조회한다. 실패해도
  /// 촬영 자체는 계속할 수 있어야 하므로 예외는 삼킨다(안내만 생략).
  Future<void> _loadPlace() async {
    try {
      final place = await FilmRollModule.instance.filmRollPlaceRepository
          .findById(widget.filmRollPlaceId);
      if (!mounted) return;
      setState(() => _place = place);
    } catch (e, st) {
      log('장소 정보 조회 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  /// 플래시 모드를 적용하되, 미지원 렌즈/기기에서 던지는 예외는 삼켜 카메라
  /// 초기화나 촬영 흐름이 중단되지 않게 한다.
  Future<void> _applyFlashModeSafely(CameraController controller) async {
    // 전면 카메라에도 off를 명시해야 한다. 컨트롤러 기본값(auto)을 그대로 두면
    // iOS 전면은 어두울 때 화면 플래시(Retina Flash)가 자동으로 켜진다.
    final mode = _isFlashSupported ? _flashMode : FlashMode.off;
    try {
      await controller.setFlashMode(mode);
    } catch (e, st) {
      log('플래시 모드 적용 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> _loadPhotoCount() async {
    try {
      final count = await _fetchPhotoCount();
      if (!mounted) return;
      setState(() => _photoCount = count);
      // 매수 조회가 카메라 초기화보다 늦게 끝날 수 있어(둘은 동시에 시작),
      // 이미 가득 찬 상태로 확인되면 그 사이 열렸을 수 있는 카메라를 정리하고
      // 안내로 전환한다 — 사용자가 쓸 수 없는 카메라를 계속 보게 두지 않는다.
      if (count >= FilmRoll.maxExposureCount) {
        await _disableCameraForExposureLimit();
      }
    } catch (e, st) {
      log('촬영 매수 조회 실패', name: _tag, error: e, stackTrace: st);
    }
  }

  Future<void> _disableCameraForExposureLimit() async {
    _isExposureLimitReached = true;
    final controller = _cameraController;
    if (mounted) {
      setState(() {
        _cameraController = null;
        _errorMessage = '필름을 다 썼어요. 더 이상 촬영할 수 없어요.';
      });
    }
    if (controller != null) {
      await controller.dispose();
    }
  }

  Future<void> _initializeCamera() async {
    // 권한 요청 다이얼로그가 뜨고 닫히는 과정 자체가 앱 라이프사이클을
    // inactive/resumed로 흔들어 didChangeAppLifecycleState에서 이 메서드를
    // 다시 호출할 수 있다. 이미 진행 중이면 무시해 카메라 컨트롤러가
    // 중복 생성되어 서로 충돌하는 것을 막는다.
    if (_isInitializingCamera || _isExposureLimitReached) return;
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

      // 권한 응답을 기다리는 사이 한도 도달이 확인됐다면 카메라를 만들지 않는다.
      if (_isExposureLimitReached) return;

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
      if (!mounted || _isExposureLimitReached) {
        await controller.dispose();
        return;
      }
      final clampedZoom = _zoomLevel.clamp(minZoom, maxZoom).toDouble();
      await controller.setZoomLevel(clampedZoom);
      await _applyFlashModeSafely(controller);
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

    final clampedZoom = zoom.clamp(_minZoom, _maxZoom).toDouble();
    await controller.setZoomLevel(clampedZoom);
    if (!mounted) return;
    setState(() => _zoomLevel = clampedZoom);
  }

  Future<void> _onFlashToggle() async {
    final controller = _cameraController;
    if (controller == null || !_isFlashSupported) return;

    final nextFlashMode = _flashMode == FlashMode.off
        ? FlashMode.always
        : FlashMode.off;
    try {
      await controller.setFlashMode(nextFlashMode);
    } catch (e, st) {
      // 일부 기기/렌즈는 플래시 모드 변경을 거부한다. 상태를 바꾸지 않고
      // 무시해 토글이 화면을 깨뜨리지 않도록 한다.
      log('플래시 모드 변경 실패', name: _tag, error: e, stackTrace: st);
      return;
    }
    if (!mounted) return;
    setState(() => _flashMode = nextFlashMode);
  }

  Future<void> _onCameraSwitch() async {
    if (_isInitializingCamera || _isSaving || _isSwitchingCamera) return;
    _isSwitchingCamera = true;

    try {
      final controller = _cameraController;
      if (controller != null) {
        setState(() => _cameraController = null);
        await controller.dispose();
      }
      _lensDirection = _lensDirection == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;
      // 전면은 플래시가 없으므로 상태를 꺼둔다(_initializeCamera가 이 값을 반영).
      if (_lensDirection == CameraLensDirection.front) {
        _flashMode = FlashMode.off;
      }
      await _initializeCamera();
    } finally {
      _isSwitchingCamera = false;
    }
  }

  Future<void> _onCaptureTap() async {
    final controller = _cameraController;
    if (controller == null || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      // 화면이 열려 있는 동안(예: 동기화)으로 필름이 가득 찼을 수 있으므로,
      // 셔터를 누르기 직전 매수를 다시 확인해 불필요한 촬영·파일 처리를
      // 막는다. savePhoto()도 같은 한도를 검사하지만, 그때는 이미 셔터가
      // 눌리고 파일까지 처리된 뒤라 늦다.
      final latestCount = await _fetchPhotoCount();
      if (!mounted) return;
      if (latestCount >= FilmRoll.maxExposureCount) {
        _isExposureLimitReached = true;
        setState(() {
          _errorMessage = '필름을 다 썼어요. 더 이상 촬영할 수 없어요.';
          _isSaving = false;
        });
        return;
      }

      // 촬영 직전 플래시 모드를 한 번 더 확정한다(이전 촬영 후 모드가 초기화되는
      // 기기 대비).
      await _applyFlashModeSafely(controller);
      final file = await controller.takePicture();
      // 카메라는 앱 방향(세로) 기준으로 저장하지만 이 화면은 UI를 돌려 그리므로,
      // 뷰파인더에서 본 방향과 같아지도록 사진도 그만큼 돌려 저장한다.
      final bytes = await orientCapturedPhotoInBackground(
        await file.readAsBytes(),
        uiQuarterTurns: _photoQuarterTurns,
      );
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
    } on FilmRollExposureLimitExceededException {
      _isExposureLimitReached = true;
      if (!mounted) return;
      setState(() {
        _errorMessage = '필름을 다 썼어요. 더 이상 촬영할 수 없어요.';
        _isSaving = false;
      });
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChaerokColors.background,
      body: Stack(
        children: [
          // 실제 화면(회전 전) 좌표계 기준 장식 패턴이므로 RotatedBox 바깥에 둔다.
          const Positioned.fill(child: CameraBottomPattern()),
          // 앱 인터페이스는 세로. 이 화면만 본문 전체를 회전시켜 가로로 보이게 한다.
          SafeArea(
            child: RotatedBox(
              key: const ValueKey('capture-body-rotator'),
              quarterTurns: _bodyQuarterTurns,
              child: _buildBody(),
            ),
          ),
        ],
      ),
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
            isFlashSupported: _isFlashSupported,
            filmTypeLabel: _regionCode?.filmTypeLabel ?? '',
            photoCount: _photoCount,
            maxPhotoCount: FilmRoll.maxExposureCount,
            onFlashToggle: _onFlashToggle,
            onClose: () => Navigator.of(context).maybePop(),
          ),
          if (_place != null) ...[
            const SizedBox(height: ChaerokSpacing.xs),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${_place!.name} 인증하기',
                style: ChaerokTypography.bodyMedium.copyWith(
                  color: ChaerokColors.textSecondary,
                ),
              ),
            ),
          ],
          // const SizedBox(height: ChaerokSpacing.lg),
          Expanded(
            // Row 대신 Stack을 써서, 뷰파인더 그룹의 정렬 기준이 옆(줌/셔터/전환
            // 버튼) 그룹의 폭에 영향받지 않고 이 영역 전체 크기를 기준으로 잡히게
            // 한다. Row였을 때는 Align(0, ...)의 x=0이 "전체 화면 중앙"이 아니라
            // "옆 그룹 폭을 뺀 나머지 영역의 중앙"이라 화면 전체 기준으로는 안
            // 맞았다.
            child: Stack(
              children: [
                Align(
                  // 본문이 90° 회전되므로(RotatedBox quarterTurns:1),
                  // 이 로컬 좌표계의 '위(top)' 방향이 화면 정방향 기준
                  // '오른쪽', '아래(bottom)' 방향이 정방향 기준 '왼쪽'이
                  // 된다. y를 음수로 줄수록 뷰파인더(+라벨)가 정방향
                  // 기준 오른쪽으로 이동한다. x=0이면 이 Stack(=Expanded
                  // 전체) 너비 기준 정중앙에 위치한다.
                  alignment: const Alignment(0, -2.4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Figma 원본 뷰파인더 크기(393x852 화면 기준
                      // 195x147)를 그대로 고정 크기로 사용한다.
                      SizedBox(
                        width: 212,
                        height: 160,
                        child: FilmViewfinderFrame(
                          // UI(베젤)는 본문과 함께 회전되지만, 그 안의
                          // 실제 카메라 프리뷰만은 반대로 되돌려
                          // 정방향으로 보이게 한다.
                          child: RotatedBox(
                            quarterTurns: _previewCounterQuarterTurns,
                            child: CameraPreview(controller),
                          ),
                        ),
                      ),
                      // 로컬 '아래' 방향 간격 = 정방향 기준 뷰파인더
                      // 왼쪽 라벨과의 간격(24px).
                      const SizedBox(height: 24),
                      Text(
                        _cameraName,
                        style: ChaerokTypography.titleMedium.copyWith(
                          color: ChaerokColors.sageDark,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _cameraSubtitle,
                        style: ChaerokTypography.caption.copyWith(
                          color: ChaerokColors.sageDark,
                        ),
                      ),
                    ],
                  ),
                ),
                Align(
                  // 로컬 '위(top)-오른쪽(right)'는 화면 정방향 기준
                  // '오른쪽-아래(bottom)'로 회전한다(90° 회전 매핑:
                  // final_x=-local_y, final_y=local_x). 세로 위치(아래)는
                  // 그대로 두고 좌우만 오른쪽으로 옮기려면 로컬 bottomRight
                  // 대신 topRight를 써야 한다.
                  alignment: Alignment.bottomCenter,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CameraZoomSelector(
                        availableZoomLevels: _availableZoomLevels,
                        selectedZoomLevel: _zoomLevel,
                        onZoomSelected: _onZoomSelected,
                      ),
                      const SizedBox(width: ChaerokSpacing.lg),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              CameraShutterButton(
                                onPressed: _onCaptureTap,
                                isLoading: _isSaving,
                              ),
                            ],
                          ),
                          const SizedBox(height: ChaerokSpacing.lg),
                          CameraSwitchButton(onPressed: _onCameraSwitch),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
