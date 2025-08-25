import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' as getx;

import '../services/device_info_service.dart';
import '../services/permission_service.dart';
import '../services/webrtc.dart';
import 'video_fullscreen_page.dart';
import '../widgets/ai_backend/connection_settings_section.dart';
import '../widgets/ai_backend/device_settings_section.dart';
import '../widgets/ai_backend/ai_models_section.dart';
import '../widgets/ai_backend/video_grid_section.dart';
import '../widgets/ai_backend/connection_logs_section.dart';
import '../widgets/ai_backend/ai_services_section.dart';

class AIChatPage extends StatefulWidget {
  const AIChatPage({super.key});

  @override
  State<AIChatPage> createState() => _AIChatPageState();
}

class _AIChatPageState extends State<AIChatPage>
    with AutomaticKeepAliveClientMixin {
  late WebRTCService _webrtcService;
  late PermissionService _permissionService;
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  // Webcam selection variables
  List<MediaDeviceInfo> _videoDevices = [];
  String? _selectedVideoDeviceId;
  bool _isLoadingDevices = false;

  // Audio devices
  List<MediaDeviceInfo> _audioInputDevices = [];
  List<MediaDeviceInfo> _audioOutputDevices = [];
  String? _selectedAudioInputId;
  String? _selectedAudioOutputId;

  // Video stream variables
  MediaStream? _localVideoStream;
  final List<RTCVideoRenderer> _aiStreamRenderers = List.generate(
    8, // 8 AI streams for 3x3 grid (1 user + 8 AI = 9 total)
    (index) => RTCVideoRenderer(),
  );

  // WebRTC connection status
  bool _isConnecting = false;

  // Connection settings and logs
  String _serverUrl = 'localhost';
  String _roomId = 'ai_room';
  String _userId = '';
  int _connectionCount = 0;
  final List<String> _connectionLogs = [];
  // AI services selections
  final Map<String, Map<String, bool>> _aiServices = {
    'vision': {
      'object_detection': false,
      'image_classification': false,
      'image_segmentation': false,
      'interactive_segmentation': false,
      'hand_landmark_detection': false,
      'gesture_recognition': false,
      'image_embedding': false,
      'face_detection': false,
      'face_landmark_detection': false,
      'face_stylization': false,
      'pose_landmark_detection': false,
      'image_generation': false,
    },
    'nlp': {
      'text_classification': false,
      'text_embedding': false,
      'language_detector': false,
    },
    'audio': {
      'audio_classification': false,
    }
  };
  Map<String, dynamic> get _aiServicesJson => _aiServices;

  @override
  void initState() {
    super.initState();
    _webrtcService = WebRTCService();
    _permissionService = PermissionService();
    _setupWebSocketErrorHandling();
    // Capture server info when connected
    _webrtcService.webSocketService.onServerInfo = (serverName) {
      setState(() {
        // trigger rebuild to show server name
      });
    };
    _initializeRenderers();
    _initializeApp();
  }

  @override
  void dispose() {
    for (final renderer in _aiStreamRenderers) {
      renderer.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeRenderers() async {
    for (final renderer in _aiStreamRenderers) {
      await renderer.initialize();
    }
  }

  void _setupWebSocketErrorHandling() {
    _webrtcService.webSocketService.onError = (errorMessage) {
      getx.Get.snackbar(
        'Connection Error',
        errorMessage,
        snackPosition: getx.SnackPosition.TOP,
        backgroundColor: getx.Get.theme.colorScheme.error,
        colorText: getx.Get.theme.colorScheme.onError,
        duration: const Duration(seconds: 5),
        margin: const EdgeInsets.all(16),
        borderRadius: 8,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    };
  }

  Future<void> _initializeApp() async {
    try {
      await _webrtcService.initializeRenderers();
      await _permissionService.checkPermissions();
      await _enumerateDevices();
      await _deviceInfoService.loadDeviceAndSensorInfo();
      if (mounted) {
        setState(() {});
      }

      if (_permissionService.permissionsChecked &&
          !_permissionService.allPermissionsGranted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showPermissionDialog();
          }
        });
      }
    } catch (e) {
      print('Error during app initialization: $e');
      if (mounted) {
        _addSystemMessage('Initialization error: $e');
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permissions Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('This app needs the following permissions:'),
              const SizedBox(height: 16),
              _buildPermissionItem(
                  'Camera', _permissionService.hasCameraPermission),
              _buildPermissionItem(
                  'Microphone', _permissionService.hasMicrophonePermission),
              _buildPermissionItem(
                  'Sensors', _permissionService.hasSensorPermission),
              const SizedBox(height: 16),
              const Text(
                  'Please grant these permissions in your browser settings and refresh the page.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await _permissionService.requestCameraPermission();
                await _permissionService.checkPermissions();
                if (mounted) setState(() {});
              },
              child: const Text('Allow Camera'),
            ),
            TextButton(
              onPressed: () async {
                await _permissionService.requestMicrophonePermission();
                await _permissionService.checkPermissions();
                if (mounted) setState(() {});
              },
              child: const Text('Allow Microphone'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _permissionService.checkPermissions();
                if (!_permissionService.allPermissionsGranted) {
                  _showPermissionDialog();
                }
              },
              child: const Text('Check Again'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionItem(String permission, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.error,
            color: granted ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text('$permission: ${granted ? "Granted" : "Required"}'),
        ],
      ),
    );
  }

  Future<void> _enumerateDevices() async {
    setState(() {
      _isLoadingDevices = true;
    });

    try {
      final devices = await navigator.mediaDevices.enumerateDevices();
      final videoDevices =
          devices.where((device) => device.kind == 'videoinput').toList();
      final audioInputs =
          devices.where((device) => device.kind == 'audioinput').toList();
      final audioOutputs =
          devices.where((device) => device.kind == 'audiooutput').toList();

      setState(() {
        _videoDevices = videoDevices;
        _audioInputDevices = audioInputs;
        _audioOutputDevices = audioOutputs;
        _isLoadingDevices = false;

        if (videoDevices.isNotEmpty && _selectedVideoDeviceId == null) {
          _selectedVideoDeviceId = videoDevices.first.deviceId;
        }
        if (audioInputs.isNotEmpty && _selectedAudioInputId == null) {
          _selectedAudioInputId = audioInputs.first.deviceId;
        }
        if (audioOutputs.isNotEmpty && _selectedAudioOutputId == null) {
          _selectedAudioOutputId = audioOutputs.first.deviceId;
        }
      });
    } catch (e) {
      print('Error enumerating devices: $e');
      setState(() {
        _isLoadingDevices = false;
      });
    }
  }

  Future<void> _startLocalVideo() async {
    if (_selectedVideoDeviceId == null) {
      print('No video device selected');
      return;
    }

    try {
      final constraints = {
        'audio': false,
        'video': {
          'deviceId': _selectedVideoDeviceId,
          'width': {'ideal': 640},
          'height': {'ideal': 480},
        }
      };

      final stream = await navigator.mediaDevices.getUserMedia(constraints);
      _localVideoStream = stream;
      _webrtcService.localRenderer.srcObject = stream;
      setState(() {});
    } catch (e) {
      print('Error starting local video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accessing camera: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopLocalVideo() async {
    if (_localVideoStream != null) {
      _localVideoStream!.getTracks().forEach((track) => track.stop());
      _localVideoStream = null;
      _webrtcService.localRenderer.srcObject = null;
      setState(() {});
    }
  }

  Future<void> _setAudioOutput(String? deviceId) async {
    if (deviceId == null) return;
    try {
      await _webrtcService.localRenderer.audioOutput(deviceId);
      setState(() {
        _selectedAudioOutputId = deviceId;
      });
    } catch (e) {
      // ignore errors on unsupported platforms
    }
  }

  void _toggleConnection() async {
    if (_webrtcService.webSocketService.isConnected) {
      await _disconnectFromServer();
    } else {
      await _connectToServer();
    }
  }

  Future<void> _connectToServer() async {
    setState(() {
      _isConnecting = true;
    });

    if (_userId.isEmpty) {
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    }

    try {
      final success = await _webrtcService.connectToSignalingServer(
        _serverUrl,
        _roomId,
        _userId,
      );

      if (success) {
        setState(() {
          _isConnecting = false;
        });
        _addSystemMessage('Connected to AI server successfully!');
        _addConnectionLog('Successfully connected to AI server');
        _connectionCount = 1;

        // Start local video when connected
        await _startLocalVideo();

        // Send selected AI services over DataChannel when available
        try {
          await _webrtcService.createOffer(); // ensure pc has datachannel
        } catch (_) {}
        final dc = _webrtcService.dataChannel;
        if (dc != null && dc.state.toString().contains('open')) {
          final payload = {
            'type': 'ai_services',
            'data': _aiServicesJson,
            'timestamp': DateTime.now().toIso8601String(),
          };
          dc.send(RTCDataChannelMessage(payload.toString()));
        }
      } else {
        setState(() {
          _isConnecting = false;
        });
        _addSystemMessage('Failed to connect to AI server');
        _addConnectionLog('Failed to connect to AI server');
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
      });
      _addSystemMessage('Connection error: $e');
    }
  }

  Future<void> _disconnectFromServer() async {
    try {
      await _webrtcService.disconnectFromSignalingServer();
      await _stopLocalVideo();
      _addSystemMessage('Disconnected from AI server');
    } catch (e) {
      _addSystemMessage('Disconnection error: $e');
    }
  }

  void _addSystemMessage(String text) {
    setState(() {
      _connectionLogs
          .add('[${DateTime.now().toString().substring(11, 19)}] $text');
      if (_connectionLogs.length > 100) {
        _connectionLogs.removeAt(0);
      }
    });
  }

  void _addConnectionLog(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    setState(() {
      _connectionLogs.add('[$timestamp] $message');
      if (_connectionLogs.length > 100) {
        _connectionLogs.removeAt(0);
      }
    });
  }

  void _clearConnectionLogs() {
    setState(() {
      _connectionLogs.clear();
    });
  }

  Widget _buildVideoGrid() {
    return GridView.count(
      crossAxisCount: 3,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        // User video stream (top-left)
        _buildVideoTile(
          'User Stream',
          _webrtcService.localRenderer,
          _localVideoStream != null,
          isUserStream: true,
        ),
        // AI processed streams (remaining 8 positions)
        ...List.generate(
            8,
            (index) => _buildVideoTile(
                  'AI Stream ${index + 1}',
                  _aiStreamRenderers[index],
                  false, // AI streams are not active yet
                  isUserStream: false,
                )),
      ],
    );
  }

  Widget _buildVideoTile(String title, RTCVideoRenderer renderer, bool isActive,
      {required bool isUserStream}) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VideoFullscreenPage(
              title: title,
              renderer: isUserStream ? _webrtcService.localRenderer : renderer,
              isActive: isActive,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUserStream ? Colors.blue : Colors.purple,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            // Video content
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: isActive
                  ? RTCVideoView(
                      renderer,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : Container(
                      color: Colors.black54,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isUserStream ? Icons.person : Icons.psychology,
                              size: 32,
                              color: isUserStream ? Colors.blue : Colors.purple,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isUserStream ? 'No Camera' : 'AI Processing',
                              style: TextStyle(
                                color:
                                    isUserStream ? Colors.blue : Colors.purple,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            // Title overlay
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            // Status indicator
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for AutomaticKeepAliveClientMixin
    return Scaffold(
      body: Column(
        children: [
          // Header with connection controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Connection status and controls
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Mind - Video Processing',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _webrtcService.webSocketService.isConnected
                                  ? Colors.green
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _webrtcService.webSocketService.isConnected
                                ? 'Connected'
                                : 'Disconnected',
                            style: TextStyle(
                              color: _webrtcService.webSocketService.isConnected
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (_webrtcService.webSocketService.isConnected &&
                              _webrtcService.webSocketService.serverName !=
                                  null)
                            Row(
                              children: [
                                const Icon(Icons.dns,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  _webrtcService.webSocketService.serverName!,
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Connection button
                const SizedBox.shrink(),
              ],
            ),
          ),

          // Main content with collapsible sections
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Connection Settings Section (moved first)
                  ConnectionSettingsSection(
                    serverUrl: _serverUrl,
                    roomId: _roomId,
                    userId: _userId,
                    connectionCount: _connectionCount,
                    onServerUrlChanged: (value) =>
                        setState(() => _serverUrl = value),
                    onRoomIdChanged: (value) => setState(() => _roomId = value),
                    onUserIdChanged: (value) => setState(() => _userId = value),
                  ),

                  // Device Settings Section (moved after connection)
                  DeviceSettingsSection(
                    isLoadingDevices: _isLoadingDevices,
                    videoDevices: _videoDevices,
                    audioInputDevices: _audioInputDevices,
                    audioOutputDevices: _audioOutputDevices,
                    selectedVideoDeviceId: _selectedVideoDeviceId,
                    selectedAudioInputId: _selectedAudioInputId,
                    selectedAudioOutputId: _selectedAudioOutputId,
                    onRefreshDevices: _enumerateDevices,
                    onVideoChanged: (String? newValue) {
                      setState(() {
                        _selectedVideoDeviceId = newValue;
                      });
                      if (_localVideoStream != null) {
                        _stopLocalVideo();
                        _startLocalVideo();
                      }
                    },
                    onAudioInputChanged: (String? newValue) {
                      setState(() {
                        _selectedAudioInputId = newValue;
                      });
                    },
                    onAudioOutputChanged: (String? newValue) {
                      _setAudioOutput(newValue);
                    },
                    deviceInfo: _deviceInfoService.deviceInfo,
                    sensors: _deviceInfoService.availableSensors,
                  ),

                  // AI Agent Models Section
                  AIModelsSection(
                    onAddModel: () {
                      // TODO: Implement model management
                    },
                    onConfigure: () {
                      // TODO: Implement model configuration
                    },
                  ),

                  // AI Services Section
                  AIServicesSection(
                    selections: _aiServices,
                    onChanged: (category, key, value) {
                      setState(() {
                        _aiServices[category]?[key] = value;
                      });
                    },
                  ),

                  // Video Grid Section
                  VideoGridSection(
                    cameraOn: _localVideoStream != null,
                    onToggleCamera: (value) {
                      if (value) {
                        _startLocalVideo();
                      } else {
                        _stopLocalVideo();
                      }
                    },
                    grid: _buildVideoGrid(),
                  ),

                  // Connection Logs Section
                  ConnectionLogsSection(
                    logs: _connectionLogs,
                    onClear: _clearConnectionLogs,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isConnecting ? null : _toggleConnection,
        icon: _isConnecting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(_webrtcService.webSocketService.isConnected
                ? Icons.link_off
                : Icons.link),
        label: Text(
          _isConnecting
              ? 'Connecting...'
              : _webrtcService.webSocketService.isConnected
                  ? 'Disconnect'
                  : 'Connect',
        ),
        backgroundColor: _webrtcService.webSocketService.isConnected
            ? Colors.red
            : Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
