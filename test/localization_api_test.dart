import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seminar_mobile/data/remote/localization_api.dart';

Map<String, dynamic> ready() => {
  'poi_id': 'poi-1',
  'lang': 'en',
  'title': 'Title',
  'translated_text': 'English narration',
  'audio_url': '/static/audio/test.mp3',
  'audio_status': 'completed',
  'is_fallback': false,
  'cache_hit': false,
};

void main() {
  test(
    'POST matches backend contract and resolves audio against origin',
    () async {
      final api = LocalizationApi(
        baseUrl: () => 'http://localhost:8000/api/v1/',
        client: MockClient((request) async {
          expect(request.method, 'POST');
          expect(
            request.url.toString(),
            'http://localhost:8000/api/v1/localizations/on-demand',
          );
          expect(jsonDecode(request.body), {'poi_id': 'poi-1', 'lang': 'en'});
          expect(request.headers['content-type'], 'application/json');
          return http.Response(jsonEncode(ready()), 200);
        }),
      );
      addTearDown(api.close);
      final result = await api.generate('poi-1', 'en');
      expect(result.audioUrl, 'http://localhost:8000/static/audio/test.mp3');
      expect(result.text, 'English narration');
    },
  );

  test('UTF-8 narration is decoded from bytes', () async {
    final body = ready()..['translated_text'] = 'Thuyết minh 日本語';
    final api = LocalizationApi(
      baseUrl: () => 'https://example.com/api/v1',
      client: MockClient(
        (_) async => http.Response.bytes(utf8.encode(jsonEncode(body)), 200),
      ),
    );
    addTearDown(api.close);
    expect((await api.generate('poi-1', 'en')).text, 'Thuyết minh 日本語');
  });

  for (final mutation in <Map<String, dynamic>>[
    {'lang': 'vi'},
    {'audio_status': 'pending'},
    {'is_fallback': true},
    {'audio_url': ''},
    {'audio_url': 'file:///secret.mp3'},
    {'translated_text': null},
  ]) {
    test('rejects unusable localization: $mutation', () async {
      final api = LocalizationApi(
        baseUrl: () => 'http://localhost:8000/api/v1',
        client: MockClient(
          (_) async =>
              http.Response(jsonEncode({...ready(), ...mutation}), 200),
        ),
      );
      addTearDown(api.close);
      await expectLater(api.generate('poi-1', 'en'), throwsFormatException);
    });
  }

  for (final status in [404, 409, 422, 429, 502, 503, 504]) {
    test('preserves HTTP failure $status', () async {
      final api = LocalizationApi(
        baseUrl: () => 'http://localhost/api/v1',
        client: MockClient((_) async => http.Response('{}', status)),
      );
      addTearDown(api.close);
      await expectLater(
        api.generate('poi-1', 'en'),
        throwsA(
          isA<LocalizationFailure>().having(
            (e) => e.statusCode,
            'status',
            status,
          ),
        ),
      );
    });
  }

  test('Retry-After prevents repeated calls until cooldown ends', () async {
    var calls = 0;
    var stamp = DateTime.utc(2026, 11, 10);
    final api = LocalizationApi(
      baseUrl: () => 'http://localhost/api/v1',
      clock: () => stamp,
      client: MockClient((_) async {
        calls++;
        if (calls == 1) {
          return http.Response('{}', 429, headers: {'retry-after': '30'});
        }
        return http.Response(jsonEncode(ready()), 200);
      }),
    );
    addTearDown(api.close);
    await expectLater(
      api.generate('poi-1', 'en'),
      throwsA(isA<LocalizationFailure>()),
    );
    await expectLater(
      api.generate('poi-2', 'en'),
      throwsA(isA<LocalizationFailure>()),
    );
    expect(calls, 1);
    stamp = stamp.add(const Duration(seconds: 31));
    await api.generate('poi-1', 'en');
    expect(calls, 2);
  });

  test('network timeout is bounded', () async {
    final pending = Completer<http.Response>();
    final api = LocalizationApi(
      baseUrl: () => 'http://localhost/api/v1',
      timeout: const Duration(milliseconds: 10),
      client: MockClient((_) => pending.future),
    );
    addTearDown(api.close);
    await expectLater(
      api.generate('poi-1', 'en'),
      throwsA(isA<TimeoutException>()),
    );
    pending.complete(http.Response('{}', 504));
  });
}
