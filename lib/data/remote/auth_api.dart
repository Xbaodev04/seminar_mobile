import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:seminar_mobile/core/services/locale_provider.dart';

import 'api_client.dart';
import 'http_client.dart';

class AuthApi {
  AuthApi._private();
  static final AuthApi instance = AuthApi._private();

  static const _timeout = Duration(seconds: 60);

  Uri _uri(String path) => Uri.parse('${ApiClient.instance.baseUrl}$path');

  Future<http.Response> _postReq(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final defaultLocale =
        LocaleProvider.instance.locale?.languageCode ??
        (PlatformDispatcher.instance.locale.languageCode);
    final mergedHeaders = {
      'Accept-Language': defaultLocale,
      if (headers != null) ...headers,
    };
    if (mergedHeaders.containsKey('Authorization')) {
      return await HttpClientWithTokenRefresh.instance.post(
        _uri(path),
        headers: mergedHeaders,
        body: body,
        timeout: _timeout,
      );
    }
    try {
      final res = await http
          .post(_uri(path), headers: mergedHeaders, body: body)
          .timeout(_timeout);
      return res;
    } on TimeoutException {
      throw Exception('Request timed out. Please check network or server.');
    }
  }

  Future<http.Response> _getReq(
    String path, {
    Map<String, String>? headers,
  }) async {
    final defaultLocale =
        LocaleProvider.instance.locale?.languageCode ??
        (PlatformDispatcher.instance.locale.languageCode);
    final mergedHeaders = {
      'Accept-Language': defaultLocale,
      if (headers != null) ...headers,
    };
    if (mergedHeaders.containsKey('Authorization')) {
      return await HttpClientWithTokenRefresh.instance.get(
        _uri(path),
        headers: mergedHeaders,
        timeout: _timeout,
      );
    }
    try {
      final res = await http
          .get(_uri(path), headers: mergedHeaders)
          .timeout(_timeout);
      return res;
    } on TimeoutException {
      throw Exception('Request timed out. Please check network or server.');
    }
  }

  Future<http.Response> _postReqWithCandidates(
    List<String> subPaths, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    http.Response? lastRes;
    for (final subPath in subPaths) {
      final candidatePaths = [
        '/api/v1$subPath',
        '/api/v1$subPath/',
        subPath,
        '$subPath/',
      ];
      for (final path in candidatePaths) {
        try {
          final res = await _postReq(path, headers: headers, body: body);
          if (res.statusCode != 404) {
            return res;
          }
          lastRes = res;
        } catch (_) {
          // Continue trying next candidate
        }
      }
    }
    if (lastRes != null) return lastRes;
    throw Exception('Endpoint not found (404)');
  }

  Future<http.Response> _getReqWithCandidates(
    List<String> subPaths, {
    Map<String, String>? headers,
  }) async {
    http.Response? lastRes;
    for (final subPath in subPaths) {
      final candidatePaths = [
        '/api/v1$subPath',
        '/api/v1$subPath/',
        subPath,
        '$subPath/',
      ];
      for (final path in candidatePaths) {
        try {
          final res = await _getReq(path, headers: headers);
          if (res.statusCode != 404) {
            return res;
          }
          lastRes = res;
        } catch (_) {
          // Continue trying next candidate
        }
      }
    }
    if (lastRes != null) return lastRes;
    throw Exception('Endpoint not found (404)');
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _postReqWithCandidates(
      ['/mobile/auth/login'],
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (res.statusCode >= 400) {
      throw Exception(_parseError(res));
    }
    try {
      final js = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      final access = js['accessToken'] ?? js['access_token'];
      final refresh = js['refreshToken'] ?? js['refresh_token'];
      if (access == null || access is! String) {
        throw Exception('Login response missing tokens');
      }
      return {'accessToken': access, 'refreshToken': refresh ?? access, ...js};
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Invalid response from server during login');
    }
  }

  Future<Map<String, dynamic>> register({
    String? username,
    required String email,
    required String password,
    required String full_name,
  }) async {
    final payload = <String, dynamic>{
      'username': username,
      'email': email,
      'password': password,
      'full_name': full_name,
    };
    final res = await _postReqWithCandidates(
      ['/mobile/auth/register'],
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (res.statusCode >= 400) {
      throw Exception(_parseError(res));
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (e) {
      return {'message': 'OTP sent to email'};
    }
  }

  Future<Map<String, dynamic>> verify({
    required String email,
    required String otp,
  }) async {
    final res = await _postReqWithCandidates(
      ['/mobile/auth/verify'],
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'otp': otp}),
    );
    if (res.statusCode >= 400) {
      throw Exception(_parseError(res));
    }
    try {
      final js = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      final access = js['accessToken'] ?? js['access_token'];
      final refresh = js['refreshToken'] ?? js['refresh_token'];
      if (access == null || access is! String) {
        throw Exception('Verify response missing tokens');
      }
      return {'accessToken': access, 'refreshToken': refresh ?? access, ...js};
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Invalid response from server during verify');
    }
  }

  Future<Map<String, dynamic>> me(String accessToken) async {
    final res = await _getReqWithCandidates(
      ['/mobile/auth/me'],
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    if (res.statusCode >= 400) {
      throw Exception(_parseError(res));
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (e) {
      throw Exception('Invalid response from server during me');
    }
  }

  Future<Map<String, dynamic>> refresh(String refreshToken) async {
    final res = await _postReqWithCandidates(
      ['/mobile/auth/refresh'],
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'refreshToken': refreshToken,
        'refresh_token': refreshToken,
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception(_parseError(res));
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (e) {
      throw Exception('Invalid response from server during refresh');
    }
  }

  Future<Map<String, dynamic>> forgotPassword({required String email}) async {
    final res = await _postReqWithCandidates(
      ['/mobile/auth/forgot-password'],
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );
    if (res.statusCode >= 400) {
      throw Exception(_parseError(res));
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (e) {
      return {'message': 'Password reset email sent'};
    }
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final res = await _postReqWithCandidates(
      ['/mobile/auth/reset-password'],
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'otp': otp,
        'new_password': newPassword,
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception(_parseError(res));
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (e) {
      return {'message': 'Password reset successful'};
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _postReqWithCandidates(
      ['/mobile/auth/change-password'],
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'current_password': currentPassword,
        'new_password': newPassword,
      }),
    );
    if (res.statusCode >= 400) {
      throw Exception(_parseError(res));
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (e) {
      return {'message': 'Password changed successfully'};
    }
  }

  Future<Map<String, dynamic>> updateProfile({
    required String accessToken,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (email != null) body['email'] = email;
    if (phone != null) body['phone'] = phone;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;

    final res = await _postReqWithCandidates(
      ['/mobile/auth/update-profile'],
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode >= 400) {
      throw Exception(_parseError(res));
    }
    try {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (e) {
      return {'message': 'Profile updated successfully'};
    }
  }

  Future<Map<String, dynamic>> listListeningHistory({
    required String accessToken,
    int page = 1,
    int size = 20,
    int? fromTimestamp,
    int? toTimestamp,
    String? languageCode,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'size': size.toString(),
      if (fromTimestamp != null) 'from_timestamp': fromTimestamp.toString(),
      if (toTimestamp != null) 'to_timestamp': toTimestamp.toString(),
    };

    final queryStr = Uri(queryParameters: query).query;
    final subPath = '/mobile/listening-history/?$queryStr';
    final headers = <String, String>{
      'Authorization': 'Bearer $accessToken',
      'Accept': 'application/json',
    };
    if (languageCode != null) {
      headers['Accept-Language'] = languageCode;
    }
    final res = await _getReqWithCandidates([subPath], headers: headers);

    if (res.statusCode >= 400) {
      throw Exception(_parseError(res));
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (e) {
      throw Exception('Invalid response from server in listListeningHistory');
    }
  }

  Future<Map<String, dynamic>> addListeningHistory({
    required String accessToken,
    required String stallId,
    required String stallContentId,
    required int listenedAt,
    int? listenDuration,
  }) async {
    final res = await _postReqWithCandidates(
      ['/mobile/listening-history/'],
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'stall_id': stallId,
        'stall_content_id': stallContentId,
        'listened_at': listenedAt,
        if (listenDuration != null) 'listen_duration': listenDuration,
      }),
    );

    if (res.statusCode >= 400) {
      throw Exception(_parseError(res));
    }

    try {
      return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
    } catch (e) {
      throw Exception('Invalid response from server in addListeningHistory');
    }
  }

  Future<Map<String, dynamic>> googleLogin({required String idToken}) async {
    final res = await _postReqWithCandidates(
      ['/mobile/auth/google-login', '/mobile/auth/google_login'],
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'idToken': idToken,
        'id_token': idToken,
        'token': idToken,
      }),
    );

    if (res.statusCode >= 400) {
      throw Exception(_parseError(res));
    }

    try {
      final js = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      final access =
          js['accessToken'] ??
          js['access_token'] ??
          js['token'] ??
          js['data']?['accessToken'] ??
          js['data']?['access_token'];
      final refresh =
          js['refreshToken'] ??
          js['refresh_token'] ??
          js['data']?['refreshToken'] ??
          js['data']?['refresh_token'];

      if (access == null || access is! String) {
        throw Exception('Google login response missing tokens');
      }

      return {'accessToken': access, 'refreshToken': refresh ?? access, ...js};
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Invalid response from server during Google login');
    }
  }

  Future<Map<String, dynamic>> loginDevice({required String deviceId}) async {
    final res = await _postReqWithCandidates(
      ['/mobile/auth/login-device', '/mobile/auth/login_device'],
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'device_id': deviceId, 'deviceId': deviceId}),
    );

    if (res.statusCode >= 400) {
      throw Exception(_parseError(res));
    }

    try {
      final js = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
      final access =
          js['accessToken'] ??
          js['access_token'] ??
          js['token'] ??
          js['data']?['accessToken'] ??
          js['data']?['access_token'];
      final refresh =
          js['refreshToken'] ??
          js['refresh_token'] ??
          js['data']?['refreshToken'] ??
          js['data']?['refresh_token'];

      if (access == null || access is! String) {
        throw Exception('Device login response missing tokens');
      }

      return {'accessToken': access, 'refreshToken': refresh ?? access, ...js};
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Invalid response from server during device login');
    }
  }

  String _parseError(http.Response res) {
    String raw;
    try {
      raw = utf8.decode(res.bodyBytes);
    } catch (_) {
      try {
        raw = latin1.decode(res.bodyBytes);
      } catch (_) {
        raw = res.body;
      }
    }

    String fixMojibake(String s) {
      if (s.contains('Ã') || s.contains('Â') || s.contains('\uFFFD')) {
        try {
          final bytes = latin1.encode(s);
          return utf8.decode(bytes);
        } catch (_) {
          return s;
        }
      }
      return s;
    }

    try {
      final body = jsonDecode(raw);
      if (body is Map && body['detail'] != null) {
        return fixMojibake(body['detail'].toString());
      }
      return 'HTTP ${res.statusCode}: ${fixMojibake(raw)}';
    } catch (_) {
      return 'HTTP ${res.statusCode}';
    }
  }
}
