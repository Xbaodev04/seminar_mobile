import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OnlineStatusService extends ChangeNotifier {
  WebSocketChannel? _channel;
  late String _deviceId;
  late int? _userId;
  late List<String> _candidateWsUrls;
  bool _isConnected = false;
  int _onlineCount = 0;
  Timer? _pingTimer;
  Timer? _reconnectTimer;

  static const int PING_INTERVAL = 30; // seconds
  static const int RECONNECT_DELAY = 5; // seconds

  OnlineStatusService({required String baseUrl, required String deviceId}) {
    // Clean deviceId by stripping fragment hash '#' and URL special characters
    _deviceId = deviceId.replaceAll('#', '').trim();
    if (_deviceId.isEmpty) _deviceId = 'unknown_device';

    // Convert http/https to ws/wss and clean trailing slashes
    String cleanUrl = baseUrl.replaceFirst(RegExp(r'https?://'), '');
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }

    bool isSecure = baseUrl.startsWith('https');
    final scheme = isSecure ? 'wss' : 'ws';

    // Candidate URL paths (handles with or without /api/v1 prefix)
    if (cleanUrl.endsWith('/api/v1')) {
      final baseHost = cleanUrl.substring(0, cleanUrl.length - 7);
      _candidateWsUrls = [
        '$scheme://$cleanUrl/mobile/ws/online/$_deviceId',
        '$scheme://$baseHost/mobile/ws/online/$_deviceId',
        '$scheme://$cleanUrl/ws/online/$_deviceId',
      ];
    } else {
      _candidateWsUrls = [
        '$scheme://$cleanUrl/api/v1/mobile/ws/online/$_deviceId',
        '$scheme://$cleanUrl/mobile/ws/online/$_deviceId',
        '$scheme://$cleanUrl/ws/online/$_deviceId',
      ];
    }
  }

  bool get isConnected => _isConnected;
  int get onlineCount => _onlineCount;

  /// Initialize and connect to WebSocket
  Future<void> connect({int? userId}) async {
    _userId = userId;

    for (final wsUrl in _candidateWsUrls) {
      try {
        final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        await channel.ready;

        _channel = channel;
        _isConnected = true;
        notifyListeners();

        print('✓ WebSocket connected for device: $_deviceId at $wsUrl');

        _listenToMessages();
        _sendConnectMessage(userId);
        _startPingTimer();
        return; // Connected successfully!
      } catch (_) {
        // Try next candidate URL
      }
    }

    print('✗ WebSocket connection failed for all candidates');
    _isConnected = false;
    _scheduleReconnect();
    notifyListeners();
  }

  /// Listen to incoming WebSocket messages
  void _listenToMessages() {
    if (_channel == null) return;

    _channel!.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message);
          _handleMessage(data);
        } catch (e) {
          print('Error parsing WebSocket message: $e');
        }
      },
      onError: (error) {
        print('WebSocket error: $error');
        _handleDisconnect();
      },
      onDone: () {
        print('WebSocket connection closed');
        _handleDisconnect();
      },
    );
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(Map<String, dynamic> data) {
    final type = data['type'];

    switch (type) {
      case 'online_count':
        _onlineCount = data['count'] ?? 0;
        print('📊 Online users: $_onlineCount');
        notifyListeners();
        break;

      case 'pong':
        _onlineCount = data['online_count'] ?? 0;
        print('📍 Heartbeat received, online: $_onlineCount');
        break;

      default:
        print('Unknown message type: $type');
    }
  }

  /// Send initial connect message with device info
  void _sendConnectMessage(int? userId) {
    final message = {
      'action': 'update_user',
      'device_id': _deviceId,
      'user_id': userId,
      'platform': Platform.isAndroid ? 'android' : 'ios',
    };

    try {
      _channel?.sink.add(jsonEncode(message));
      print('📤 Sent connect message: $_deviceId');
    } catch (e) {
      print('Error sending connect message: $e');
    }
  }

  /// Send ping to keep connection alive
  void _sendPing() {
    final message = {'action': 'ping', 'device_id': _deviceId};

    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      print('Error sending ping: $e');
      _handleDisconnect();
    }
  }

  /// Start periodic ping timer
  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: PING_INTERVAL), (
      timer,
    ) {
      if (_isConnected) {
        _sendPing();
      } else {
        timer.cancel();
      }
    });
  }

  /// Handle disconnection
  void _handleDisconnect() {
    _isConnected = false;
    _pingTimer?.cancel();
    notifyListeners();
    _scheduleReconnect();
  }

  /// Schedule automatic reconnection
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: RECONNECT_DELAY), () {
      print('🔄 Attempting to reconnect...');
      connect(userId: _userId);
    });
  }

  /// Disconnect from WebSocket
  Future<void> disconnect() async {
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();

    try {
      final message = {'action': 'disconnect', 'device_id': _deviceId};
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      print('Error sending disconnect message: $e');
    }

    try {
      await _channel?.sink.close();
    } catch (e) {
      print('Error closing WebSocket: $e');
    }

    _channel = null;
    _isConnected = false;
    notifyListeners();
    print('✗ WebSocket disconnected for device: $_deviceId');
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
