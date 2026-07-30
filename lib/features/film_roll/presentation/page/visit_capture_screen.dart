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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_initializeCamera());
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (!mounted) return;
      setState(() => _errorMessage = '카메라 권한이 필요해요.');
      return;
    }

    try {
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
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    final isInitialized = controller != null && controller.value.isInitialized;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (!isInitialized) return;
      setState(() => _cameraController = null);
      unawaited(controller.dispose());
    } else if (state == AppLifecycleState.resumed) {
      if (isInitialized) return;
      unawaited(_initializeCamera());
    }
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
          child: Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: ChaerokTypography.bodyMedium.copyWith(color: Colors.white),
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
