import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:seminar_mobile/core/services/online_status_service.dart';

class FakeChannel implements WebSocketChannel {
  final incoming = StreamController<dynamic>();
  final readyGate = Completer<void>();
  late final output = FakeSink(this);
  FakeChannel({bool ready = true}) {
    if (ready) readyGate.complete();
  }
  @override
  Future<void> get ready => readyGate.future;
  @override
  Stream<dynamic> get stream => incoming.stream;
  @override
  WebSocketSink get sink => output;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSink implements WebSocketSink {
  FakeSink(this.channel);
  final FakeChannel channel;
  final messages = <dynamic>[];
  final finished = Completer<void>();
  bool closed = false;
  @override
  void add(dynamic value) {
    messages.add(value);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}
  @override
  Future<void> addStream(Stream<dynamic> stream) async {
    await for (final message in stream) {
      add(message);
    }
  }

  @override
  Future<void> get done => finished.future;
  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
    if (!finished.isCompleted) finished.complete();
    if (!channel.incoming.isClosed) unawaited(channel.incoming.close());
  }
}

void main() {
  test(
    'connect is idempotent across login and resume; canonical URL has one API prefix',
    () async {
      final socket = FakeChannel();
      var opens = 0;
      final service = OnlineStatusService(
        baseUrl: 'https://example.com/api/v1/',
        deviceId: 'install_123',
        connector: (uri) {
          expect(
            uri.toString(),
            'wss://example.com/api/v1/mobile/ws/online/install_123',
          );
          opens++;
          return socket;
        },
      );
      addTearDown(service.dispose);
      await Future.wait([service.connect(), service.connect(userId: 1)]);
      await service.connect();
      expect(opens, 1);
      expect(service.isConnected, isTrue);
      expect(jsonDecode(socket.output.messages.first), {'action': 'ping'});
    },
  );

  test(
    'background disconnect cancels retry, and foreground resume reconnects',
    () async {
      final sockets = <FakeChannel>[];
      final service = OnlineStatusService(
        baseUrl: 'http://example.com',
        deviceId: 'install_123',
        reconnectDelay: const Duration(milliseconds: 10),
        connector: (_) {
          final socket = FakeChannel();
          sockets.add(socket);
          return socket;
        },
      );
      addTearDown(service.dispose);
      await service.connect();
      await service.disconnect();
      await Future<void>.delayed(const Duration(milliseconds: 35));
      expect(sockets.length, 1);
      expect(service.isConnected, isFalse);
      expect(sockets.first.output.closed, isTrue);
      await service.connect();
      expect(sockets.length, 2);
      expect(service.isConnected, isTrue);
    },
  );

  test(
    'late connection cannot revive a background session or replace its successor',
    () async {
      final old = FakeChannel(ready: false);
      final current = FakeChannel();
      var opens = 0;
      final service = OnlineStatusService(
        baseUrl: 'http://example.com/api/v1',
        deviceId: 'install_123',
        connector: (_) => opens++ == 0 ? old : current,
      );
      addTearDown(service.dispose);
      final opening = service.connect();
      await service.disconnect();
      await service.connect();
      old.readyGate.complete();
      await opening;
      expect(old.output.closed, isTrue);
      expect(current.output.closed, isFalse);
      expect(service.isConnected, isTrue);
    },
  );

  test(
    'server pong updates online count and unexpected close reconnects',
    () async {
      final sockets = <FakeChannel>[];
      final service = OnlineStatusService(
        baseUrl: 'http://example.com',
        deviceId: 'install_123',
        reconnectDelay: const Duration(milliseconds: 10),
        connector: (_) {
          final socket = FakeChannel();
          sockets.add(socket);
          return socket;
        },
      );
      addTearDown(service.dispose);
      await service.connect();
      sockets.first.incoming.add(
        jsonEncode({'type': 'pong', 'online_count': 4}),
      );
      await Future<void>.delayed(Duration.zero);
      expect(service.onlineCount, 4);
      await sockets.first.incoming.close();
      await Future<void>.delayed(const Duration(milliseconds: 35));
      expect(sockets.length, 2);
      expect(service.isConnected, isTrue);
    },
  );
}
