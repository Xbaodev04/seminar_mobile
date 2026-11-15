import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:seminar_mobile/data/remote/poi_access.dart';
import 'package:seminar_mobile/data/remote/poi_api.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  PoiApi api(Future<http.Response> Function(http.Request) handler) {
    final client = MockClient(handler);
    addTearDown(client.close);
    return PoiApi(client: client, baseUrl: () => 'https://example.com/api/v1/');
  }

  test(
    'unpublished response stops immediately without trying aliases',
    () async {
      var requests = 0;
      final service = api((request) async {
        requests++;
        expect(request.url.path, '/api/v1/mobile/pois/poi-1');
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'detail': {
                'code': 'poi_not_public',
                'message': 'Quán đã đóng cửa',
              },
            }),
          ),
          403,
        );
      });
      await expectLater(
        service.getPoi('poi-1', ''),
        throwsA(isA<PoiNotPublicException>()),
      );
      expect(requests, 1);
      expect(const PoiNotPublicException().toString(), 'Quán đã đóng cửa');
    },
  );

  for (final wrapped in [true, false]) {
    test(
      'unpublished success payload is also rejected (wrapped=$wrapped)',
      () async {
        final data = {'id': 'poi-1', 'is_active': false};
        final service = api(
          (_) async =>
              http.Response(jsonEncode(wrapped ? {'data': data} : data), 200),
        );
        await expectLater(
          service.getPoi('poi-1', ''),
          throwsA(isA<PoiNotPublicException>()),
        );
      },
    );
  }

  test('public POI preserves Vietnamese text and authorization', () async {
    final service = api((request) async {
      expect(request.headers['Authorization'], 'Bearer token');
      return http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'data': {'id': 'poi-1', 'name': 'Quán cá kho', 'is_active': true},
          }),
        ),
        200,
      );
    });
    expect((await service.getPoi('poi-1', 'token'))?['name'], 'Quán cá kho');
  });

  test('404 still tries legacy aliases and can find a public POI', () async {
    final service = api((request) async {
      if (request.url.path.contains('/stalls/')) {
        return http.Response(jsonEncode({'id': 'poi-1'}), 200);
      }
      return http.Response('{}', 404);
    });
    expect((await service.getPoi('poi-1', ''))?['id'], 'poi-1');
  });

  test('missing QR returns null rather than closed', () async {
    final service = api((_) async => http.Response('{}', 404));
    expect(await service.getPoi('missing', ''), isNull);
  });

  for (final status in [401, 403, 500]) {
    test('other HTTP $status errors are not treated as closed', () async {
      var requests = 0;
      final service = api((_) async {
        requests++;
        return http.Response(jsonEncode({'detail': 'Other error'}), status);
      });
      await expectLater(
        service.getPoi('poi-1', ''),
        throwsA(allOf(isA<Exception>(), isNot(isA<PoiNotPublicException>()))),
      );
      expect(requests, 1);
    });
  }

  test('connection error is propagated without a closed notice', () async {
    final service = api(
      (_) async => throw http.ClientException('No connection'),
    );
    await expectLater(
      service.getPoi('poi-1', ''),
      throwsA(isA<http.ClientException>()),
    );
  });
}
