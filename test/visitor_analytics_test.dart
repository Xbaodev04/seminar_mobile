import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seminar_mobile/core/services/visitor_analytics.dart';

Map<String, dynamic> event() => {
  'event_id': analyticsEventId(),
  'poi_id': '012345678901234567890123',
  'playback_id': analyticsEventId(),
  'kind': 'audio_started',
  'language': 'vi',
  'occurred_at': DateTime.now().toUtc().toIso8601String(),
};

Future<void> settle() async {
  for (var i = 0; i < 15; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<VisitorAnalytics> service(
    Future<http.Response> Function(http.Request) handler, {
    bool? consent,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (consent != null)
      await prefs.setBool(VisitorAnalytics.consentKey, consent);
    final result = VisitorAnalytics(
      client: MockClient(handler),
      baseUrl: () => 'https://example.com/api/v1/',
    );
    addTearDown(result.dispose);
    await result.init(preferences: prefs);
    return result;
  }

  test('no event is sent or saved before consent or after decline', () async {
    var requests = 0;
    final analytics = await service((_) async {
      requests++;
      return http.Response('{}', 200);
    });
    analytics.record(event());
    expect(analytics.hasChoice, isFalse);
    await analytics.setConsent(false);
    analytics.record(event());
    await settle();
    expect(requests, 0);
    expect(analytics.pendingCount, 0);
  });

  test('granted consent sends the exact anonymous backend contract', () async {
    final sent = <Map<String, dynamic>>[];
    final analytics = await service((request) async {
      expect(
        request.url.toString(),
        'https://example.com/api/v1/analytics/collect',
      );
      expect(request.method, 'POST');
      sent.add(jsonDecode(request.body));
      return http.Response('{"recorded":1}', 200);
    }, consent: true);
    final playback = event();
    analytics.record(playback);
    await settle();
    expect(sent.single, {
      'consent_status': 'granted',
      'events': [playback],
    });
    expect(analytics.pendingCount, 0);
  });

  test('network retry preserves event and playback IDs', () async {
    var online = false;
    final requests = <Map<String, dynamic>>[];
    final analytics = await service((request) async {
      requests.add(jsonDecode(request.body));
      if (!online) throw http.ClientException('offline');
      return http.Response('{}', 200);
    }, consent: true);
    analytics.record(event());
    await settle();
    expect(analytics.pendingCount, 1);
    online = true;
    await analytics.flush();
    expect(requests.first, requests.last);
    expect(analytics.pendingCount, 0);
  });

  test('pending offline events are recovered after app restart', () async {
    final analytics = await service(
      (_) async => http.Response('{}', 503),
      consent: true,
    );
    final playback = event();
    analytics.record(playback);
    await settle();
    final restored = <Map<String, dynamic>>[];
    await service((request) async {
      restored.add(jsonDecode(request.body));
      return http.Response('{}', 200);
    });
    await settle();
    expect((restored.single['events'] as List).single, playback);
  });

  test(
    'revoking consent clears persisted offline events and prevents retries',
    () async {
      var requests = 0;
      final analytics = await service((_) async {
        requests++;
        return http.Response('{}', 429);
      }, consent: true);
      analytics.record(event());
      await settle();
      expect(analytics.pendingCount, 1);
      await analytics.setConsent(false);
      final before = requests;
      await analytics.flush();
      expect(requests, before);
      expect(analytics.pendingCount, 0);
      final prefs = await SharedPreferences.getInstance();
      expect(jsonDecode(prefs.getString(VisitorAnalytics.queueKey)!), isEmpty);
    },
  );

  test(
    'concurrent additions stay queued and are sent in batches of at most 50',
    () async {
      final gate = Completer<http.Response>();
      final batches = <List<dynamic>>[];
      final analytics = await service((request) async {
        batches.add(jsonDecode(request.body)['events']);
        if (batches.length == 1) return gate.future;
        return http.Response('{}', 200);
      }, consent: true);
      analytics.record(event());
      await settle();
      for (var i = 0; i < 75; i++) {
        analytics.record(event());
      }
      gate.complete(http.Response('{}', 200));
      await settle();
      expect(batches.expand((batch) => batch).length, 76);
      expect(batches.every((batch) => batch.length <= 50), isTrue);
      expect(analytics.pendingCount, 0);
    },
  );
}
