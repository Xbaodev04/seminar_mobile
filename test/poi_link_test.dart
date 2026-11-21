import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seminar_mobile/core/config/api_config.dart';
import 'package:seminar_mobile/core/navigation/poi_link.dart';
import 'package:seminar_mobile/data/remote/poi_access.dart';
import 'package:seminar_mobile/main.dart';
import 'package:seminar_mobile/presentation/pages/poi_link_page.dart';

void main() {
  test(
    'recognizes printed QR URLs, refresh paths and existing query/hash links',
    () {
      for (final location in [
        '/poi/abc123',
        'https://visit.example.com/poi/abc123',
        '/pois/abc123',
        '/?poi=abc123',
        'https://visit.example.com/#/poi/abc123',
      ]) {
        expect(poiIdFromLocation(location), 'abc123', reason: location);
        expect(isPoiLocation(location), isTrue, reason: location);
      }
      for (final location in [
        '/poi/',
        '/poi/../secret',
        '/poi/a%2Fb',
        '/poi/a/more',
        '/login',
      ]) {
        expect(poiIdFromLocation(location), isNull, reason: location);
      }
    },
  );

  test(
    'media resolves against configured backend and preserves Cloudinary URLs',
    () {
      const api = 'https://api.example.com/api/v1';
      expect(
        resolveMediaUrl('/static/images/a.png', api),
        'https://api.example.com/static/images/a.png',
      );
      expect(
        resolveMediaUrl('static/images/a.png', api),
        'https://api.example.com/static/images/a.png',
      );
      const cloud = 'https://res.cloudinary.com/cloud/image/upload/a.png';
      expect(resolveMediaUrl(cloud, api), cloud);
      expect(resolveMediaUrl('javascript:alert(1)', api), isNull);
      expect(resolveMediaUrl('//evil.example.com/a.png', api), isNull);
    },
  );

  testWidgets(
    'camera link opens public POI without login and displays loading',
    (tester) async {
      final response = Completer<Map<String, dynamic>?>();
      String? requested;
      await tester.pumpWidget(
        MaterialApp(
          home: PoiLinkPage(
            poiId: 'abc123',
            lookupPoi: (id) {
              requested = id;
              return response.future;
            },
            detailBuilder: (poi) => Scaffold(body: Text(poi.name)),
          ),
        ),
      );
      expect(find.text('Đang tải thông tin quán…'), findsOneWidget);
      response.complete({
        'id': 'abc123',
        'name': 'Quán từ QR',
        'is_active': true,
      });
      await tester.pumpAndSettle();
      expect(requested, 'abc123');
      expect(find.text('Quán từ QR'), findsOneWidget);
      expect(find.text('Đăng nhập'), findsNothing);
    },
  );

  testWidgets('hidden POI is rejected before rendering details', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PoiLinkPage(
          poiId: 'hidden',
          lookupPoi: (_) async => {
            'id': 'hidden',
            'name': 'Hidden',
            'is_active': false,
          },
          detailBuilder: (_) => const Text('Must not show'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(PoiNotPublicException.message), findsOneWidget);
    expect(find.text('Must not show'), findsNothing);
  });

  testWidgets('network failure can be retried without losing the QR target', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PoiLinkPage(
          poiId: 'retry',
          lookupPoi: (id) async {
            expect(id, 'retry');
            if (++calls == 1) throw Exception('network');
            return {'id': id, 'name': 'Tải thành công'};
          },
          detailBuilder: (poi) => Text(poi.name),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Không tải được thông tin quán. Vui lòng thử lại.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Tải thành công'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets(
    'invalid initial QR path bypasses splash and language/login gates',
    (tester) async {
      await tester.pumpWidget(const MyApp(initialLocation: '/poi/a%2Fb'));
      await tester.pumpAndSettle();
      expect(find.byType(PoiLinkPage), findsOneWidget);
      expect(find.text('Liên kết quán không hợp lệ'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
