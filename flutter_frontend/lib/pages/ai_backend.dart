import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' as getx;

import '../services/device_info_service.dart';
import '../services/permission_service.dart';
import '../services/webrtc.dart';
import '../widgets/collapsible_section.dart';

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

  // Video stream variables
  MediaStream? _localVideoStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final List<RTCVideoRenderer> _aiStreamRenderers = List.generate(
    8, // 8 AI streams for 3x3 grid (1 user + 8 AI = 9 total)
    (index) => RTCVideoRenderer(),
  );

  // WebRTC connection status
  bool _isConnectedToServer = false;
  bool _isConnecting = false;

  // Connection settings and logs
  String _serverUrl = 'localhost';
  String _roomId = 'ai_room';
  String _userId = '';
  int _connectionCount = 0;
  final List<String> _connectionLogs = [];

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
    _webrtcService.dispose();
    _localRenderer.dispose();
    for (final renderer in _aiStreamRenderers) {
      renderer.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
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

      setState(() {
        _videoDevices = videoDevices;
        _isLoadingDevices = false;

        if (videoDevices.isNotEmpty && _selectedVideoDeviceId == null) {
          _selectedVideoDeviceId = videoDevices.first.deviceId;
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
      _localRenderer.srcObject = stream;
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
      _localRenderer.srcObject = null;
      setState(() {});
    }
  }

  void _toggleConnection() async {
    if (_isConnectedToServer) {
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
          _isConnectedToServer = true;
          _isConnecting = false;
        });
        _addSystemMessage('Connected to AI server successfully!');
        _addConnectionLog('Successfully connected to AI server');
        _connectionCount = 1;

        // Start local video when connected
        await _startLocalVideo();
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
      setState(() {
        _isConnectedToServer = false;
      });
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
          _localRenderer,
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
    return Container(
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
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
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
                              color: isUserStream ? Colors.blue : Colors.purple,
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
                              color: _isConnectedToServer
                                  ? Colors.green
                                  : Colors.grey,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isConnectedToServer ? 'Connected' : 'Disconnected',
                            style: TextStyle(
                              color: _isConnectedToServer
                                  ? Colors.green
                                  : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          if (_isConnectedToServer &&
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
                ElevatedButton.icon(
                  onPressed: _isConnecting ? null : _toggleConnection,
                  icon: _isConnecting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isConnectedToServer ? Icons.link_off : Icons.link),
                  label: Text(_isConnecting
                      ? 'Connecting...'
                      : _isConnectedToServer
                          ? 'Disconnect'
                          : 'Connect'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isConnectedToServer ? Colors.red : Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
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
                  CollapsibleSection(
                    title: 'Connection Settings',
                    icon: Icons.settings_ethernet,
                    headerColor: Colors.orange.shade50,
                    backgroundColor: Colors.orange.shade50.withOpacity(0.3),
                    initiallyExpanded: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _serverUrl,
                                decoration: const InputDecoration(
                                  labelText: 'Server URL',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _serverUrl = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                initialValue: _roomId,
                                decoration: const InputDecoration(
                                  labelText: 'Room ID',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _roomId = value;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                initialValue: _userId,
                                decoration: const InputDecoration(
                                  labelText: 'User ID',
                                  border: OutlineInputBorder(),
                                  hintText: 'Auto-generated if empty',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _userId = value;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Connection Count',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Text(
                                    '$_connectionCount',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Device Settings Section (moved after connection)
                  CollapsibleSection(
                    title: 'Device Settings',
                    icon: Icons.devices,
                    headerColor: Colors.green.shade50,
                    backgroundColor: Colors.green.shade50.withOpacity(0.3),
                    initiallyExpanded: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Video Device Selection',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoadingDevices)
                          const Center(child: CircularProgressIndicator())
                        else
                          DropdownButtonFormField<String>(
                            value: _selectedVideoDeviceId,
                            decoration: const InputDecoration(
                              labelText: 'Select Camera',
                              border: OutlineInputBorder(),
                            ),
                            items: _videoDevices.map((device) {
                              return DropdownMenuItem(
                                value: device.deviceId,
                                child: Text(device.label.isNotEmpty
                                    ? device.label
                                    : 'Camera ${_videoDevices.indexOf(device) + 1}'),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedVideoDeviceId = newValue;
                              });
                              if (_localVideoStream != null) {
                                _stopLocalVideo();
                                _startLocalVideo();
                              }
                            },
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _enumerateDevices,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh Devices'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement device testing
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Test Camera'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // AI Agent Models Section
                  CollapsibleSection(
                    title: 'AI Agent Models',
                    icon: Icons.psychology,
                    headerColor: Colors.purple.shade50,
                    backgroundColor: Colors.purple.shade50.withOpacity(0.3),
                    initiallyExpanded: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 180,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildAIModelCard(
                                'GPT-4 Vision',
                                'Advanced multimodal AI model for video analysis',
                                'Active',
                                Colors.green,
                                Icons.visibility,
                              ),
                              const SizedBox(width: 12),
                              _buildAIModelCard(
                                'Claude 3 Opus',
                                'High-performance reasoning and analysis',
                                'Active',
                                Colors.green,
                                Icons.psychology,
                              ),
                              const SizedBox(width: 12),
                              _buildAIModelCard(
                                'Gemini Pro',
                                'Google\'s multimodal AI for real-time processing',
                                'Standby',
                                Colors.orange,
                                Icons.auto_awesome,
                              ),
                              const SizedBox(width: 12),
                              _buildAIModelCard(
                                'Custom Vision Model',
                                'Specialized video processing neural network',
                                'Training',
                                Colors.blue,
                                Icons.tune,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Implement model management
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Model'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                // TODO: Implement model configuration
                              },
                              icon: const Icon(Icons.settings),
                              label: const Text('Configure'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Video Grid Section
                  CollapsibleSection(
                    title: 'Video Processing Grid',
                    icon: Icons.grid_view,
                    headerColor: Colors.blue.shade50,
                    backgroundColor: Colors.blue.shade50.withOpacity(0.3),
                    initiallyExpanded: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '3x3 Video Grid - User stream and AI processing streams',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Switch(
                              value: _localVideoStream != null,
                              onChanged: (value) {
                                if (value) {
                                  _startLocalVideo();
                                } else {
                                  _stopLocalVideo();
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Camera',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 400,
                          child: _buildVideoGrid(),
                        ),
                      ],
                    ),
                  ),

                  // Connection Logs Section
                  CollapsibleSection(
                    title: 'Connection Logs',
                    icon: Icons.info_outline,
                    headerColor: Colors.red.shade50,
                    backgroundColor: Colors.red.shade50.withOpacity(0.3),
                    initiallyExpanded: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Real-time connection and system messages',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _clearConnectionLogs,
                              child: const Text('Clear Logs'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 120,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: _connectionLogs.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No connection logs yet',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _connectionLogs.length,
                                  itemBuilder: (context, index) {
                                    final log = _connectionLogs[
                                        _connectionLogs.length - 1 - index];
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 2),
                                      child: Text(
                                        log,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontFamily: 'monospace'),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIModelCard(String name, String description, String status,
      Color statusColor, IconData icon) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: statusColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
