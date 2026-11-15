import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:seminar_mobile/core/services/installation_identity.dart';
import 'package:seminar_mobile/data/remote/auth_api.dart';
import 'package:seminar_mobile/data/remote/auth_response.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('device login -> me unwraps the real backend data envelope', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (request.url.path.endsWith('/login-device')) {
        expect(jsonDecode(request.body)['device_id'], 'install-example');
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {'accessToken': 'access', 'refreshToken': 'refresh'},
          }),
          200,
        );
      }
      expect(request.headers['authorization'], 'Bearer access');
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'id': 'uuid-visitor',
            'full_name': 'Du khách',
            'email': null,
          },
        }),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    });
    addTearDown(client.close);
    final api = AuthApi(
      client: client,
      baseUrl: () => 'http://localhost:8000/api/v1/',
    );
    final session = await api.loginDevice(deviceId: 'install-example');
    final profile = await api.me(session['accessToken']);
    expect(profile['id'], 'uuid-visitor');
    expect(profile['full_name'], 'Du khách');
    expect(requests.map((r) => r.url.path).toList(), [
      '/api/v1/mobile/auth/login-device',
      '/api/v1/mobile/auth/me',
    ]);
  });

  test('Google login exchanges the SDK token and parses tokens', () async {
    final client = MockClient((request) async {
      expect(request.url.path, '/api/v1/mobile/auth/google-login');
      expect(jsonDecode(request.body)['idToken'], 'google-id-token');
      return http.Response(
        jsonEncode({'accessToken': 'access', 'refreshToken': 'refresh'}),
        200,
      );
    });
    addTearDown(client.close);
    final api = AuthApi(
      client: client,
      baseUrl: () => 'http://localhost:8000/api/v1',
    );
    expect(
      (await api.googleLogin(idToken: 'google-id-token'))['refreshToken'],
      'refresh',
    );
  });

  test('refresh accepts nested backend token data', () async {
    final client = MockClient(
      (request) async => http.Response(
        jsonEncode({
          'data': {
            'access_token': 'new-access',
            'refresh_token': 'new-refresh',
          },
        }),
        200,
      ),
    );
    addTearDown(client.close);
    final api = AuthApi(
      client: client,
      baseUrl: () => 'http://localhost/api/v1',
    );
    expect((await api.refresh('old-refresh'))['accessToken'], 'new-access');
  });

  test('network failure is not retried across six candidate URLs', () async {
    var attempts = 0;
    final client = MockClient((_) async {
      attempts++;
      throw http.ClientException('unreachable');
    });
    addTearDown(client.close);
    final api = AuthApi(
      client: client,
      baseUrl: () => 'http://localhost/api/v1',
    );
    await expectLater(
      api.loginDevice(deviceId: 'install-id'),
      throwsA(isA<Exception>()),
    );
    expect(attempts, 1);
  });

  test(
    'never duplicates the api prefix when trying candidate routes',
    () async {
      final paths = <String>[];
      final client = MockClient((request) async {
        paths.add(request.url.path);
        return http.Response('{}', 404);
      });
      addTearDown(client.close);
      final api = AuthApi(
        client: client,
        baseUrl: () => 'http://localhost/api/v1',
      );
      await expectLater(
        api.googleLogin(idToken: 'bad'),
        throwsA(isA<Exception>()),
      );
      expect(paths.every((path) => !path.contains('/api/v1/api/v1')), isTrue);
    },
  );

  test('token aliases do not overwrite normalized tokens with null', () {
    final result = normalizeAuthTokens({
      'accessToken': null,
      'access_token': 'access',
      'refresh_token': 'refresh',
    });
    expect(result['accessToken'], 'access');
    expect(result['refreshToken'], 'refresh');
  });

  test('a missing refresh token is not substituted with the access token', () {
    expect(
      () => normalizeAuthTokens({'accessToken': 'access'}),
      throwsFormatException,
    );
  });

  test('invalid profiles cannot become an unknown logged-in user', () {
    expect(() => normalizeAuthProfile({'data': {}}), throwsFormatException);
    expect(
      normalizeAuthProfile({
        'user': {'id': '42'},
      })['id'],
      '42',
    );
  });

  test(
    'installation identity persists and replaces a shared Android build ID',
    () async {
      SharedPreferences.setMockInitialValues({
        'auth_device_id': 'TP1A.220624.014',
      });
      final prefs = await SharedPreferences.getInstance();
      final first = await InstallationIdentity.loadOrCreate(prefs);
      final second = await InstallationIdentity.loadOrCreate(prefs);
      expect(first, startsWith('install_'));
      expect(second, first);
      expect(first, isNot('TP1A.220624.014'));
      expect(prefs.getString('auth_device_id'), first);
    },
  );

  test('separate installations receive separate identities', () async {
    SharedPreferences.setMockInitialValues({});
    final first = await InstallationIdentity.loadOrCreate(
      await SharedPreferences.getInstance(),
    );
    SharedPreferences.setMockInitialValues({});
    final second = await InstallationIdentity.loadOrCreate(
      await SharedPreferences.getInstance(),
    );
    expect(second, isNot(first));
  });
}
