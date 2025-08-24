import 'package:get/get.dart';

class UserController extends GetxController {
  // Observable variables for user state
  final RxString serverUrl = ''.obs;
  final RxString roomId = ''.obs;
  final RxString userId = ''.obs;
  final RxInt connectionCount = 0.obs;
  final RxList<String> connectionLogs = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedSettings();
  }

  void _loadSavedSettings() {
    // Load saved settings from local storage if needed
    // For now, using default values
    serverUrl.value = 'localhost';
    roomId.value = 'ai_room';
    userId.value = 'user_${DateTime.now().millisecondsSinceEpoch}';

    print('UserController: Loaded default settings:');
    print('  Server URL: ${serverUrl.value}');
    print('  Room ID: ${roomId.value}');
    print('  User ID: ${userId.value}');
  }

  // Update connection settings
  void updateServerUrl(String url) {
    serverUrl.value = url;
  }

  void updateRoomId(String room) {
    roomId.value = room;
  }

  void updateUserId(String user) {
    userId.value = user;
  }

  // Add connection log entry
  void addConnectionLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    connectionLogs.add('[$timestamp] $message');

    // Keep only last 100 logs
    if (connectionLogs.length > 100) {
      connectionLogs.removeAt(0);
    }
  }

  // Update connection count
  void updateConnectionCount(int count) {
    connectionCount.value = count;
  }

  void clearLogs() {
    connectionLogs.clear();
  }
}
