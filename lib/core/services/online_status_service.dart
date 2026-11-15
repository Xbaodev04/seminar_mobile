import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OnlineStatusService extends ChangeNotifier {
  OnlineStatusService({
    required String baseUrl,
    required String deviceId,
    WebSocketChannel Function(Uri)? connector,
    this.pingInterval = const Duration(seconds: 30),
    this.reconnectDelay = const Duration(seconds: 5),
    this.connectionTimeout = const Duration(seconds: 8),
  }) : _connector = connector ?? WebSocketChannel.connect {
    final base = Uri.parse(baseUrl);
    var path = base.path.replaceFirst(RegExp(r'/+$'), '');
    if (!path.endsWith('/api/v1')) path += '/api/v1';
    _uri = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: '$path/mobile/ws/online/${Uri.encodeComponent(deviceId)}',
      query: null,
      fragment: null,
    );
  }

  final WebSocketChannel Function(Uri) _connector;
  final Duration pingInterval;
  final Duration reconnectDelay;
  final Duration connectionTimeout;
  late final Uri _uri;
  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _messages;
  Future<void>? _connecting;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _desiredConnected = false;
  bool _disposed = false;
  bool _isConnected = false;
  int _onlineCount = 0;
  int _generation = 0;

  bool get isConnected => _isConnected;
  int get onlineCount => _onlineCount;

  Future<void> connect({int? userId}) {
    if (_disposed) return Future.value();
    _desiredConnected = true;
    if (_isConnected) return Future.value();
    if (_connecting != null) return _connecting!;
    final generation = _generation;
    final future = _open(generation);
    _connecting = future;
    return future.whenComplete(() {
      if (identical(_connecting, future)) _connecting = null;
    });
  }

  Future<void> _open(int generation) async {
    WebSocketChannel? channel;
    try {
      channel = _connector(_uri);
      await channel.ready.timeout(connectionTimeout);
      if (_disposed || !_desiredConnected || generation != _generation) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _isConnected = true;
      _messages = channel.stream.listen(
        (raw) {
          if (!identical(_channel, channel)) return;
          try {
            final data = jsonDecode(raw as String);
            final count = data['type'] == 'online_count'
                ? data['count']
                : data['online_count'];
            if (count is int && count >= 0) {
              _onlineCount = count;
              _notify();
            }
          } catch (_) {
            /* Ignore malformed server frames. */
          }
        },
        onDone: () => _lost(channel!),
        onError: (Object _) => _lost(channel!),
      );
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(pingInterval, (_) => _ping());
      _ping();
      _notify();
    } catch (_) {
      unawaited(channel?.sink.close());
      if (generation == _generation && !_disposed) {
        _isConnected = false;
        _retry();
        _notify();
      }
    }
  }

  void _ping() {
    try {
      _channel?.sink.add(jsonEncode({'action': 'ping'}));
    } catch (_) {
      if (_channel != null) _lost(_channel!);
    }
  }

  void _lost(WebSocketChannel channel) {
    if (!identical(_channel, channel)) return;
    _channel = null;
    _isConnected = false;
    _pingTimer?.cancel();
    unawaited(_messages?.cancel());
    unawaited(channel.sink.close());
    _retry();
    _notify();
  }

  void _retry() {
    _reconnectTimer?.cancel();
    if (!_desiredConnected || _disposed) return;
    _reconnectTimer = Timer(reconnectDelay, () => unawaited(connect()));
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> disconnect() async {
    _desiredConnected = false;
    ++_generation;
    _connecting = null;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    final channel = _channel;
    _channel = null;
    _isConnected = false;
    await _messages?.cancel();
    _messages = null;
    try {
      channel?.sink.add(jsonEncode({'action': 'disconnect'}));
      await channel?.sink.close();
    } catch (_) {}
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(disconnect());
    super.dispose();
  }
}
