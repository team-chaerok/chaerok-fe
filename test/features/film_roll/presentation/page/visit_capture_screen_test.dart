import 'dart:async';

import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:chaerok/features/film_roll/presentation/page/visit_capture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

const _camera = CameraDescription(
  name: 'back',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

/// 실제 권한 다이얼로그처럼, [request]가 완료되기 전까지 대기하다가
/// [grant]가 호출되면 승인 상태를 반환하는 가짜 권한 플랫폼.
class _FakePermissionPlatform extends PermissionHandlerPlatform {
  final _completer = Completer<Map<Permission, PermissionStatus>>();

  void grant() {
    if (!_completer.isCompleted) {
      _completer.complete({Permission.camera: PermissionStatus.granted});
    }
  }

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return PermissionStatus.granted;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) {
    return _completer.future;
  }
}

/// 이미 영구 거부된 상태를 흉내내는 가짜 권한 플랫폼. 실기기에서 iOS/Android가
/// 그렇듯, checkPermissionStatus/requestPermissions 모두 다이얼로그 없이
/// 즉시 permanentlyDenied를 반환한다.
class _PermanentlyDeniedPermissionPlatform extends PermissionHandlerPlatform {
  int openAppSettingsCallCount = 0;

  @override
  Future<PermissionStatus> checkPermissionStatus(Permission permission) async {
    return PermissionStatus.permanentlyDenied;
  }

  @override
  Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    return {for (final p in permissions) p: PermissionStatus.permanentlyDenied};
  }

  @override
  Future<bool> openAppSettings() async {
    openAppSettingsCallCount++;
    return true;
  }
}

/// 카메라 컨트롤러 생성 횟수를 세는 가짜 카메라 플랫폼.
class _FakeCameraPlatform extends CameraPlatform {
  int createCameraCallCount = 0;
  int _nextCameraId = 0;

  @override
  Future<List<CameraDescription>> availableCameras() async => [_camera];

  @override
  Future<int> createCameraWithSettings(
    CameraDescription cameraDescription,
    MediaSettings mediaSettings,
  ) async {
    createCameraCallCount++;
    return _nextCameraId++;
  }

  @override
  Future<void> initializeCamera(
    int cameraId, {
    ImageFormatGroup imageFormatGroup = ImageFormatGroup.unknown,
  }) async {}

  @override
  Stream<CameraInitializedEvent> onCameraInitialized(int cameraId) {
    return Stream.value(
      const CameraInitializedEvent(
        0,
        1920,
        1080,
        ExposureMode.auto,
        false,
        FocusMode.auto,
        false,
      ),
    );
  }

  @override
  Stream<CameraResolutionChangedEvent> onCameraResolutionChanged(
    int cameraId,
  ) => const Stream.empty();

  @override
  Stream<CameraClosingEvent> onCameraClosing(int cameraId) =>
      const Stream.empty();

  @override
  Stream<CameraErrorEvent> onCameraError(int cameraId) =>
      // CameraController가 이 스트림에 `.first.then(...)`을 걸어두므로,
      // 완료되는 스트림(Stream.empty)을 쓰면 "Bad state: No element"가 던져진다.
      // 실제 에러 채널처럼 아무것도 발행하지 않고 끝나지 않는 스트림을 흉내낸다.
      StreamController<CameraErrorEvent>().stream;

  @override
  Stream<DeviceOrientationChangedEvent> onDeviceOrientationChanged() =>
      const Stream.empty();

  @override
  Widget buildPreview(int cameraId) => const SizedBox.shrink();

  @override
  Future<void> dispose(int cameraId) async {}

  @override
  Future<double> getMinZoomLevel(int cameraId) async => 1.0;

  @override
  Future<double> getMaxZoomLevel(int cameraId) async => 4.0;

  @override
  Future<void> setZoomLevel(int cameraId, double zoom) async {}

  @override
  Future<void> setFlashMode(int cameraId, FlashMode mode) async {}
}

void main() {
  testWidgets('권한 다이얼로그가 앱을 일시적으로 비활성화시켜도 카메라 컨트롤러는 한 번만 생성된다', (tester) async {
    final fakePermissions = _FakePermissionPlatform();
    final fakeCamera = _FakeCameraPlatform();
    PermissionHandlerPlatform.instance = fakePermissions;
    CameraPlatform.instance = fakeCamera;

    await tester.pumpWidget(
      const MaterialApp(
        home: VisitCaptureScreen(
          filmRollId: 'roll-1',
          filmRollPlaceId: 'place-1',
        ),
      ),
    );
    await tester.pump();

    // 시스템 권한 다이얼로그가 뜨면서 앱이 잠시 비활성화됐다가 돌아오는
    // 라이프사이클 변화를 흉내낸다. 이 시점에는 아직 권한 요청이 완료되지
    // 않아 _cameraController가 null인 상태다.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // 이제 사용자가 권한을 허용한다.
    fakePermissions.grant();
    await tester.pumpAndSettle();

    expect(
      fakeCamera.createCameraCallCount,
      1,
      reason: '권한 다이얼로그로 인한 라이프사이클 변화가 중복 카메라 초기화를 유발해서는 안 된다',
    );
  });

  testWidgets('카메라 권한이 영구 거부된 상태라면 다이얼로그 대신 설정 이동 버튼을 보여준다', (tester) async {
    final fakePermissions = _PermanentlyDeniedPermissionPlatform();
    PermissionHandlerPlatform.instance = fakePermissions;
    CameraPlatform.instance = _FakeCameraPlatform();

    await tester.pumpWidget(
      const MaterialApp(
        home: VisitCaptureScreen(
          filmRollId: 'roll-1',
          filmRollPlaceId: 'place-1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('설정에서 권한 허용하기'), findsOneWidget);

    await tester.tap(find.text('설정에서 권한 허용하기'));
    await tester.pumpAndSettle();

    expect(fakePermissions.openAppSettingsCallCount, 1);
  });
}
