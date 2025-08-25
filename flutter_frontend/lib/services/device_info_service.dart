import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';

class DeviceInfoService {
  List<String> _availableSensors = [];
  Map<String, dynamic> _deviceInfo = {};
  Map<String, dynamic> _packageInfo = {};
  bool _isLoadingInfo = false;

  // Getters
  List<String> get availableSensors => _availableSensors;
  Map<String, dynamic> get deviceInfo => _deviceInfo;
  Map<String, dynamic> get packageInfo => _packageInfo;
  bool get isLoadingInfo => _isLoadingInfo;

  // Load all device and sensor information
  Future<void> loadDeviceAndSensorInfo() async {
    _isLoadingInfo = true;

    try {
      // Get package info
      final packageInfo = await PackageInfo.fromPlatform();
      _packageInfo = {
        'appName': packageInfo.appName,
        'packageName': packageInfo.packageName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      };

      // Get device info
      final deviceInfo = DeviceInfoPlugin();
      if (kIsWeb) {
        final webInfo = await deviceInfo.webBrowserInfo;
        _deviceInfo = {
          'platform': 'Web',
          'browserName': webInfo.browserName.name,
          'userAgent': webInfo.userAgent,
          'appVersion': webInfo.appVersion,
          'appName': webInfo.appName,
          'platformName': webInfo.platform,
          'vendor': webInfo.vendor,
          'language': webInfo.language,
          'product': webInfo.product,
          'productSub': webInfo.productSub,
          'vendorSub': webInfo.vendorSub,
          'hardwareConcurrency': webInfo.hardwareConcurrency,
          'maxTouchPoints': webInfo.maxTouchPoints,
          'deviceMemoryGB': webInfo.deviceMemory,
        };
      }

      // Check available sensors
      await _checkAvailableSensors();
    } catch (e) {
      print('Error loading device info: $e');
    } finally {
      _isLoadingInfo = false;
    }
  }

  // Check which sensors are available
  Future<void> _checkAvailableSensors() async {
    _availableSensors = [];

    // Check accelerometer
    try {
      await accelerometerEvents.first;
      _availableSensors.add('Accelerometer');
    } catch (e) {
      // Sensor not available
    }

    // Check gyroscope
    try {
      await gyroscopeEvents.first;
      _availableSensors.add('Gyroscope');
    } catch (e) {
      // Sensor not available
    }

    // Check magnetometer
    try {
      await magnetometerEvents.first;
      _availableSensors.add('Magnetometer');
    } catch (e) {
      // Sensor not available
    }

    // Check user accelerometer
    try {
      await userAccelerometerEvents.first;
      _availableSensors.add('User Accelerometer');
    } catch (e) {
      // Sensor not available
    }
  }

  // Reset all data
  void reset() {
    _availableSensors = [];
    _deviceInfo = {};
    _packageInfo = {};
    _isLoadingInfo = false;
  }
}
