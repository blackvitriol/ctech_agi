import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _heartbeatTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;
  static const Duration reconnectDelay = Duration(seconds: 2);

  // Callbacks for different message types
  Function(Map<String, dynamic>)? onOffer;
  Function(Map<String, dynamic>)? onAnswer;
  Function(Map<String, dynamic>)? onIceCandidate;
  Function(String)? onUserJoined;
  Function(String)? onUserLeft;
  Function(String)? onUserDisconnected;
  Function()? onConnected;
  Function()? onDisconnected;
  Function(String)? onError;
  Function(String)? onServerInfo;

  bool get isConnected => _isConnected;
  String? _serverName;
  String? get serverName => _serverName;

  // Get detailed connection status for debugging
  Map<String, dynamic> get connectionStatus {
    return {
      'isConnected': _isConnected,
      'channelExists': _channel != null,
      'sinkExists': _channel?.sink != null,
      'reconnectAttempts': _reconnectAttempts,
      'hasReconnectTimer': _reconnectTimer != null,
      'hasHeartbeatTimer': _heartbeatTimer != null,
    };
  }

  Future<bool> connectToSignalingServer(String serverUrl, String roomId) async {
    if (_isConnected) {
      await disconnectFromSignalingServer();
    }

    try {
      _reconnectAttempts = 0;

      if (serverUrl.isEmpty || roomId.isEmpty) {
        print(
            'Invalid server URL or room ID: serverUrl="$serverUrl", roomId="$roomId"');
        onError?.call('Invalid server URL or room ID');
        return false;
      }

      final wsUrl = 'ws://$serverUrl:8000/ws/$roomId';
      print('Attempting to connect to: $wsUrl');

      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      if (_channel == null) {
        throw Exception('WebSocket channel is null after creation');
      }

      // Set up stream listener
      bool hasError = false;
      _channel!.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          if (!hasError) {
            hasError = true;
            print('WebSocket stream error: $error');
            _handleError(error);
          }
        },
        onDone: () {
          print('WebSocket stream done');
          _handleDisconnection();
        },
        cancelOnError: false,
      );

      // Send join immediately after opening the channel
      try {
        await _sendMessage({
          'type': 'join',
          'roomId': roomId,
        });

        _isConnected = true;
        _startHeartbeat();
        onConnected?.call();
        print('WebSocket connection successful');
        return true;
      } catch (e) {
        print('Failed to send join message: $e');
        _isConnected = false;
        onError?.call('Failed to send join message: $e');
        return false;
      }
    } catch (e) {
      print('WebSocket connection failed: $e');
      _isConnected = false;
      onError?.call('WebSocket connection failed: $e');
      _scheduleReconnect(serverUrl, roomId);
      return false;
    }
  }

  void _scheduleReconnect(String serverUrl, String roomId) {
    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      print(
          'Scheduling reconnection attempt $_reconnectAttempts in ${reconnectDelay.inSeconds} seconds');

      _reconnectTimer?.cancel();
      _reconnectTimer = Timer(reconnectDelay, () {
        print('Attempting reconnection...');
        connectToSignalingServer(serverUrl, roomId);
      });
    } else {
      print('Max reconnection attempts reached');
      // Only call error callback once when max attempts reached
      if (_reconnectAttempts == maxReconnectAttempts) {
        onError?.call(
            'Connection failed after $_reconnectAttempts attempts. Please check server and try again.');
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected && _channel != null) {
        try {
          _sendMessage({'type': 'ping'});
        } catch (e) {
          print('Heartbeat failed: $e');
          _handleError('Heartbeat failed');
        }
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> disconnectFromSignalingServer() async {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();

    if (_channel != null) {
      try {
        if (_isConnected) {
          await _sendMessage({'type': 'leave'});
        }
        await _channel!.sink.close(1000, 'Client disconnected');
      } catch (e) {
        print('Error during disconnect: $e');
      } finally {
        _channel = null;
      }
    }

    _isConnected = false;
    onDisconnected?.call();
  }

  // WebRTC signaling methods
  Future<void> sendOffer(String offer, String targetUserId) async {
    await _sendMessage({
      'type': 'offer',
      'offer': offer,
      'targetUserId': targetUserId,
    });
  }

  Future<void> sendAnswer(String answer, String targetUserId) async {
    await _sendMessage({
      'type': 'answer',
      'answer': answer,
      'targetUserId': targetUserId,
    });
  }

  Future<void> sendIceCandidate(
      Map<String, dynamic> candidate, String targetUserId) async {
    await _sendMessage({
      'type': 'ice-candidate',
      'candidate': candidate,
      'targetUserId': targetUserId,
    });
  }

  Future<void> _sendMessage(Map<String, dynamic> message) async {
    // Allow sending as soon as channel exists (even before onConnected),
    // so the initial 'join' can be delivered to establish the session.
    if (_channel != null) {
      try {
        final jsonMessage = jsonEncode(message);
        print('Sending message: $jsonMessage');
        _channel!.sink.add(jsonMessage);
      } catch (e) {
        print('Failed to send message: $e');
        throw e;
      }
    } else {
      print(
          'Cannot send message: channel is ${_channel == null ? 'null' : 'not ready'}');
      throw Exception('WebSocket not connected');
    }
  }

  void _handleMessage(dynamic message) {
    try {
      print('Received message: $message');

      if (message is String) {
        final data = jsonDecode(message);
        final type = data['type'];
        print('Parsed message type: $type');

        switch (type) {
          case 'offer':
            onOffer?.call(data);
            break;
          case 'answer':
            onAnswer?.call(data);
            break;
          case 'ice-candidate':
            onIceCandidate?.call(data);
            break;
          case 'user_joined':
            onUserJoined?.call(data['userId'] ?? 'Unknown');
            break;
          case 'user_left':
            onUserLeft?.call(data['userId'] ?? 'Unknown');
            break;
          case 'user_disconnected':
            onUserDisconnected?.call(data['userId'] ?? 'Unknown');
            break;
          case 'connected':
            _isConnected = true;
            if (data.containsKey('serverName')) {
              _serverName = data['serverName'];
              onServerInfo?.call(_serverName!);
            }
            onConnected?.call();
            break;
          case 'disconnected':
            _isConnected = false;
            onDisconnected?.call();
            break;
          case 'pong':
            print('Received pong response');
            break;
          default:
            print('Unknown message type: $type');
        }
      } else {
        print('Message is not a string: $message');
      }
    } catch (e) {
      print('Error parsing message: $e');
      print('Raw message: $message');
    }
  }

  void _handleError(dynamic error) {
    print('WebSocket error: $error');
    _isConnected = false;
    onError?.call('WebSocket connection failed: $error');
    onDisconnected?.call();
  }

  void _handleDisconnection() {
    print('WebSocket connection closed');
    _isConnected = false;
    onDisconnected?.call();
  }

  void dispose() {
    _reconnectTimer?.cancel();
    _heartbeatTimer?.cancel();
    disconnectFromSignalingServer();
  }
}
