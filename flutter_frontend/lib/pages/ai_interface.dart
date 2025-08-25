import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../services/device_info_service.dart';
import '../services/permission_service.dart';
import '../services/webrtc.dart';

class AIInterfacePage extends StatefulWidget {
  const AIInterfacePage({super.key});

  @override
  State<AIInterfacePage> createState() => _AIInterfacePageState();
}

class _AIInterfacePageState extends State<AIInterfacePage>
    with AutomaticKeepAliveClientMixin {
  late WebRTCService _webrtcService;
  late PermissionService _permissionService;
  final DeviceInfoService _deviceInfoService = DeviceInfoService();

  // Webcam selection variables
  String? _selectedVideoDeviceId;
  // Chat variables
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _isLoadingDevices = false;
  List<MediaDeviceInfo> _videoDevices = [];

  // Connection is managed in AI Backend page

  @override
  void initState() {
    super.initState();
    _webrtcService = WebRTCService();
    _permissionService = PermissionService();
    _initializeApp();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // No WebSocket wiring here; connection is handled in AI Backend page

  Future<void> _initializeApp() async {
    try {
      await _webrtcService.initializeRenderers();
      await _permissionService.checkPermissions();
      await _enumerateDevices();
      await _deviceInfoService.loadDeviceAndSensorInfo();

      // Only show permission dialog if permissions are actually missing
      if (_permissionService.permissionsChecked &&
          !_permissionService.allPermissionsGranted) {
        // Delay the dialog to ensure the UI is fully rendered
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showPermissionDialog();
          }
        });
      }
    } catch (e) {
      print('Error during app initialization: $e');
      // Show error message but don't block the UI
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

        // Auto-select first camera if available
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

  Future<void> _getUserMedia() async {
    if (_selectedVideoDeviceId == null) {
      print('No video device selected');
      return;
    }

    try {
      await _webrtcService.getUserMedia(_selectedVideoDeviceId);
      setState(() {});
    } catch (e) {
      print('Error getting user media: $e');
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

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final text = _textController.text.trim();

    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = false;
    });

    _textController.clear();

    final ok = await _webrtcService.sendChatMessage(text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send. DataChannel not open.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // No connection controls in this page

  // No connect/disconnect handlers here

  // No disconnect here

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        text: text,
        isUser: false,
        timestamp: DateTime.now(),
        isSystem: true,
      ));
    });
  }

  // No connection logs on this page

  // No connection logs on this page

  // Test if server is reachable via HTTP
  // No server test here

  // No connection settings dialog on this page

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Debug: Print current connection state
    // Connection managed in AI Backend page

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Note about connection management location
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Connection is managed in the AI Backend page. Use this page for UI/interaction only.',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),

            // Chat Window Section
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.4,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Chat Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        border: Border(
                          bottom: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              color: Colors.blue),
                          const SizedBox(width: 8),
                          const Text(
                            'AI Communication',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_messages.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _messages.clear();
                                });
                              },
                              child: const Text('Clear'),
                            ),
                        ],
                      ),
                    ),

                    // Messages Area
                    Expanded(
                      child: _messages.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No messages yet',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Connect to AI server to start communication',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade400,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _messages.length + (_isTyping ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _messages.length && _isTyping) {
                                  return const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                        SizedBox(width: 8),
                                        Text('AI is thinking...'),
                                      ],
                                    ),
                                  );
                                }

                                final message = _messages[index];
                                return MessageBubble(message: message);
                              },
                            ),
                    ),

                    // Text Input Area
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                        border: Border(
                          top: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              decoration: const InputDecoration(
                                hintText: 'Type your message to AI...',
                                border: OutlineInputBorder(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(24)),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: _sendMessage,
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(16),
                            ),
                            child: const Icon(Icons.send),
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
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isSystem;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isSystem = false,
  });
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    // System messages are centered and styled differently
    if (message.isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Regular user/AI messages
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: message.isUser ? Colors.blue : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
