import 'dart:developer';
import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// 위치 권한 요청/조회 및 현재 위치 확인을 담당하는 서비스.
class LocationPermissionService {
  const LocationPermissionService._();

  static const _tag = 'LocationPermissionService';
  static const _positionTimeLimit = Duration(seconds: 30);

  /// 다이얼로그 없이 현재 위치 권한 상태를 조회합니다.
  /// macOS는 permission_handler 구현체가 없어 Geolocator의 자체 권한 API로 대체한다.
  static Future<PermissionStatus> checkStatus() {
    if (Platform.isMacOS) {
      return Geolocator.checkPermission().then(_toPermissionStatus);
    }
    return Permission.locationWhenInUse.status;
  }

  /// Foreground(WhenInUse) 위치 권한을 요청합니다.
  /// 이미 승인·영구거부된 상태라면 OS가 다이얼로그 없이 현재 상태를 그대로 반환한다.
  static Future<PermissionStatus> requestPermission() async {
    log('위치 권한 요청', name: _tag);
    final status = Platform.isMacOS
        ? _toPermissionStatus(await Geolocator.requestPermission())
        : await Permission.locationWhenInUse.request();
    log('위치 권한 상태: $status', name: _tag);
    return status;
  }

  static PermissionStatus _toPermissionStatus(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return PermissionStatus.granted;
      case LocationPermission.deniedForever:
        return PermissionStatus.permanentlyDenied;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return PermissionStatus.denied;
    }
  }

  /// 기기의 위치 서비스(OS GPS 설정) 활성화 여부를 확인합니다.
  static Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  /// 현재 위치 좌표를 조회합니다. 권한이 없으면 null을 반환합니다.
  static Future<Position?> getCurrentPosition() async {
    final status = await checkStatus();
    if (!status.isGranted) {
      log('위치 권한 없음 - 좌표 조회 불가', name: _tag);
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _buildLocationSettings(),
      );
    } catch (e, st) {
      log('현재 위치 조회 실패 또는 시간 초과', name: _tag, error: e, stackTrace: st);
      return null;
    }
  }

  /// 위치 조회 설정을 생성합니다.
  /// Android는 FusedLocationProviderClient(Play Services) 대신 LocationManager를
  /// 강제 사용한다. 에뮬레이터의 Extended Controls로 주입한 mock 위치는
  /// FusedLocationProviderClient로 갱신되지 않아 getCurrentPosition이
  /// timeLimit까지 응답 없이 타임아웃되는 문제가 있었다.
  static LocationSettings _buildLocationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: _positionTimeLimit,
        forceLocationManager: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.medium,
      timeLimit: _positionTimeLimit,
    );
  }

  /// 영구 거부 상태에서 사용자를 OS 앱 설정 화면으로 이동시킵니다.
  static Future<bool> openSettings() {
    return openAppSettings();
  }
}
