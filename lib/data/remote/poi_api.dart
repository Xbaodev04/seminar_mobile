import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:http/http.dart' as http;
import 'package:seminar_mobile/core/services/locale_provider.dart';

import 'api_client.dart';
import 'http_client.dart';

class PoiApi {
  PoiApi._private();
  static final PoiApi instance = PoiApi._private();

  static const _timeout = Duration(seconds: 30);

  Uri _uri(String path) => Uri.parse('${ApiClient.instance.baseUrl}$path');

  /// Fetches stalls from backend API trying candidate path variations to prevent 404s
  Future<List<Map<String, dynamic>>> listStalls(
    String accessToken, {
    String? search,
    double? latitude,
    double? longitude,
    int limit = 20,
    int offset = 0,
  }) async {
    final queryParams = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
      queryParams['keyword'] = search;
    }

    if (latitude != null && longitude != null) {
      queryParams['latitude'] = latitude.toString();
      queryParams['longitude'] = longitude.toString();
    }

    // Candidate URL paths to handle trailing slash variations
    final candidatePaths = [
      '/api/v1/mobile/stalls',
      '/api/v1/mobile/stalls/',
      '/mobile/stalls/',
      '/mobile/stalls',
      '/stalls/',
      '/stalls',
    ];

    http.Response? lastResponse;

    for (final path in candidatePaths) {
      final uri = _uri(path).replace(queryParameters: queryParams);
      try {
        final headers = <String, String>{
          'Accept-Language':
              LocaleProvider.instance.locale?.languageCode ??
              (PlatformDispatcher.instance.locale.languageCode),
          'Accept': 'application/json',
        };
        if (accessToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $accessToken';
        }

        final res = await HttpClientWithTokenRefresh.instance.get(
          uri,
          headers: headers,
          timeout: _timeout,
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map && body['data'] != null) {
            if (body['data'] is List) {
              return List<Map<String, dynamic>>.from(body['data'] as List);
            } else if (body['data'] is Map && body['data']['items'] is List) {
              return List<Map<String, dynamic>>.from(body['data']['items'] as List);
            }
          } else if (body is List) {
            return List<Map<String, dynamic>>.from(body);
          }
          return <Map<String, dynamic>>[];
        }
        lastResponse = res;
      } catch (_) {
        // Continue trying next candidate path
      }
    }

    if (lastResponse != null && lastResponse.statusCode >= 400) {
      throw Exception(_parseError(lastResponse));
    }
    return <Map<String, dynamic>>[];
  }

  /// Fetches content for a stall
  Future<List<Map<String, dynamic>>> getStallContents(
    String stallId,
    String accessToken,
  ) async {
    final candidatePaths = [
      '/api/v1/mobile/stalls/$stallId/content',
      '/api/v1/mobile/stalls/$stallId/content/',
      '/mobile/stalls/$stallId/content/',
      '/mobile/stalls/$stallId/content',
      '/mobile/stall-contents/$stallId/',
      '/mobile/stall-contents/$stallId',
    ];

    for (final path in candidatePaths) {
      try {
        final headers = <String, String>{
          'Accept-Language':
              LocaleProvider.instance.locale?.languageCode ??
              (PlatformDispatcher.instance.locale.languageCode),
          'Accept': 'application/json',
        };
        if (accessToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $accessToken';
        }

        final res = await HttpClientWithTokenRefresh.instance.get(
          _uri(path),
          headers: headers,
          timeout: _timeout,
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map && body['data'] != null) {
            if (body['data'] is List) {
              return List<Map<String, dynamic>>.from(body['data'] as List);
            }
            return [body['data'] as Map<String, dynamic>];
          } else if (body is List) {
            return List<Map<String, dynamic>>.from(body);
          }
          return <Map<String, dynamic>>[];
        }
      } catch (_) {
        // Try next candidate
      }
    }

    return <Map<String, dynamic>>[];
  }

  /// Fetches detail for a single stall
  Future<Map<String, dynamic>?> getStall(
    String stallId,
    String accessToken,
  ) async {
    final candidatePaths = [
      '/api/v1/mobile/stalls/$stallId',
      '/api/v1/mobile/stalls/$stallId/',
      '/mobile/stalls/$stallId/',
      '/mobile/stalls/$stallId',
      '/stalls/$stallId/',
      '/stalls/$stallId',
    ];

    for (final path in candidatePaths) {
      try {
        final headers = <String, String>{
          'Accept-Language':
              LocaleProvider.instance.locale?.languageCode ??
              (PlatformDispatcher.instance.locale.languageCode),
          'Accept': 'application/json',
        };
        if (accessToken.isNotEmpty) {
          headers['Authorization'] = 'Bearer $accessToken';
        }

        final res = await HttpClientWithTokenRefresh.instance.get(
          _uri(path),
          headers: headers,
          timeout: _timeout,
        );

        if (res.statusCode == 200) {
          final body = jsonDecode(res.body);
          if (body is Map && body['data'] != null) {
            return body['data'] as Map<String, dynamic>;
          } else if (body is Map<String, dynamic>) {
            return body;
          }
          return null;
        }
      } catch (_) {
        // Try next candidate
      }
    }

    return null;
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
