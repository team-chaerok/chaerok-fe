import 'dart:developer';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// 위치 권한 요청/조회 및 현재 위치 확인을 담당하는 서비스.
class LocationPermissionService {
  const LocationPermissionService._();

  static const _tag = 'LocationPermissionService';

  /// 다이얼로그 없이 현재 위치 권한 상태를 조회합니다.
  static Future<PermissionStatus> checkStatus() {
    return Permission.locationWhenInUse.status;
  }

  /// Foreground(WhenInUse) 위치 권한을 요청합니다.
  /// 이미 승인·영구거부된 상태라면 OS가 다이얼로그 없이 현재 상태를 그대로 반환한다.
  static Future<PermissionStatus> requestPermission() async {
    log('위치 권한 요청', name: _tag);
    final status = await Permission.locationWhenInUse.request();
    log('위치 권한 상태: $status', name: _tag);
    return status;
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
      );
    } catch (e, st) {
      log('현재 위치 조회 실패', name: _tag, error: e, stackTrace: st);
      return null;
    }
  }

  /// 영구 거부 상태에서 사용자를 OS 앱 설정 화면으로 이동시킵니다.
  static Future<bool> openSettings() {
    return openAppSettings();
  }
}
