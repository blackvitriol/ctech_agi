import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'websocket_service.dart';

class WebRTCService {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final WebSocketService _webSocketService = WebSocketService();

  // UserController removed - using simplified state management

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  bool _isInitialized = false;
  String? _currentRoomId;
  String? _currentUserId;

  // Getters
  RTCVideoRenderer get localRenderer => _localRenderer;
  RTCVideoRenderer get remoteRenderer => _remoteRenderer;
  MediaStream? get localStream => _localStream;
  RTCPeerConnection? get peerConnection => _peerConnection;
  bool get isInitialized => _isInitialized;
  bool get isConnected => _webSocketService.isConnected;
  String? get currentRoomId => _currentRoomId;
  String? get currentUserId => _currentUserId;
  WebSocketService get webSocketService => _webSocketService;

  // Initialize renderers and WebSocket callbacks
  Future<void> initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _isInitialized = true;

    // UserController disabled - using simplified state management
    print('WebRTC service initialized without state management');

    // Set up WebSocket callbacks
    _setupWebSocketCallbacks();
  }

  // UserController connection disabled
  void connectToUserController() {
    // No-op - UserController functionality removed
  }

  // Set up WebSocket callbacks for WebRTC signaling
  void _setupWebSocketCallbacks() {
    _webSocketService.onOffer = (data) => _handleOffer(data);
    _webSocketService.onAnswer = (data) => _handleAnswer(data);
    _webSocketService.onIceCandidate = (data) => _handleIceCandidate(data);
    _webSocketService.onUserJoined = (userId) => _handleUserJoined(userId);
    _webSocketService.onUserLeft = (userId) => _handleUserLeft(userId);
    _webSocketService.onUserDisconnected =
        (userId) => _handleUserDisconnected(userId);
    _webSocketService.onConnected = () => _handleConnected();
    _webSocketService.onDisconnected = () => _handleDisconnected();
    _webSocketService.onError =
        (errorMessage) => _handleWebSocketError(errorMessage);
  }

  // Connect to signaling server - delegate to WebSocketService
  Future<bool> connectToSignalingServer(
      String serverUrl, String roomId, String userId) async {
    _currentRoomId = roomId;
    _currentUserId = userId;

    // Try to connect to UserController if not already connected
    connectToUserController();

    try {
      print(
          'Attempting to connect to signaling server: $serverUrl, room: $roomId, user: $userId');

      final success =
          await _webSocketService.connectToSignalingServer(serverUrl, roomId);
      if (success) {
        print('Connected to signaling server in room: $roomId');
        return true;
      } else {
        print('Failed to connect to signaling server in room: $roomId');
        _handleWebSocketError('Failed to connect to signaling server');
        return false;
      }
    } catch (e) {
      print('Error connecting to signaling server: $e');
      _handleWebSocketError('Connection error: $e');
      return false;
    }
  }

  // Disconnect from signaling server - delegate to WebSocketService
  Future<void> disconnectFromSignalingServer() async {
    try {
      print('Disconnecting from signaling server');
      await _webSocketService.disconnectFromSignalingServer();
      _currentRoomId = null;
      _currentUserId = null;
      print('Disconnected from signaling server');
    } catch (e) {
      print('Error during disconnect: $e');
    }
  }

  // Handle WebRTC offer from remote peer
  Future<void> _handleOffer(Map<String, dynamic> data) async {
    if (data['from'] == _currentUserId) return; // Ignore our own offer

    print('Received offer from: ${data['from']}');

    if (_peerConnection == null) {
      await _setupPeerConnection();
    }

    try {
      final offer = RTCSessionDescription(data['sdp'], 'offer');
      await _peerConnection!.setRemoteDescription(offer);

      // Create and send answer
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);

      await _webSocketService.sendAnswer(
          answer.sdp!, data['from'] ?? 'unknown');
      print('Sent answer to: ${data['from']}');
    } catch (e) {
      print('Error handling offer: $e');
    }
  }

  // Handle WebRTC answer from remote peer
  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    if (data['from'] == _currentUserId) return; // Ignore our own answer

    print('Received answer from: ${data['from']}');

    try {
      final answer = RTCSessionDescription(data['sdp'], 'answer');
      await _peerConnection!.setRemoteDescription(answer);
    } catch (e) {
      print('Error handling answer: $e');
    }
  }

  // Handle ICE candidate from remote peer
  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    if (data['from'] == _currentUserId) return; // Ignore our own candidate

    print('Received ICE candidate from: ${data['from']}');

    try {
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    } catch (e) {
      print('Error handling ICE candidate: $e');
    }
  }

  // Handle user joined event
  void _handleUserJoined(String userId) {
    print('User joined: $userId');
  }

  // Handle user left event
  void _handleUserLeft(String userId) {
    print('User left: $userId');
  }

  // Handle user disconnected event
  void _handleUserDisconnected(String userId) {
    print('User disconnected: $userId');
  }

  // Handle WebSocket errors
  void _handleWebSocketError(String errorMessage) {
    print('WebSocket error in WebRTC service: $errorMessage');
  }

  // Handle WebSocket connected event
  void _handleConnected() {
    print('WebSocket connected in WebRTC service');
  }

  // Handle WebSocket disconnected event
  void _handleDisconnected() {
    print('WebSocket disconnected in WebRTC service');
  }

  // Get user media with specific device
  Future<void> getUserMedia(String? deviceId) async {
    if (deviceId == null) {
      print('No video device selected');
      return;
    }

    try {
      // Stop existing stream if any
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) => track.stop());
        _localStream!.dispose();
      }

      final Map<String, dynamic> mediaConstraints = {
        'audio': true,
        'video': {
          'width': {'min': 640, 'ideal': 1280, 'max': 1920},
          'height': {'min': 480, 'ideal': 720, 'max': 1080},
          'frameRate': {'min': 30, 'ideal': 60},
          'facingMode': 'user',
          'deviceId': deviceId,
        }
      };

      MediaStream stream =
          await navigator.mediaDevices.getUserMedia(mediaConstraints);
      _localStream = stream;
      _localRenderer.srcObject = stream;
    } catch (e) {
      print('Error getting user media: $e');
      rethrow;
    }
  }

  // Create peer connection
  Future<void> _setupPeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [] // No STUN servers needed for local connections
    };

    // Create peer connection using the correct API
    _peerConnection = await createPeerConnection(configuration, {});

    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      print('New ICE candidate: ${candidate.toMap()}');
      // Send ICE candidate to remote peer via signaling server
      if (_webSocketService.isConnected) {
        _webSocketService.sendIceCandidate(
            candidate.toMap(), _currentUserId ?? 'unknown');
      }
    };

    _peerConnection!.onAddStream = (MediaStream stream) {
      print('Add stream: ${stream.id}');
      _remoteRenderer.srcObject = stream;
    };

    if (_localStream != null) {
      for (final track in _localStream!.getTracks()) {
        _peerConnection!.addTrack(track);
      }
    }
  }

  // Create offer and send via signaling server
  Future<RTCSessionDescription?> createOffer() async {
    if (_peerConnection == null) {
      await _setupPeerConnection();
    }

    try {
      RTCSessionDescription description = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(description);
      print('Offer created: ${description.sdp}');

      // Send offer via signaling server
      if (_webSocketService.isConnected) {
        await _webSocketService.sendOffer(
            description.sdp!, _currentUserId ?? 'unknown');
        print('Offer sent via signaling server');
      }

      return description;
    } catch (e) {
      print('Error creating offer: $e');
      return null;
    }
  }

  // Stop local stream
  void stopLocalStream() {
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) => track.stop());
      _localStream!.dispose();
      _localStream = null;
      _localRenderer.srcObject = null;
    }
  }

  // Close peer connection
  void closePeerConnection() {
    _peerConnection?.close();
    _peerConnection = null;
  }

  // Dispose resources
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.dispose();
    // Fire and forget - we can't await in dispose
    _webSocketService.disconnectFromSignalingServer();
  }
}
