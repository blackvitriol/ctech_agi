import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:sensors_plus/sensors_plus.dart';

class PermissionService {
  bool _hasCameraPermission = false;
  bool _hasMicrophonePermission = false;
  bool _hasSensorPermission = false;
  bool _permissionsChecked = false;

  // Getters
  bool get hasCameraPermission => _hasCameraPermission;
  bool get hasMicrophonePermission => _hasMicrophonePermission;
  bool get hasSensorPermission => _hasSensorPermission;
  bool get permissionsChecked => _permissionsChecked;

  // Check all permissions
  Future<void> checkPermissions() async {
    if (!kIsWeb) return;

    try {
      // Check camera permission
      final cameraStream =
          await navigator.mediaDevices.getUserMedia({'video': true});
      _hasCameraPermission = true;
      cameraStream.getTracks().forEach((track) => track.stop());

      // Check microphone permission
      final micStream =
          await navigator.mediaDevices.getUserMedia({'audio': true});
      _hasMicrophonePermission = true;
      micStream.getTracks().forEach((track) => track.stop());

      // Check sensor permission (if available)
      try {
        await accelerometerEvents.first;
        _hasSensorPermission = true;
      } catch (e) {
        _hasSensorPermission = false;
      }

      _permissionsChecked = true;
    } catch (e) {
      print('Error checking permissions: $e');
      _permissionsChecked = true;
    }
  }

  // Check if all required permissions are granted
  bool get allPermissionsGranted {
    return _hasCameraPermission && _hasMicrophonePermission;
  }

  // Request camera permission specifically
  Future<bool> requestCameraPermission() async {
    if (!kIsWeb) return false;

    try {
      final stream = await navigator.mediaDevices.getUserMedia({'video': true});
      _hasCameraPermission = true;
      stream.getTracks().forEach((track) => track.stop());
      return true;
    } catch (e) {
      print('Camera permission denied: $e');
      _hasCameraPermission = false;
      return false;
    }
  }

  // Request microphone permission specifically
  Future<bool> requestMicrophonePermission() async {
    if (!kIsWeb) return false;

    try {
      final stream = await navigator.mediaDevices.getUserMedia({'audio': true});
      _hasMicrophonePermission = true;
      stream.getTracks().forEach((track) => track.stop());
      return true;
    } catch (e) {
      print('Microphone permission denied: $e');
      _hasMicrophonePermission = false;
      return false;
    }
  }

  // Get permission status summary
  Map<String, bool> get permissionStatus {
    return {
      'camera': _hasCameraPermission,
      'microphone': _hasMicrophonePermission,
      'sensors': _hasSensorPermission,
    };
  }

  // Get permission status as text
  String getPermissionStatusText(String permission) {
    switch (permission.toLowerCase()) {
      case 'camera':
        return _hasCameraPermission ? 'Granted' : 'Denied';
      case 'microphone':
        return _hasMicrophonePermission ? 'Granted' : 'Denied';
      case 'sensors':
        return _hasSensorPermission ? 'Available' : 'Unavailable';
      default:
        return 'Unknown';
    }
  }

  // Reset permissions (useful for testing)
  void resetPermissions() {
    _hasCameraPermission = false;
    _hasMicrophonePermission = false;
    _hasSensorPermission = false;
    _permissionsChecked = false;
  }
}
