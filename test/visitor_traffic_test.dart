import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seminar_mobile/core/navigation/poi_link.dart';
import 'package:seminar_mobile/core/services/visitor_analytics.dart';

Future<void> settle() async {
  for (var i = 0; i < 20; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DateTime now;
  late List<Map<String, dynamic>> sent;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    now = DateTime.utc(2026, 11, 22, 1);
    sent = [];
  });

  Future<VisitorAnalytics> service() async {
    final analytics = VisitorAnalytics(
      client: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        sent.addAll(
          (body['events'] as List).map((e) => Map<String, dynamic>.from(e)),
        );
        return http.Response('{}', 200);
      }),
      baseUrl: () => 'https://example.com/api/v1',
      now: () => now,
    );
    await analytics.init();
    return analytics;
  }

  test('visit identity is consent gated and removed on withdrawal', () async {
    final analytics = await service();
    addTearDown(analytics.dispose);
    final prefs = await SharedPreferences.getInstance();
    await analytics.startVisit();
    analytics.viewPoi('012345678901234567890123', fromQr: true);
    await settle();
    expect(sent, isEmpty);
    expect(prefs.getString(VisitorAnalytics.deviceKey), isNull);
    await analytics.setConsent(true);
    analytics.viewPoi('012345678901234567890123', fromQr: true);
    await settle();
    expect(sent.map((e) => e['kind']), ['app_visited', 'poi_viewed']);
    expect(sent.last['source'], 'qr');
    expect(sent.first['device_id'], sent.last['device_id']);
    expect(sent.first['session_id'], sent.last['session_id']);
    await analytics.setConsent(false);
    expect(prefs.getString(VisitorAnalytics.deviceKey), isNull);
    expect(prefs.getString(VisitorAnalytics.sessionKey), isNull);
    final count = sent.length;
    analytics.viewPoi('012345678901234567890123');
    await settle();
    expect(sent.length, count);
  });

  test(
    'reload preserves identities and 30 minute inactivity rotates only session',
    () async {
      final first = await service();
      await first.setConsent(true);
      await first.startVisit();
      await settle();
      final visit = Map<String, dynamic>.from(sent.single);
      first.dispose();
      now = now.add(const Duration(minutes: 20));
      final reloaded = await service();
      addTearDown(reloaded.dispose);
      await reloaded.startVisit();
      await settle();
      expect(sent.last['device_id'], visit['device_id']);
      expect(sent.last['session_id'], visit['session_id']);
      expect(sent.last['occurred_at'], visit['occurred_at']);
      // Another activity at +40 minutes keeps the session (only 20 minutes idle).
      now = now.add(const Duration(minutes: 20));
    reloaded.recordActivity();
    now = now.add(const Duration(minutes: 20));
      reloaded.viewPoi('012345678901234567890123');
      await settle();
      expect(sent.last['session_id'], visit['session_id']);
      now = now.add(const Duration(minutes: 30));
      reloaded.viewPoi('012345678901234567890123');
      await settle();
      expect(sent.last['session_id'], isNot(visit['session_id']));
      expect(sent.last['device_id'], visit['device_id']);
      expect(sent.where((e) => e['kind'] == 'app_visited').length, 3);
    },
  );

  test(
    'existing decline remains declined and playback-only grant is re-prompted',
    () async {
      SharedPreferences.setMockInitialValues({
        'visitor_analytics_consent_v1': false,
      });
      final declined = await service();
      expect(declined.hasChoice, isTrue);
      expect(declined.enabled, isFalse);
      declined.dispose();
      SharedPreferences.setMockInitialValues({
        'visitor_analytics_consent_v1': true,
      });
      final granted = await service();
      addTearDown(granted.dispose);
      await granted.startVisit();
      expect(granted.hasChoice, isFalse);
      expect(granted.enabled, isFalse);
      expect(sent, isEmpty);
    },
  );

  test(
    'QR attribution supports path and hash links without inferring all links are QR',
    () {
      expect(isQrLocation('/poi/abc?source=qr'), isTrue);
      expect(
        isQrLocation('https://visit.example.com/#/poi/abc?source=qr'),
        isTrue,
      );
      expect(isQrLocation('/poi/abc'), isFalse);
      expect(isQrLocation('/poi/abc?source=direct'), isFalse);
      expect(poiIdFromLocation('/poi/abc?source=qr'), 'abc');
    },
  );
}
