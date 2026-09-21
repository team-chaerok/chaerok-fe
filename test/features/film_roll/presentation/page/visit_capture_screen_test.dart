import 'dart:async';

import 'package:camera/camera.dart';
import 'package:camera_platform_interface/camera_platform_interface.dart';
import 'package:chaerok/features/film_roll/domain/entity/film_roll.dart';
import 'package:chaerok/features/film_roll/presentation/page/visit_capture_screen.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/camera_shutter_button.dart';
import 'package:chaerok/features/film_roll/presentation/widgets/camera_switch_button.dart';
import 'package:chaerok/shared/region/region_code.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler_platform_interface/permission_handler_platform_interface.dart';

const _backCamera = CameraDescription(
  name: 'back',
  lensDirection: CameraLensDirection.back,
  sensorOrientation: 90,
);

const _frontCamera = CameraDescription(
  name: 'front',
  lensDirection: CameraLensDirection.front,
  sensorOrientation: 270,
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

/// 카메라 컨트롤러 동작을 흉내내며 호출 인자를 기록하는 가짜 카메라 플랫폼.
class _FakeCameraPlatform extends CameraPlatform {
  _FakeCameraPlatform({this.includeFrontCamera = false});

  final bool includeFrontCamera;

  int createCameraCallCount = 0;
  int _nextCameraId = 0;

  final List<FlashMode> flashModeCalls = [];
  bool setFlashModeThrows = false;

  @override
  Future<List<CameraDescription>> availableCameras() async => [
    _backCamera,
    if (includeFrontCamera) _frontCamera,
  ];

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
  Future<void> setFlashMode(int cameraId, FlashMode mode) async {
    if (setFlashModeThrows) {
      throw CameraException('setFlashModeFailed', '이 렌즈는 플래시를 지원하지 않아요.');
    }
    flashModeCalls.add(mode);
  }
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

  testWidgets('본문은 RotatedBox로 회전돼 세로 폰에서도 가로 UI로 렌더된다', (tester) async {
    final fakePermissions = _FakePermissionPlatform();
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
    fakePermissions.grant();
    await tester.pumpAndSettle();

    final rotator = tester.widget<RotatedBox>(
      find.byKey(const ValueKey('capture-body-rotator')),
    );
    expect(rotator.quarterTurns, 1);
  });

  testWidgets('카메라 프리뷰는 본문 회전과 반대로 되돌려져 정방향으로 렌더된다', (tester) async {
    final fakePermissions = _FakePermissionPlatform();
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
    fakePermissions.grant();
    await tester.pumpAndSettle();

    final previewRotator = tester
        .widgetList<RotatedBox>(
          find.ancestor(
            of: find.byType(CameraPreview),
            matching: find.byType(RotatedBox),
          ),
        )
        .first;
    expect(
      previewRotator.quarterTurns,
      3,
      reason: '본문 회전(1)을 상쇄해 카메라 프리뷰만 정방향으로 보여야 한다',
    );
  });

  testWidgets('플래시 토글을 누르면 상단 바 상태가 ON으로 바뀌고 플래시 모드가 적용된다', (tester) async {
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
    fakePermissions.grant();
    await tester.pumpAndSettle();

    expect(find.text('OFF'), findsOneWidget);

    await tester.tap(find.text('OFF'));
    await tester.pumpAndSettle();

    expect(find.text('ON'), findsOneWidget);
    expect(fakeCamera.flashModeCalls, contains(FlashMode.always));
  });

  testWidgets('플래시 모드 변경이 실패하면 상태를 바꾸지 않고 무시한다', (tester) async {
    final fakePermissions = _FakePermissionPlatform();
    final fakeCamera = _FakeCameraPlatform()..setFlashModeThrows = true;
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
    fakePermissions.grant();
    await tester.pumpAndSettle();

    await tester.tap(find.text('OFF'));
    await tester.pumpAndSettle();

    expect(find.text('OFF'), findsOneWidget, reason: '실패 시 OFF 상태를 유지해야 한다');
    expect(tester.takeException(), isNull, reason: '예외가 화면 밖으로 전파되면 안 된다');
  });

  testWidgets('전면 카메라로 전환하면 플래시 토글을 노출하지 않는다', (tester) async {
    final fakePermissions = _FakePermissionPlatform();
    final fakeCamera = _FakeCameraPlatform(includeFrontCamera: true);
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
    fakePermissions.grant();
    await tester.pumpAndSettle();

    expect(find.text('OFF'), findsOneWidget);

    await tester.tap(find.byType(CameraSwitchButton));
    await tester.pumpAndSettle();

    expect(find.text('OFF'), findsNothing);
    expect(find.text('ON'), findsNothing);
  });

  testWidgets('촬영 매수가 이미 최대치면 카메라를 초기화하지 않고 필름 소진 안내를 보여준다', (tester) async {
    final fakePermissions = _FakePermissionPlatform();
    final fakeCamera = _FakeCameraPlatform();
    PermissionHandlerPlatform.instance = fakePermissions;
    CameraPlatform.instance = fakeCamera;

    await tester.pumpWidget(
      MaterialApp(
        home: VisitCaptureScreen(
          filmRollId: 'roll-1',
          filmRollPlaceId: 'place-1',
          debugFetchPhotoCount: () async => FilmRoll.maxExposureCount,
        ),
      ),
    );
    // 매수 조회가 먼저 끝난 뒤 권한이 승인되는 순서를 재현한다.
    await tester.pump();
    fakePermissions.grant();
    await tester.pumpAndSettle();

    expect(find.text('필름을 다 썼어요. 더 이상 촬영할 수 없어요.'), findsOneWidget);
    expect(
      fakeCamera.createCameraCallCount,
      0,
      reason: '이미 필름이 가득 찬 상태에서는 카메라를 초기화할 필요가 없다',
    );
  });

  testWidgets('카메라가 이미 열려 있어도 촬영 시점에 매수가 가득 찼으면 촬영하지 않고 안내로 전환한다', (
    tester,
  ) async {
    final fakePermissions = _FakePermissionPlatform();
    final fakeCamera = _FakeCameraPlatform();
    PermissionHandlerPlatform.instance = fakePermissions;
    CameraPlatform.instance = fakeCamera;

    var latestCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: VisitCaptureScreen(
          filmRollId: 'roll-1',
          filmRollPlaceId: 'place-1',
          debugFetchPhotoCount: () async => latestCount,
        ),
      ),
    );
    fakePermissions.grant();
    await tester.pumpAndSettle();

    // 화면이 열려 있는 동안 다른 경로(동기화 등)로 필름이 가득 찼다고 가정한다.
    latestCount = FilmRoll.maxExposureCount;

    await tester.tap(find.byType(CameraShutterButton));
    await tester.pumpAndSettle();

    expect(find.text('필름을 다 썼어요. 더 이상 촬영할 수 없어요.'), findsOneWidget);
  });

  for (final region in RegionCode.values) {
    testWidgets('상단 필름 타입 라벨에 ${region.displayName} 필름롤의 지역 라벨을 보여준다', (
      tester,
    ) async {
      final fakePermissions = _FakePermissionPlatform();
      PermissionHandlerPlatform.instance = fakePermissions;
      CameraPlatform.instance = _FakeCameraPlatform();

      await tester.pumpWidget(
        MaterialApp(
          home: VisitCaptureScreen(
            filmRollId: 'roll-1',
            filmRollPlaceId: 'place-1',
            debugFetchPhotoCount: () async => 0,
            debugFetchRegionCode: () async => region,
          ),
        ),
      );
      fakePermissions.grant();
      await tester.pumpAndSettle();

      expect(find.text(region.filmTypeLabel), findsOneWidget);
    });
  }
}
