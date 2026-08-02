import 'dart:async';
import 'dart:developer';

import 'package:camera/camera.dart';
import 'package:chaerok/core/design_system/chaerok_spacing.dart';
import 'package:chaerok/core/design_system/chaerok_typography.dart';
import 'package:chaerok/features/film_roll/film_roll_module.dart';
import 'package:chaerok/features/location/data/location_permission_service.dart';
import 'package:chaerok/shared/widgets/chaerok_button.dart';
import 'package:chaerok/shared/widgets/chaerok_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// 방문 인증 사진을 촬영하는 화면. 촬영에 성공해 저장까지 마치면
/// `Navigator.pop(true)`로 닫히며, 호출부(FilmRollScreen)가 방문 인증을 이어서 기록한다.
class VisitCaptureScreen extends StatefulWidget {
  const VisitCaptureScreen({
    super.key,
    required this.filmRollId,
    required this.filmRollPlaceId,
    required this.placeName,
  });

  final String filmRollId;
  final String filmRollPlaceId;
  final String placeName;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
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

      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _cameraController = controller;
        _errorMessage = null;
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          widget.placeName,
          style: ChaerokTypography.titleMedium.copyWith(color: Colors.white),
        ),
      ),
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
                  color: Colors.white,
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
      return const Center(child: ChaerokLoadingIndicator(color: Colors.white));
    }

    return Column(
      children: [
        Expanded(child: CameraPreview(controller)),
        Padding(
          padding: const EdgeInsets.all(ChaerokSpacing.lg),
          child: ChaerokButton(
            text: '촬영하기',
            isLoading: _isSaving,
            onPressed: _onCaptureTap,
          ),
        ),
      ],
    );
  }
}
